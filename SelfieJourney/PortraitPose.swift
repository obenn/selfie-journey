import Foundation

/// A consistent portrait crop, shared by setup, the viewfinder, and Vision.
/// Coordinates are normalized in the upright, mirrored 3:4 viewfinder, with
/// the origin at its top-left. Face dimensions target Vision's face bounds;
/// the decorative guide includes a little more room above the forehead.
nonisolated enum PortraitPose: String, CaseIterable, Identifiable, Sendable {
    case close
    case classic
    case relaxed
    case wide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .close: "Close-up"
        case .classic: "Classic"
        case .relaxed: "Relaxed"
        case .wide: "Wide"
        }
    }

    var subtitle: String {
        switch self {
        case .close: "Every little detail"
        case .classic: "Face & shoulders"
        case .relaxed: "A little breathing room"
        case .wide: "More of your world"
        }
    }

    var faceWidth: Double {
        switch self {
        case .close: 0.58
        case .classic: 0.47
        case .relaxed: 0.36
        case .wide: 0.28
        }
    }

    var faceHeight: Double {
        switch self {
        case .close: 0.62
        case .classic: 0.50
        case .relaxed: 0.39
        case .wide: 0.30
        }
    }

    var centerY: Double { 0.44 }
    var eyeLineY: Double { centerY - faceHeight * 0.12 }
}
