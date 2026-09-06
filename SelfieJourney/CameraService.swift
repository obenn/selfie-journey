import AVFoundation
import Combine
import UIKit
import Vision

/// The UI owns permission and presentation state; all session work runs on one serial queue.
@MainActor
final class CameraService: ObservableObject {
    enum State: Equatable {
        case preparing
        case ready
        case denied
        case unavailable(String)
    }

    @Published private(set) var state: State = .preparing
    @Published private(set) var isCapturing = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    @Published private(set) var guidance: FaceGuidance = .starting

    private var wantsRunning = false
    private var pose: PortraitPose = .classic
    private var guidanceGeneration = 0
    private var guidanceWatchdog: Task<Void, Never>?
    private var lastPreviewAngle: CGFloat?
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private lazy var controller = CameraSessionController(
        onReady: { [weak self] result in
            guard let self, self.wantsRunning else { return }
            switch result {
            case .success: self.state = .ready
            case .failure(let error):
                self.state = .unavailable(error.localizedDescription)
                AppSupport.shared.record(.cameraError)
            }
        },
        onCapture: { [weak self] result in
            guard let self else { return }
            self.isCapturing = false
            switch result {
            case .success(let image): self.capturedImage = image
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                AppSupport.shared.record(.cameraError)
            }
        },
        onGuidance: { [weak self] guidance, generation in
            guard let self, self.wantsRunning, self.guidanceGeneration == generation else { return }
            self.guidanceWatchdog?.cancel()
            self.guidance = guidance
        }
    )

    var session: AVCaptureSession { controller.session }

    func start() {
        wantsRunning = true
        guidanceGeneration += 1
        guidance = .starting
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            state = .preparing
            startController()
        case .notDetermined:
            state = .preparing
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self, self.wantsRunning else { return }
                    if granted { self.startController() }
                    else { self.state = .denied }
                }
            }
        case .denied, .restricted:
            state = .denied
        @unknown default:
            state = .unavailable("The camera is not available right now.")
        }
    }

    private func startController() {
        controller.start(pose: pose, generation: guidanceGeneration, rotationAngle: lastPreviewAngle)
        watchForGuidance()
    }

    private func watchForGuidance() {
        guidanceWatchdog?.cancel()
        let generation = guidanceGeneration
        guidanceWatchdog = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(4)) }
            catch { return }
            guard let self, self.wantsRunning, self.guidanceGeneration == generation else { return }
            self.guidance = .manual
        }
    }

    func updatePose(_ pose: PortraitPose) {
        guard self.pose != pose else { return }
        self.pose = pose
        resetGuidance()
    }

    private func resetGuidance(deferPresentation: Bool = false) {
        guidanceGeneration += 1
        if deferPresentation {
            let generation = guidanceGeneration
            // Preview attachment/layout may occur during a SwiftUI view update.
            Task { @MainActor [weak self] in
                guard let self, self.guidanceGeneration == generation else { return }
                self.guidance = .starting
            }
        } else {
            guidance = .starting
        }
        guard wantsRunning else { return }
        controller.updateGuidance(pose: pose, generation: guidanceGeneration, rotationAngle: lastPreviewAngle)
        watchForGuidance()
    }

    func stop() {
        wantsRunning = false
        guidanceWatchdog?.cancel()
        guidanceWatchdog = nil
        guidanceGeneration += 1
        guidance = .starting
        controller.stop()
    }

    /// The coordinator accounts for both the sensor mounting and the preview's
    /// actual interface orientation, including iPad rotation and multitasking.
    func attachPreview(_ layer: AVCaptureVideoPreviewLayer) {
        if previewLayer === layer {
            refreshPreviewRotation()
            return
        }
        guard let input = session.inputs.compactMap({ $0 as? AVCaptureDeviceInput }).first else { return }
        rotationObservation = nil
        previewLayer = layer
        let coordinator = AVCaptureDevice.RotationCoordinator(device: input.device, previewLayer: layer)
        rotationCoordinator = coordinator
        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.initial, .new]) { [weak self] _, _ in
            // AVFoundation delivers these observations on the main queue.
            Task { @MainActor [weak self] in self?.refreshPreviewRotation() }
        }
        refreshPreviewRotation()
    }

    func refreshPreviewRotation() {
        guard let connection = previewLayer?.connection, let rotationCoordinator else { return }
        let angle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview
        if connection.isVideoRotationAngleSupported(angle) { connection.videoRotationAngle = angle }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
        if lastPreviewAngle != angle {
            lastPreviewAngle = angle
            resetGuidance(deferPresentation: true)
        }
    }

    func detachPreview(_ layer: AVCaptureVideoPreviewLayer) {
        guard previewLayer === layer else { return }
        rotationObservation = nil
        rotationCoordinator = nil
        previewLayer = nil
        lastPreviewAngle = nil
        resetGuidance(deferPresentation: true)
    }

    func capture() {
        guard state == .ready, !isCapturing else { return }
        guard let rotationCoordinator else {
            errorMessage = "The camera is still getting ready. Please try again in a moment."
            return
        }
        // Capture and preview angles can legitimately differ when an interface
        // is rotation-locked. Read the coordinator's capture angle at shutter time.
        let angle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
        isCapturing = true
        controller.capture(rotationAngle: angle)
    }

    func retake() {
        capturedImage = nil
        start()
    }
}

nonisolated private enum CameraFailure: LocalizedError, Sendable {
    case unavailable
    case configuration
    case capture(String)
    case image

    var errorDescription: String? {
        switch self {
        case .unavailable: "A front camera is needed for a live portrait. You can also choose a photo from your library."
        case .configuration: "The camera could not start. Try again, or choose a photo from your library."
        case .capture(let message): message
        case .image: "That photo could not be opened. Please try another one."
        }
    }
}

/// Session state is accessed only on `queue`. AVCapture delivers its photo result separately.
nonisolated private final class CameraSessionController: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "com.selfiejourney.camera", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private let analysisQueue = DispatchQueue(label: "com.selfiejourney.guidance", qos: .userInitiated)
    private var analysisAvailable = false
    private let analyzer: CameraFrameAnalyzer
    private var configured = false
    private var takingPhoto = false
    private var processedPhoto: Result<UIImage, CameraFailure>?
    private var observers: [NSObjectProtocol] = []
    private let onReady: @MainActor @Sendable (Result<Void, CameraFailure>) -> Void
    private let onCapture: @MainActor @Sendable (Result<UIImage, CameraFailure>) -> Void
    private let onGuidance: @MainActor @Sendable (FaceGuidance, Int) -> Void

    init(
        onReady: @escaping @MainActor @Sendable (Result<Void, CameraFailure>) -> Void,
        onCapture: @escaping @MainActor @Sendable (Result<UIImage, CameraFailure>) -> Void,
        onGuidance: @escaping @MainActor @Sendable (FaceGuidance, Int) -> Void
    ) {
        self.onReady = onReady
        self.onCapture = onCapture
        self.onGuidance = onGuidance
        self.analyzer = CameraFrameAnalyzer(onGuidance: onGuidance)
        super.init()
        observers = [
            NotificationCenter.default.addObserver(forName: AVCaptureSession.wasInterruptedNotification, object: session, queue: nil) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in self.onReady(.failure(.capture("The camera is temporarily in use. Try again when it is available, or choose a portrait from Photos."))) }
            },
            NotificationCenter.default.addObserver(forName: AVCaptureSession.runtimeErrorNotification, object: session, queue: nil) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in self.onReady(.failure(.configuration)) }
            }
        ]
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    func start(pose: PortraitPose, generation: Int, rotationAngle: CGFloat?) {
        queue.async { [self] in
            do {
                if !configured { try configure() }
                configureGuidance(pose: pose, generation: generation, rotationAngle: rotationAngle)
                if !session.isRunning { session.startRunning() }
                let result: Result<Void, CameraFailure> = session.isRunning && !session.isInterrupted ? .success(()) : .failure(.configuration)
                Task { @MainActor in self.onReady(result) }
            } catch let error as CameraFailure {
                Task { @MainActor in self.onReady(.failure(error)) }
            } catch {
                Task { @MainActor in self.onReady(.failure(.configuration)) }
            }
        }
    }

    func stop() {
        queue.async { [self] in
            analysisQueue.async { [self] in analyzer.pause() }
            if session.isRunning { session.stopRunning() }
        }
    }

    func updateGuidance(pose: PortraitPose, generation: Int, rotationAngle: CGFloat?) {
        queue.async { [self] in
            configureGuidance(pose: pose, generation: generation, rotationAngle: rotationAngle)
        }
    }

    private func configureGuidance(pose: PortraitPose, generation: Int, rotationAngle: CGFloat?) {
        guard analysisAvailable, let connection = videoOutput.connection(with: .video) else {
            Task { @MainActor in self.onGuidance(.manual, generation) }
            return
        }
        // The preview and analysis use the same physical rotation and mirroring. This avoids
        // device-specific sensor-orientation assumptions, including landscape-mounted iPad cameras.
        // Only change rotation when it changes, since rebuilding this pipeline has a cost.
        guard let rotationAngle else {
            analysisQueue.async { [self] in analyzer.reset(pose: pose, generation: generation, enabled: false) }
            return
        }
        guard connection.isVideoRotationAngleSupported(rotationAngle), connection.isVideoMirroringSupported else {
            analysisQueue.async { [self] in analyzer.pause() }
            Task { @MainActor in self.onGuidance(.manual, generation) }
            return
        }
        if connection.videoRotationAngle != rotationAngle { connection.videoRotationAngle = rotationAngle }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = true
        analysisQueue.async { [self] in analyzer.reset(pose: pose, generation: generation, enabled: true) }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CameraFailure.unavailable
        }
        let input = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        guard session.canAddInput(input) else { throw CameraFailure.configuration }
        session.addInput(input)
        guard session.canAddOutput(output) else {
            session.removeInput(input)
            throw CameraFailure.configuration
        }
        session.addOutput(output)
        output.maxPhotoQualityPrioritization = .quality
        // Camera capture remains available if this device cannot provide a Vision stream.
        if session.canAddOutput(videoOutput) {
            videoOutput.alwaysDiscardsLateVideoFrames = true
            session.addOutput(videoOutput)
            let formats = videoOutput.availableVideoPixelFormatTypes
            if formats.contains(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            } else if formats.contains(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
            }
            // Native YCbCr preview buffers avoid a full-resolution RGB copy for analysis.
            videoOutput.automaticallyConfiguresOutputBufferDimensions = false
            videoOutput.deliversPreviewSizedOutputBuffers = true
            videoOutput.setSampleBufferDelegate(analyzer, queue: analysisQueue)
            analysisAvailable = true
        }
        configured = true
    }

    func capture(rotationAngle: CGFloat) {
        queue.async { [self] in
            guard configured, session.isRunning, !takingPhoto else {
                Task { @MainActor in self.onCapture(.failure(.configuration)) }
                return
            }
            takingPhoto = true
            processedPhoto = nil
            if let connection = output.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(rotationAngle) { connection.videoRotationAngle = rotationAngle }
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                }
            }
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            settings.photoQualityPrioritization = .quality
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let result: Result<UIImage, CameraFailure>
        if let error {
            result = .failure(.capture(error.localizedDescription))
        } else if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            result = .success(CameraImageProcessor.portrait(from: image))
        } else {
            result = .failure(.image)
        }
        queue.async { [self] in processedPhoto = result }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        queue.async { [self] in
            let result: Result<UIImage, CameraFailure>
            if let error { result = .failure(.capture(error.localizedDescription)) }
            else { result = processedPhoto ?? .failure(.image) }
            processedPhoto = nil
            takingPhoto = false
            Task { @MainActor in self.onCapture(result) }
        }
    }
}

/// All mutable analysis state belongs to the dedicated serial analysis queue. Buffers live only
/// for this callback; the main actor receives a small guidance value, never frames or landmarks.
nonisolated private final class CameraFrameAnalyzer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private var pose: PortraitPose = .classic
    private var generation = 0
    private var enabled = false
    private var lastAnalysis: CFTimeInterval = 0
    private var readyAfter: CFTimeInterval = 0
    private var consecutiveFailures = 0
    private var stabilizer = FaceGuidanceStabilizer()
    private let onGuidance: @MainActor @Sendable (FaceGuidance, Int) -> Void

    init(onGuidance: @escaping @MainActor @Sendable (FaceGuidance, Int) -> Void) {
        self.onGuidance = onGuidance
        super.init()
    }

    func reset(pose: PortraitPose, generation: Int, enabled: Bool) {
        self.pose = pose
        self.generation = generation
        self.enabled = enabled
        consecutiveFailures = 0
        lastAnalysis = 0
        // Discard any buffers already in flight while the connection reorients.
        readyAfter = CACurrentMediaTime() + 0.3
        stabilizer.reset()
    }

    func pause() {
        enabled = false
        stabilizer.reset()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard enabled, now >= readyAfter, now - lastAnalysis >= 0.25,
              let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastAnalysis = now
        autoreleasepool {
            let request = VNDetectFaceLandmarksRequest()
            request.preferBackgroundProcessing = true
            do {
                // AVFoundation has physically rotated and mirrored this buffer to match the preview.
                try VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up).perform([request])
                let imageSize = CGSize(width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
                let observations = (request.results ?? []).filter { observation in
                    guard observation.confidence >= 0.6 else { return false }
                    let rect = FacePreviewGeometry.rect(observation.boundingBox, imageSize: imageSize)
                    let visible = rect.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
                    return !visible.isNull && visible.width * visible.height > rect.width * rect.height * 0.2
                }.sorted { $0.boundingBox.width * $0.boundingBox.height > $1.boundingBox.width * $1.boundingBox.height }
                let faces = observations.map { Self.geometry($0, imageSize: imageSize) }
                let light = Self.lightEstimate(buffer, face: observations.first?.boundingBox)
                let next = FaceGuidancePolicy.evaluate(faces: faces, light: light, pose: pose)
                let feedback = stabilizer.update(next)
                consecutiveFailures = 0
                publish(feedback)
            } catch {
                consecutiveFailures += 1
                // Vision availability never prevents a manual portrait. Retry on the next camera session.
                if consecutiveFailures >= 3 {
                    enabled = false
                    publish(.manual)
                }
            }
        }
    }

    private func publish(_ feedback: FaceGuidance) {
        let generation = self.generation
        Task { @MainActor in self.onGuidance(feedback, generation) }
    }

    private static func geometry(_ observation: VNFaceObservation, imageSize: CGSize) -> FaceGeometry {
        let box = observation.boundingBox
        func eyeCenter(_ region: VNFaceLandmarkRegion2D?) -> CGPoint? {
            guard let region, region.pointCount > 0 else { return nil }
            let sum = region.normalizedPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            return CGPoint(x: box.minX + sum.x / CGFloat(region.pointCount) * box.width,
                           y: box.minY + sum.y / CGFloat(region.pointCount) * box.height)
        }
        let left = eyeCenter(observation.landmarks?.leftEye)
        let right = eyeCenter(observation.landmarks?.rightEye)
        let eyes: CGPoint?
        let roll: Double?
        if let left, let right {
            eyes = FacePreviewGeometry.point(CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2), imageSize: imageSize)
            // The eye line gives a finer level estimate than the detector's roll buckets.
            roll = Double(atan2(abs(left.y - right.y) * imageSize.height, abs(left.x - right.x) * imageSize.width))
        } else {
            eyes = nil
            roll = observation.roll?.doubleValue
        }
        return FaceGeometry(bounds: FacePreviewGeometry.rect(box, imageSize: imageSize), eyes: eyes,
                            yaw: observation.yaw?.doubleValue, roll: roll, pitch: observation.pitch?.doubleValue)
    }

    private static func lightEstimate(_ buffer: CVPixelBuffer, face: CGRect?) -> FaceLightEstimate? {
        let format = CVPixelBufferGetPixelFormatType(buffer)
        let fullRange = format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        guard fullRange || format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
              CVPixelBufferGetPlaneCount(buffer) > 0,
              CVPixelBufferLockBaseAddress(buffer, .readOnly) == kCVReturnSuccess else { return nil }
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else { return nil }
        let pixels = base.assumingMemoryBound(to: UInt8.self)
        let width = CVPixelBufferGetWidthOfPlane(buffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(buffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
        func average(in normalizedRect: CGRect) -> Double? {
            let rect = normalizedRect.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
            guard !rect.isNull, rect.width > 0, rect.height > 0 else { return nil }
            let minX = max(0, min(width - 1, Int(rect.minX * CGFloat(width))))
            let maxX = max(minX + 1, min(width, Int(rect.maxX * CGFloat(width))))
            let minY = max(0, min(height - 1, Int(rect.minY * CGFloat(height))))
            let maxY = max(minY + 1, min(height, Int(rect.maxY * CGFloat(height))))
            let stepX = max(1, (maxX - minX) / 32)
            let stepY = max(1, (maxY - minY) / 32)
            var total = 0.0
            var count = 0
            for y in stride(from: minY, to: maxY, by: stepY) {
                for x in stride(from: minX, to: maxX, by: stepX) {
                    let value = Double(pixels[y * bytesPerRow + x])
                    total += fullRange ? value / 255 : min(1, max(0, (value - 16) / 219))
                    count += 1
                }
            }
            return count == 0 ? nil : total / Double(count)
        }
        let visibleRegion = FacePreviewGeometry.visibleImageRect(imageSize: CGSize(width: width, height: height))
        guard let scene = average(in: visibleRegion) else { return nil }
        let faceBrightness = face.flatMap { box in
            // Sample the inner face, excluding as much background and hair as possible.
            let inner = box.insetBy(dx: box.width * 0.22, dy: box.height * 0.18)
            return average(in: CGRect(x: inner.minX, y: 1 - inner.maxY, width: inner.width, height: inner.height))
        }
        return FaceLightEstimate(scene: scene, face: faceBrightness)
    }
}

nonisolated enum CameraImageProcessor {
    /// Bakes orientation and mirroring into a consistent portrait canvas for the timeline and film.
    static func portrait(from image: UIImage) -> UIImage {
        let target = CGSize(width: 1200, height: 1600)
        let scale = max(target.width / image.size.width, target.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: target))
            image.draw(in: CGRect(x: (target.width - size.width) / 2, y: (target.height - size.height) / 2, width: size.width, height: size.height))
        }
    }
}
