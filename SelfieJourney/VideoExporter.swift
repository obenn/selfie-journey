import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UIKit

/// A serial encoder that requests and decodes one portrait at a time.
actor VideoExporter {
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

    enum ExportError: LocalizedError {
        case notEnoughPortraits
        case cannotCreateVideo
        case unreadablePortrait
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .notEnoughPortraits: "Take at least two portraits to make your first film."
            case .cannotCreateVideo: "This device couldn't prepare the video. Please try again."
            case .unreadablePortrait: "One of your portraits couldn't be opened. Your collection hasn't been changed."
            case .encodingFailed: "The video couldn't be finished. Check your available storage and try again."
            }
        }
    }

    func export(frames: [Frame], pace: Pace, includeDates: Bool, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        try await export(dates: frames.map(\.date), pace: pace, includeDates: includeDates, imageDataAt: { index in
            frames[index].imageData
        }, progress: progress)
    }

    /// Indices passed to the provider refer to the original dates array, requested oldest first.
    /// The main-actor provider can safely fetch SwiftData's external image storage on demand.
    func export(
        dates: [Date],
        pace: Pace,
        includeDates: Bool,
        imageDataAt: @escaping @MainActor @Sendable (Int) throws -> Data,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        guard dates.count >= 2 else { throw ExportError.notEnoughPortraits }
        try Task.checkCancellation()
        let orderedIndices = dates.indices.sorted {
            dates[$0] == dates[$1] ? $0 < $1 : dates[$0] < dates[$1]
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SelfieJourney-\(UUID().uuidString).mp4")
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

        var frameNumber: Int64 = 0
        for (index, sourceIndex) in orderedIndices.enumerated() {
            try Task.checkCancellation()
            let buffer = try await loadPixelBuffer(
                index: sourceIndex, date: dates[sourceIndex], imageDataAt: imageDataAt,
                pool: pool, width: width, height: height, includeDate: includeDates
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
        includeDate: Bool
    ) async throws -> CVPixelBuffer {
        try Task.checkCancellation()
        let data = try await imageDataAt(index)
        try Task.checkCancellation()
        // The compressed image and the decoded CGImage leave scope before the next request.
        return try autoreleasepool {
            try Self.makePixelBuffer(frame: Frame(imageData: data, date: date), pool: pool, width: width, height: height, includeDate: includeDate)
        }
    }

    private static func makePixelBuffer(frame: Frame, pool: CVPixelBufferPool, width: Int, height: Int, includeDate: Bool) throws -> CVPixelBuffer {
        guard let source = CGImageSourceCreateWithData(frame.imageData as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(width, height),
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw ExportError.unreadablePortrait }
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
            let caption = frame.date.formatted(.dateTime.month(.wide).day().year())
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
