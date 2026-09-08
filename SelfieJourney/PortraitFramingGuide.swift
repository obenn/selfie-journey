import SwiftUI

/// Shared by the camera and pose cards. The brackets suggest a framing area;
/// the eye line provides a consistent reference without prescribing anatomy.
struct PortraitFramingGuide: View {
    let pose: PortraitPose
    let color: Color
    var aligned = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let bounds = pose.framingBounds
            let frameWidth = width * bounds.width
            let frameHeight = height * bounds.height
            ZStack {
                FramingBrackets()
                    .stroke(color.opacity(aligned ? 0.95 : 0.8),
                            style: StrokeStyle(lineWidth: aligned ? 2.2 : 1.6,
                                               lineCap: .round, lineJoin: .round))
                    .frame(width: frameWidth, height: frameHeight)
                    .position(x: width * bounds.midX, y: height * bounds.midY)
                Path { path in
                    let eyeY = height * pose.eyeLineY
                    path.move(to: CGPoint(x: width * 0.5 - frameWidth * 0.42, y: eyeY))
                    path.addLine(to: CGPoint(x: width * 0.5 + frameWidth * 0.42, y: eyeY))
                }
                .stroke(color.opacity(0.65), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 5]))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FramingBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(rect.width, rect.height) * 0.25
        let radius = length * 0.55
        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                              control: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

            path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                              control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                              control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

            path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                              control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        }
    }
}
