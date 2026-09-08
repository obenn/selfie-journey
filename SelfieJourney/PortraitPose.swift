import CoreGraphics
import Foundation

/// A consistent portrait crop, shared by setup, the viewfinder, and Vision.
/// Coordinates are normalized in the upright, mirrored 3:4 viewfinder, with
/// the origin at its top-left. Face dimensions target Vision's face bounds;
/// the open framing guide leaves room for different face shapes around those targets.
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

    /// A generous framing region, not a head or shoulder outline. This stays
    /// fixed for each distance so it remains a useful reference across days.
    var framingBounds: CGRect {
        CGRect(x: 0.5 - faceWidth * 0.66,
               y: centerY - faceHeight * 0.62,
               width: faceWidth * 1.32,
               height: faceHeight * 1.20)
    }
}
