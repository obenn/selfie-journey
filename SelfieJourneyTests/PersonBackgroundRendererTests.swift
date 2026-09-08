import CoreGraphics
import CoreVideo
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
import XCTest
@testable import SelfieJourney

struct PersonBackgroundRendererTests {
    @Test func softMaskCompositesSubjectOntoNeutralOpaqueBackground() async throws {
        let image = try PersonBackgroundTestImage.image(width: 120, height: 80) { _, _ in (0, 255, 0, 255) }
        let renderer = PersonBackgroundRenderer(maskProvider: { _ in
            try PersonBackgroundTestImage.mask(width: 30, height: 20) { x, _ in
                x < 10 ? 0 : (x < 20 ? 128 : 255)
            }
        })
        let result = try await renderer.removingBackground(from: image)
        let background = PersonBackgroundTestImage.pixel(result, x: 0.1, y: 0.5)
        let edge = PersonBackgroundTestImage.pixel(result, x: 0.5, y: 0.5)
        let subject = PersonBackgroundTestImage.pixel(result, x: 0.9, y: 0.5)
        #expect(abs(background.red - 238) <= 2 && abs(background.green - 236) <= 2 && abs(background.blue - 228) <= 2)
        #expect(subject.green > 250 && subject.red < 5 && subject.blue < 5)
        #expect(edge.red > subject.red + 20 && edge.red < background.red - 20, "Soft hair/edge mask values must blend rather than become a hard cutout.")
        #expect(background.alpha == 255 && edge.alpha == 255 && subject.alpha == 255)
    }

    @Test func decodesExifOrientationBeforeRequestingMask() async throws {
        let source = try PersonBackgroundTestImage.image(width: 120, height: 90) { x, _ in
            if x < 40 { return (255, 0, 0, 255) }
            if x < 80 { return (0, 255, 0, 255) }
            return (0, 0, 255, 255)
        }
        let data = try PersonBackgroundTestImage.jpeg(source, orientation: .right)
        let upright = try VideoExporter.decodePortrait(data, maximumPixelSize: 1440)
        #expect(upright.width == 90 && upright.height == 120)
        let renderer = PersonBackgroundRenderer(maskProvider: { image in
            #expect(image.width == 90 && image.height == 120)
            return try PersonBackgroundTestImage.mask(width: 18, height: 24) { _, _ in 255 }
        })
        let result = try await renderer.removingBackground(from: upright)
        let top = PersonBackgroundTestImage.pixel(result, x: 0.5, y: 0.1)
        let bottom = PersonBackgroundTestImage.pixel(result, x: 0.5, y: 0.9)
        #expect(top.red > top.blue + 150 && bottom.blue > bottom.red + 150, "The EXIF rotation must be baked into the pixels before producing the mask.")
    }

    @Test func rejectsEmptyPersonMask() async throws {
        let image = try PersonBackgroundTestImage.image(width: 30, height: 40) { _, _ in (50, 80, 100, 255) }
        let renderer = PersonBackgroundRenderer(maskProvider: { _ in
            try PersonBackgroundTestImage.mask(width: 3, height: 4) { _, _ in 0 }
        })
        await #expect(throws: VideoExporter.ExportError.personNotFound) {
            try await renderer.removingBackground(from: image)
        }
    }
}

/// This is an actual Apple-model smoke check, separate from deterministic mask
/// tests. Simulator model availability can differ from supported physical devices.
final class VisionPersonBackgroundSmokeTests: XCTestCase {
    func testRealVisionSegmentationOnPortraitFixture() async throws {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(bundle.url(forResource: "person-background-portrait", withExtension: "jpg")
            ?? bundle.url(forResource: "person-background-portrait", withExtension: "jpg", subdirectory: "Resources"))
        let data = try Data(contentsOf: url)
        let image = try VideoExporter.decodePortrait(data, maximumPixelSize: 640)
        do {
            let result = try await PersonBackgroundRenderer().removingBackground(from: image)
            XCTAssertEqual(result.width, image.width)
            XCTAssertEqual(result.height, image.height)
            let corners = [(0.02, 0.02), (0.98, 0.02), (0.02, 0.98), (0.98, 0.98)]
            let neutralCorners = corners.filter { x, y in
                let pixel = PersonBackgroundTestImage.pixel(result, x: x, y: y)
                return abs(pixel.red - 238) < 10 && abs(pixel.green - 236) < 10 && abs(pixel.blue - 228) < 10
            }
            XCTAssertGreaterThanOrEqual(neutralCorners.count, 2, "Vision should remove the illustrative portrait's background at the top corners.")
        } catch VideoExporter.ExportError.backgroundRemovalUnavailable {
            #if targetEnvironment(simulator)
            throw XCTSkip("Apple's person-segmentation model is unavailable in this simulator. Deterministic composition/export tests remain required; verify subject-edge quality on a physical device.")
            #else
            XCTFail("Person segmentation should be available on the test device.")
            #endif
        }
    }
}

enum PersonBackgroundTestImage {
    typealias Pixel = (red: Int, green: Int, blue: Int, alpha: Int)

    static func image(width: Int, height: Int, color: (Int, Int) -> (UInt8, UInt8, UInt8, UInt8)) throws -> CGImage {
        var pixels = [UInt8](); pixels.reserveCapacity(width * height * 4)
        for y in 0..<height { for x in 0..<width {
            let pixel = color(x, y); pixels.append(contentsOf: [pixel.0, pixel.1, pixel.2, pixel.3])
        } }
        let provider = try #require(CGDataProvider(data: Data(pixels) as CFData))
        return try #require(CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    }

    static func mask(width: Int, height: Int, value: (Int, Int) -> UInt8) throws -> CVPixelBuffer {
        var optional: CVPixelBuffer?
        guard CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_OneComponent8, nil, &optional) == kCVReturnSuccess,
              let buffer = optional else { throw FixtureError.unavailable }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let base = try #require(CVPixelBufferGetBaseAddress(buffer))
        for y in 0..<height {
            let row = base.advanced(by: y * CVPixelBufferGetBytesPerRow(buffer)).assumingMemoryBound(to: UInt8.self)
            for x in 0..<width { row[x] = value(x, y) }
        }
        return buffer
    }

    static func jpeg(_ image: CGImage, orientation: CGImagePropertyOrientation = .up) throws -> Data {
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation.rawValue, kCGImageDestinationLossyCompressionQuality: 1] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw FixtureError.unavailable }
        return data as Data
    }

    static func pixel(_ image: CGImage, x: Double, y: Double) -> Pixel {
        guard let sample = image.cropping(to: CGRect(x: floor(Double(image.width - 1) * x), y: floor(Double(image.height - 1) * y), width: 1, height: 1)) else { return (0, 0, 0, 0) }
        var pixel = [UInt8](repeating: 0, count: 4)
        pixel.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            context?.draw(sample, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]), Int(pixel[3]))
    }

    static func temporaryDirectory() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("SelfieJourneyExportTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private enum FixtureError: Error { case unavailable }
}

final class MaskCallRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storedCount = 0
    var count: Int { lock.withLock { storedCount } }
    @discardableResult func record() -> Int { lock.withLock { storedCount += 1; return storedCount } }
}
