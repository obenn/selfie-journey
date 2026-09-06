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
