import CoreImage
import CoreImage.CIFilterBuiltins
import CoreVideo
import Foundation
import Vision

/// Only export copies are processed. Each request starts fresh: unrelated daily
/// portraits must not inherit Vision's temporal mask state from the previous day.
actor PersonBackgroundRenderer {
    typealias MaskProvider = @Sendable (CGImage) throws -> CVPixelBuffer

    private let maskProvider: MaskProvider?
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    init(maskProvider: MaskProvider? = nil) {
        self.maskProvider = maskProvider
    }

    func removingBackground(from image: CGImage) async throws -> CGImage {
        try Task.checkCancellation()
        let request = CancellablePersonRequest()
        return try await withTaskCancellationHandler {
            try autoreleasepool {
                try Task.checkCancellation()
                let mask: CVPixelBuffer
                do {
                    if let maskProvider {
                        mask = try maskProvider(image)
                    } else {
                        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
                        try handler.perform([request.value])
                        try Task.checkCancellation()
                        guard let result = request.value.results?.first else {
                            throw VideoExporter.ExportError.personNotFound
                        }
                        mask = result.pixelBuffer
                    }
                } catch {
                    try Task.checkCancellation()
                    if error is CancellationError { throw error }
                    if let failure = error as? VideoExporter.ExportError { throw failure }
                    throw VideoExporter.ExportError.backgroundRemovalUnavailable
                }
                try Task.checkCancellation()
                try Self.validatePersonMask(mask)
                let result = try composite(image: image, mask: mask)
                try Task.checkCancellation()
                return result
            }
        } onCancel: {
            // Vision documents cancel() for aborting an in-flight request. Task
            // cancellation remains a CancellationError, never a missing-person error.
            request.cancel()
        }
    }

    private func composite(image: CGImage, mask: CVPixelBuffer) throws -> CGImage {
        let foreground = CIImage(cgImage: image)
        let bounds = foreground.extent
        let rawMask = CIImage(cvPixelBuffer: mask, options: [.colorSpace: NSNull()])
        guard rawMask.extent.width > 0, rawMask.extent.height > 0 else {
            throw VideoExporter.ExportError.backgroundRemovalUnavailable
        }
        let fittedMask = rawMask
            .transformed(by: CGAffineTransform(translationX: -rawMask.extent.minX, y: -rawMask.extent.minY))
            .transformed(by: CGAffineTransform(scaleX: bounds.width / rawMask.extent.width, y: bounds.height / rawMask.extent.height))
            .cropped(to: bounds)
        let neutral = CIImage(color: CIColor(red: 238.0 / 255, green: 236.0 / 255, blue: 228.0 / 255, alpha: 1))
            .cropped(to: bounds)
        let blend = CIFilter.blendWithMask()
        blend.inputImage = foreground
        blend.backgroundImage = neutral
        blend.maskImage = fittedMask
        guard let output = blend.outputImage,
              let result = context.createCGImage(output, from: bounds, format: .RGBA8, colorSpace: colorSpace) else {
            throw VideoExporter.ExportError.backgroundRemovalUnavailable
        }
        return result
    }

    private static func validatePersonMask(_ mask: CVPixelBuffer) throws {
        guard CVPixelBufferGetPixelFormatType(mask) == kCVPixelFormatType_OneComponent8,
              CVPixelBufferGetWidth(mask) > 0, CVPixelBufferGetHeight(mask) > 0,
              CVPixelBufferLockBaseAddress(mask, .readOnly) == kCVReturnSuccess else {
            throw VideoExporter.ExportError.backgroundRemovalUnavailable
        }
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(mask) else {
            throw VideoExporter.ExportError.backgroundRemovalUnavailable
        }
        let width = CVPixelBufferGetWidth(mask), height = CVPixelBufferGetHeight(mask)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        var confidentPixels = 0
        for y in 0..<height {
            if y.isMultiple(of: 64) { try Task.checkCancellation() }
            let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in 0..<width where row[x] >= 128 { confidentPixels += 1 }
        }
        // An all-background result (or isolated noise below 0.1% coverage) is not a
        // usable person mask. Abort the whole export instead of mixing backgrounds.
        guard confidentPixels >= max(1, width * height / 1000) else {
            throw VideoExporter.ExportError.personNotFound
        }
    }
}

/// Configuration is immutable once published. The sole cross-task operation is
/// VNRequest.cancel(), which Apple provides to stop an in-flight perform() call.
nonisolated private final class CancellablePersonRequest: @unchecked Sendable {
    let value: VNGeneratePersonSegmentationRequest

    init() {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        value = request
    }

    func cancel() { value.cancel() }
}
