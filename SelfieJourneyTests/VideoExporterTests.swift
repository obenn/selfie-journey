import AVFoundation
import Testing
import UIKit
@testable import SelfieJourney

struct VideoExporterTests {
    @Test @MainActor func exportsChronologicalPortraitVideoWithExpectedDuration() async throws {
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        let later = earlier.addingTimeInterval(86_400)
        let frames = [
            VideoExporter.Frame(imageData: try imageData(color: .red), date: later),
            VideoExporter.Frame(imageData: try imageData(color: .blue), date: earlier)
        ]
        let url = try await VideoExporter().export(frames: frames, pace: .balanced, includeDates: true) { _ in }
        defer { try? FileManager.default.removeItem(at: url) }

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        #expect(abs(duration.seconds - 0.8) < 0.04)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        let track = try #require(tracks.first)
        let size = try await track.load(.naturalSize)
        #expect(size == CGSize(width: 1080, height: 1440))

        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let firstFrame = try await generator.image(at: .zero)
        let rgb = averageColor(firstFrame.image)
        #expect(Int(rgb.blue) > Int(rgb.red) + 100, "The earlier blue portrait must precede the later red portrait.")
    }

    @Test func requiresAtLeastTwoPortraits() async {
        do {
            _ = try await VideoExporter().export(frames: [], pace: .balanced, includeDates: false) { _ in }
            Issue.record("Export should reject fewer than two portraits.")
        } catch VideoExporter.ExportError.notEnoughPortraits {
            // Expected; the UI also explains why two portraits are needed.
        } catch {
            Issue.record("Unexpected export error: \(error)")
        }
    }

    @Test func rejectsUnreadablePortraitWithoutProducingFilm() async {
        let frames = [
            VideoExporter.Frame(imageData: Data([0, 1, 2]), date: .distantPast),
            VideoExporter.Frame(imageData: Data([3, 4, 5]), date: .distantFuture)
        ]
        do {
            _ = try await VideoExporter().export(frames: frames, pace: .quick, includeDates: false) { _ in }
            Issue.record("Export should reject unreadable image data.")
        } catch VideoExporter.ExportError.unreadablePortrait {
            // Expected. The exporter removes its incomplete temporary file in defer.
        } catch {
            Issue.record("Unexpected export error: \(error)")
        }
    }

    @Test @MainActor func respectsTaskCancellation() async throws {
        let data = try imageData(color: .white)
        let frames = (0..<30).map { VideoExporter.Frame(imageData: data, date: Date(timeIntervalSince1970: Double($0))) }
        let task = Task {
            try await VideoExporter().export(frames: frames, pace: .slow, includeDates: true) { _ in }
        }
        task.cancel()
        do {
            let url = try await task.value
            try? FileManager.default.removeItem(at: url)
            Issue.record("Export should stop when its task is cancelled.")
        } catch is CancellationError {
            // Expected.
        }
    }

    @Test @MainActor func requestsImageDataLazilyInDateOrderAndStopsOnFailure() async throws {
        let state = ImageProviderState()
        let data = try imageData(color: .blue)
        let dates = [Date(timeIntervalSince1970: 20), Date(timeIntervalSince1970: 10), Date(timeIntervalSince1970: 30)]
        do {
            _ = try await VideoExporter().export(dates: dates, pace: .quick, includeDates: false, imageDataAt: { index in
                state.requests.append(index)
                if index == 0 { throw ImageProviderError.unavailable }
                return data
            }) { _ in }
            Issue.record("Export should stop when a portrait can no longer be loaded.")
        } catch ImageProviderError.unavailable {
            #expect(state.requests == [1, 0], "Fetch oldest first and stop before requesting any images after the failure.")
        }
    }

    @Test @MainActor func removesBackgroundOncePerPortraitAndProducesOpaqueVideo() async throws {
        let calls = MaskCallRecorder()
        let data = try imageData(color: .green)
        let frames = (0..<2).map { VideoExporter.Frame(imageData: data, date: Date(timeIntervalSince1970: Double($0))) }
        let exporter = VideoExporter(maskProvider: { image in
            calls.record()
            return try PersonBackgroundTestImage.mask(width: 30, height: 40) { x, _ in x < 15 ? 0 : 255 }
        })
        let url = try await exporter.export(frames: frames, pace: .slow, includeDates: false, background: .remove) { _ in }
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(calls.count == 2, "A portrait is segmented once, not once for every encoded video frame.")

        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        let image = try await generator.image(at: .zero).image
        let background = PersonBackgroundTestImage.pixel(image, x: 0.1, y: 0.5)
        let foreground = PersonBackgroundTestImage.pixel(image, x: 0.9, y: 0.5)
        #expect(background.red > 220 && background.green > 220 && background.blue > 210)
        #expect(foreground.green > foreground.red + 100 && foreground.green > foreground.blue + 100)
        #expect(background.alpha == 255 && foreground.alpha == 255, "The MP4 has an opaque replacement background.")
    }

    @Test @MainActor func originalBackgroundNeverRunsSegmentation() async throws {
        let calls = MaskCallRecorder()
        let data = try imageData(color: .blue)
        let frames = [VideoExporter.Frame(imageData: data, date: .distantPast), .init(imageData: data, date: .distantFuture)]
        let exporter = VideoExporter(maskProvider: { _ in
            calls.record()
            throw ImageProviderError.unavailable
        })
        let url = try await exporter.export(frames: frames, pace: .quick, includeDates: false) { _ in }
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(calls.count == 0)
    }

    @Test @MainActor func failedSegmentationStopsBeforeNextPhotoAndRemovesPartialVideo() async throws {
        let folder = try PersonBackgroundTestImage.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let calls = MaskCallRecorder()
        let providerState = ImageProviderState()
        let data = try imageData(color: .green)
        let exporter = VideoExporter(maskProvider: { _ in
            let count = calls.record()
            return try PersonBackgroundTestImage.mask(width: 16, height: 16) { _, _ in count == 1 ? 255 : 0 }
        }, temporaryDirectory: folder)
        do {
            _ = try await exporter.export(dates: [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2), Date(timeIntervalSince1970: 3)], pace: .quick, includeDates: false, background: .remove, imageDataAt: { index in
                providerState.requests.append(index)
                return data
            }) { _ in }
            Issue.record("A missing person must abort instead of inserting the original photo into a removal video.")
        } catch VideoExporter.ExportError.personNotFound {
            #expect(providerState.requests == [0, 1])
            #expect(calls.count == 2)
            #expect(try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).isEmpty)
        }
    }

    @Test @MainActor func modelFailureIsFriendlyAndRemovesPartialVideo() async throws {
        let folder = try PersonBackgroundTestImage.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let data = try imageData(color: .green)
        let exporter = VideoExporter(maskProvider: { _ in throw ImageProviderError.unavailable }, temporaryDirectory: folder)
        do {
            _ = try await exporter.export(frames: [.init(imageData: data, date: .distantPast), .init(imageData: data, date: .distantFuture)], pace: .quick, includeDates: false, background: .remove) { _ in }
            Issue.record("Unavailable segmentation must not silently use original backgrounds.")
        } catch VideoExporter.ExportError.backgroundRemovalUnavailable {
            #expect(try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).isEmpty)
        }
    }

    @Test @MainActor func cancellationDuringMaskProcessingRemovesPartialVideo() async throws {
        let folder = try PersonBackgroundTestImage.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let calls = MaskCallRecorder()
        let data = try imageData(color: .green)
        let exporter = VideoExporter(maskProvider: { _ in
            calls.record()
            let deadline = Date().addingTimeInterval(10)
            while !Task.isCancelled && Date() < deadline { Thread.sleep(forTimeInterval: 0.01) }
            try Task.checkCancellation()
            throw ImageProviderError.unavailable
        }, temporaryDirectory: folder)
        let task = Task {
            try await exporter.export(frames: [.init(imageData: data, date: .distantPast), .init(imageData: data, date: .distantFuture)], pace: .quick, includeDates: false, background: .remove) { _ in }
        }
        for _ in 0..<500 where calls.count == 0 { try await Task.sleep(for: .milliseconds(20)) }
        #expect(calls.count == 1, "Cancel after mask processing starts, not before the export starts.")
        task.cancel()
        do {
            let url = try await task.value
            try? FileManager.default.removeItem(at: url)
            Issue.record("A cancelled mask request must stop export.")
        } catch is CancellationError {
            #expect(try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).isEmpty)
        }
    }

    @Test @MainActor func aspectFillCropsPhotoAndMaskTogether() async throws {
        let source = try PersonBackgroundTestImage.image(width: 240, height: 120) { x, _ in
            if x < 75 || x >= 165 { return (255, 0, 0, 255) }
            return (0, 255, 0, 255)
        }
        let data = try PersonBackgroundTestImage.jpeg(source)
        let exporter = VideoExporter(maskProvider: { _ in
            try PersonBackgroundTestImage.mask(width: 80, height: 40) { x, _ in x < 40 ? 0 : 255 }
        })
        let url = try await exporter.export(frames: [.init(imageData: data, date: .distantPast), .init(imageData: data, date: .distantFuture)], pace: .quick, includeDates: false, background: .remove) { _ in }
        defer { try? FileManager.default.removeItem(at: url) }
        let image = try await AVAssetImageGenerator(asset: AVURLAsset(url: url)).image(at: .zero).image
        let left = PersonBackgroundTestImage.pixel(image, x: 0.1, y: 0.5)
        let right = PersonBackgroundTestImage.pixel(image, x: 0.9, y: 0.5)
        #expect(left.red > 220 && left.green > 220 && left.blue > 210)
        #expect(right.green > right.red + 100, "Aspect fill should crop the red outer bands and keep the photo and mask aligned.")
    }

    @MainActor private final class ImageProviderState {
        var requests: [Int] = []
    }

    private enum ImageProviderError: Error {
        case unavailable
    }

    @MainActor private func imageData(color: UIColor) throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 90, height: 120)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 90, height: 120))
        }
        return try #require(image.jpegData(compressionQuality: 0.9))
    }

    private func averageColor(_ image: CGImage) -> (red: UInt8, green: UInt8, blue: UInt8) {
        var pixel = [UInt8](repeating: 0, count: 4)
        pixel.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            context?.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return (pixel[0], pixel[1], pixel[2])
    }
}
