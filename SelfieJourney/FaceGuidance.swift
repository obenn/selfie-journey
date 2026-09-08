import CoreGraphics
import Foundation

/// Transient geometry only. No identity, face template, or preview image is saved.
nonisolated struct FaceGeometry: Equatable, Sendable {
    /// Normalized coordinates in the mirrored, aspect-filled 3:4 preview; origin is top left.
    var bounds: CGRect
    var eyes: CGPoint?
    var yaw: Double?
    var roll: Double?
    var pitch: Double?
}

nonisolated struct FaceLightEstimate: Equatable, Sendable {
    /// Relative image brightness after camera exposure, not a physical light-meter reading.
    var scene: Double
    var face: Double?
}

nonisolated enum FaceGuidanceCue: Equatable, Sendable {
    case starting, manual, noFace, multipleFaces, lowLight, backlit
    case moveCloser, moveBack, moveLeft, moveRight, moveUp, moveDown
    case faceForward, levelHead, liftChin, lowerChin, aligned

    var message: String {
        switch self {
        case .starting: "Finding your frame…"
        case .manual: "Center your face; eyes near the dotted line"
        case .noFace: "Bring your face into the frame"
        case .multipleFaces: "Make this a moment just for you"
        case .lowLight: "Try a little more light in front of you"
        case .backlit: "Turn toward the light"
        case .moveCloser: "Move a little closer"
        case .moveBack: "Move a little farther away"
        case .moveLeft: "Move left in the frame"
        case .moveRight: "Move right in the frame"
        case .moveUp: "Bring your face a little higher"
        case .moveDown: "Bring your face a little lower"
        case .faceForward: "Look straight toward the camera"
        case .levelHead: "Gently level your head"
        case .liftChin: "Lift your chin a little"
        case .lowerChin: "Lower your chin a little"
        case .aligned: "Lovely. This is your frame."
        }
    }

    var symbol: String {
        switch self {
        case .starting: "viewfinder"
        case .manual: "viewfinder"
        case .noFace, .multipleFaces: "person.crop.rectangle"
        case .lowLight, .backlit: "sun.max"
        case .moveCloser: "arrow.down.right.and.arrow.up.left"
        case .moveBack: "arrow.up.left.and.arrow.down.right"
        case .moveLeft: "arrow.left"
        case .moveRight: "arrow.right"
        case .moveUp, .liftChin: "arrow.up"
        case .moveDown, .lowerChin: "arrow.down"
        case .faceForward: "face.smiling"
        case .levelHead: "level"
        case .aligned: "checkmark"
        }
    }
}

nonisolated enum GuidanceCondition: Equatable, Sendable {
    case unknown, adjust, good
}

nonisolated struct FaceGuidance: Equatable, Sendable {
    var cue: FaceGuidanceCue
    var face: GuidanceCondition = .unknown
    var position: GuidanceCondition = .unknown
    var light: GuidanceCondition = .unknown

    static let starting = FaceGuidance(cue: .starting)
    static let manual = FaceGuidance(cue: .manual)
    var isAligned: Bool { cue == .aligned }
}

nonisolated enum FaceGuidancePolicy {
    /// One actionable instruction at a time, prioritizing visibility before pose refinements.
    static func evaluate(faces: [FaceGeometry], light: FaceLightEstimate?, pose: PortraitPose) -> FaceGuidance {
        let lighting: GuidanceCondition
        let lightCue: FaceGuidanceCue?
        if let light, light.scene < 0.16 {
            lighting = .adjust
            lightCue = .lowLight
        } else if let light, let face = light.face, face < 0.24, light.scene - face > 0.16 {
            lighting = .adjust
            lightCue = .backlit
        } else {
            lighting = light == nil ? .unknown : .good
            lightCue = nil
        }

        guard !faces.isEmpty else {
            return FaceGuidance(cue: lightCue ?? .noFace, face: .adjust, light: lighting)
        }
        guard faces.count == 1 else {
            return FaceGuidance(cue: .multipleFaces, face: .adjust, light: lighting)
        }
        let face = faces[0]
        let positionCue = positionAdvice(face: face, pose: pose)
        let angleCue = angleAdvice(face: face)
        return FaceGuidance(
            cue: lightCue ?? positionCue ?? angleCue ?? .aligned,
            face: angleCue == nil ? .good : .adjust,
            position: positionCue == nil ? .good : .adjust,
            light: lighting
        )
    }

    private static func positionAdvice(face: FaceGeometry, pose: PortraitPose) -> FaceGuidanceCue? {
        // Height is less sensitive to yaw than face width and represents framing, not measured metres.
        if face.bounds.height < pose.faceHeight * 0.85 { return .moveCloser }
        if face.bounds.height > pose.faceHeight * 1.15 { return .moveBack }
        if face.bounds.midX < 0.43 { return .moveRight }
        if face.bounds.midX > 0.57 { return .moveLeft }
        let actualY = face.eyes?.y ?? face.bounds.midY
        let targetY = face.eyes == nil ? pose.centerY : pose.eyeLineY
        if actualY < targetY - 0.055 { return .moveDown }
        if actualY > targetY + 0.055 { return .moveUp }
        return nil
    }

    private static func angleAdvice(face: FaceGeometry) -> FaceGuidanceCue? {
        if let yaw = face.yaw, abs(yaw) > 0.22 { return .faceForward }
        if let roll = face.roll, abs(roll) > 0.14 { return .levelHead }
        if let pitch = face.pitch, pitch > 0.24 { return .liftChin }
        if let pitch = face.pitch, pitch < -0.24 { return .lowerChin }
        return nil
    }
}

/// Requires sustained advice for three sampled frames (~0.75s), avoiding flicker around thresholds.
nonisolated struct FaceGuidanceStabilizer {
    private(set) var current: FaceGuidance = .starting
    private var candidate: FaceGuidanceCue?
    private var candidateCount = 0

    mutating func reset() {
        current = .starting
        candidate = nil
        candidateCount = 0
    }

    mutating func update(_ next: FaceGuidance) -> FaceGuidance {
        guard next.cue != current.cue else {
            candidate = nil
            candidateCount = 0
            current = next
            return current
        }
        if candidate == next.cue { candidateCount += 1 }
        else { candidate = next.cue; candidateCount = 1 }
        if candidateCount >= 3 {
            current = next
            candidate = nil
            candidateCount = 0
        }
        return current
    }
}

nonisolated enum FacePreviewGeometry {
    /// Vision sees already rotated and mirrored pixel buffers. Convert its lower-left coordinates
    /// to the preview's upper-left coordinates and apply the same centered aspect-fill crop.
    static func rect(_ rect: CGRect, imageSize: CGSize) -> CGRect {
        let upperLeft = CGRect(x: rect.minX, y: 1 - rect.maxY, width: rect.width, height: rect.height)
        let transform = cropTransform(imageSize: imageSize)
        return upperLeft.applying(transform)
    }

    static func point(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
        CGPoint(x: point.x, y: 1 - point.y).applying(cropTransform(imageSize: imageSize))
    }

    /// Visible image region with a top-left origin, useful for sampling only light in the viewfinder.
    static func visibleImageRect(imageSize: CGSize) -> CGRect {
        CGRect(x: 0, y: 0, width: 1, height: 1).applying(cropTransform(imageSize: imageSize).inverted())
    }

    private static func cropTransform(imageSize: CGSize) -> CGAffineTransform {
        guard imageSize.width > 0, imageSize.height > 0 else { return .identity }
        let sourceAspect = imageSize.width / imageSize.height
        let targetAspect: CGFloat = 3 / 4
        let xScale = max(1, sourceAspect / targetAspect)
        let yScale = max(1, targetAspect / sourceAspect)
        return CGAffineTransform(a: xScale, b: 0, c: 0, d: yScale, tx: (1 - xScale) / 2, ty: (1 - yScale) / 2)
    }
}
