import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UIKit

/// A serial encoder that requests and decodes one portrait at a time.
actor VideoExporter {
    private let maskProvider: PersonBackgroundRenderer.MaskProvider?
    private let temporaryDirectory: URL

    init(maskProvider: PersonBackgroundRenderer.MaskProvider? = nil, temporaryDirectory: URL = FileManager.default.temporaryDirectory) {
        self.maskProvider = maskProvider
        self.temporaryDirectory = temporaryDirectory
    }

    struct Frame: Sendable {
        let imageData: Data
        let date: Date
    }

    enum Pace: String, CaseIterable, Identifiable, Sendable {
        case slow = "Slow"
        case balanced = "Balanced"
        case quick = "Quick"

        var id: Self { self }
        var framesPerPortrait: Int {
            switch self {
            case .slow: 24
            case .balanced: 12
            case .quick: 6
            }
        }
        var secondsPerPortrait: Double { Double(framesPerPortrait) / 30 }
    }

    enum Background: String, CaseIterable, Identifiable, Sendable {
        case original = "Original"
        case remove = "Remove background"

        var id: Self { self }
    }

    enum ExportError: LocalizedError, Equatable {
        case notEnoughPortraits
        case cannotCreateVideo
        case unreadablePortrait
        case encodingFailed
        case backgroundRemovalUnavailable
        case personNotFound

        var errorDescription: String? {
            switch self {
            case .notEnoughPortraits: "Take at least two portraits to make your first film."
            case .cannotCreateVideo: "This device couldn't prepare the video. Please try again."
            case .unreadablePortrait: "One of your portraits couldn't be opened. Your collection hasn't been changed."
            case .encodingFailed: "The video couldn't be finished. Check your available storage and try again."
            case .backgroundRemovalUnavailable: "This device couldn't remove a portrait's background. Try again, or turn off Remove background to use the original backgrounds. Your photos haven't been changed."
            case .personNotFound: "A person couldn't be found clearly in one of your portraits. Turn off Remove background to use the original backgrounds. Your photos haven't been changed."
            }
        }
    }

    func export(frames: [Frame], pace: Pace, includeDates: Bool, background: Background = .original, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        try await export(dates: frames.map(\.date), pace: pace, includeDates: includeDates, background: background, imageDataAt: { index in
            frames[index].imageData
        }, progress: progress)
    }

    /// Indices passed to the provider refer to the original dates array, requested oldest first.
    /// The main-actor provider can safely fetch SwiftData's external image storage on demand.
    func export(
        dates: [Date],
        pace: Pace,
        includeDates: Bool,
        background: Background = .original,
        imageDataAt: @escaping @MainActor @Sendable (Int) throws -> Data,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        guard dates.count >= 2 else { throw ExportError.notEnoughPortraits }
        try Task.checkCancellation()
        let orderedIndices = dates.indices.sorted {
            dates[$0] == dates[$1] ? $0 < $1 : dates[$0] < dates[$1]
        }
        let url = temporaryDirectory.appendingPathComponent("SelfieJourney-\(UUID().uuidString).mp4")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let width = 1080
        let height = 1440
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 7_000_000,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 30
            ]
        ])
        input.expectsMediaDataInRealTime = false
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attributes)
        guard writer.canAdd(input) else { throw ExportError.cannotCreateVideo }
        writer.add(input)
        var completed = false
        defer {
            if !completed {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: url)
            }
        }
        guard writer.startWriting() else { throw writer.error ?? ExportError.cannotCreateVideo }
        writer.startSession(atSourceTime: .zero)
        guard let pool = adaptor.pixelBufferPool else { throw ExportError.cannotCreateVideo }
        // A renderer lives only for this export. It never retains portraits or masks
        // across days, and the original path does not initialize Vision or Core Image.
        let backgroundRenderer = background == .remove ? PersonBackgroundRenderer(maskProvider: maskProvider) : nil

        var frameNumber: Int64 = 0
        for (index, sourceIndex) in orderedIndices.enumerated() {
            try Task.checkCancellation()
            let buffer = try await loadPixelBuffer(
                index: sourceIndex, date: dates[sourceIndex], imageDataAt: imageDataAt,
                pool: pool, width: width, height: height, includeDate: includeDates,
                backgroundRenderer: backgroundRenderer
            )
            for _ in 0..<pace.framesPerPortrait {
                try Task.checkCancellation()
                while !input.isReadyForMoreMediaData {
                    try Task.checkCancellation()
                    guard writer.status == .writing else { throw writer.error ?? ExportError.encodingFailed }
                    try await Task.sleep(for: .milliseconds(8))
                }
                guard adaptor.append(buffer, withPresentationTime: CMTime(value: frameNumber, timescale: 30)) else {
                    throw writer.error ?? ExportError.encodingFailed
                }
                frameNumber += 1
            }
            progress(Double(index + 1) / Double(orderedIndices.count))
        }
        try Task.checkCancellation()
        input.markAsFinished()
        writer.endSession(atSourceTime: CMTime(value: frameNumber, timescale: 30))
        await writer.finishWriting()
        try Task.checkCancellation()
        guard writer.status == .completed else { throw writer.error ?? ExportError.encodingFailed }
        completed = true
        return url
    }

    private func loadPixelBuffer(
        index: Int,
        date: Date,
        imageDataAt: @MainActor @Sendable (Int) throws -> Data,
        pool: CVPixelBufferPool,
        width: Int,
        height: Int,
        includeDate: Bool,
        backgroundRenderer: PersonBackgroundRenderer?
    ) async throws -> CVPixelBuffer {
        try Task.checkCancellation()
        let data = try await imageDataAt(index)
        try Task.checkCancellation()
        // Bake EXIF orientation before segmentation so the mask and photo share the
        // same coordinates. Decode only to export resolution to bound working memory.
        let image = try autoreleasepool {
            try Self.decodePortrait(data, maximumPixelSize: max(width, height))
        }
        let outputImage: CGImage
        if let backgroundRenderer {
            outputImage = try await backgroundRenderer.removingBackground(from: image)
        } else {
            outputImage = image
        }
        try Task.checkCancellation()
        // Segment once per portrait, then reuse this opaque buffer for every hold frame.
        return try autoreleasepool {
            try Self.makePixelBuffer(image: outputImage, date: date, pool: pool, width: width, height: height, includeDate: includeDate)
        }
    }

    static func decodePortrait(_ data: Data, maximumPixelSize: Int) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw ExportError.unreadablePortrait }
        return image
    }

    private static func makePixelBuffer(image: CGImage, date: Date, pool: CVPixelBufferPool, width: Int, height: Int, includeDate: Bool) throws -> CVPixelBuffer {
        var optionalBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optionalBuffer) == kCVReturnSuccess,
              let buffer = optionalBuffer else { throw ExportError.cannotCreateVideo }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { throw ExportError.cannotCreateVideo }
        let size = CGSize(width: width, height: height)
        let scale = max(size.width / CGFloat(image.width), size.height / CGFloat(image.height))
        let drawSize = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: (size.width - drawSize.width) / 2, y: (size.height - drawSize.height) / 2, width: drawSize.width, height: drawSize.height))
        if includeDate {
            // UIKit uses a top-left coordinate system; flip only for the date typography.
            context.saveGState()
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)
            let colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.45).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height - 240), end: CGPoint(x: 0, y: size.height), options: [])
            }
            UIGraphicsPushContext(context)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let caption = date.formatted(.dateTime.month(.wide).day().year())
            (caption as NSString).draw(in: CGRect(x: 50, y: size.height - 95, width: size.width - 100, height: 48), withAttributes: [
                .font: UIFont.systemFont(ofSize: 30, weight: .medium),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph,
                .kern: 1.5
            ])
            UIGraphicsPopContext()
            context.restoreGState()
        }
        return buffer
    }
}
