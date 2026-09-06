import SwiftUI

// An editorial palette that follows the system appearance.
enum JourneyTheme {
    static let background = Color("Paper")
    static let surface = Color("Card")
    static let ink = Color("Ink")
    static let secondary = Color("Quiet")
    static let accent = Color("Terracotta")
    static let softAccent = Color("Blush")
    static let line = Color("Rule")
    static let sage = Color("Sage")

    static func serif(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif) }

}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(2).foregroundStyle(JourneyTheme.secondary)
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol = "camera"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 19, weight: .medium))
                Text(title).font(.system(.body, design: .rounded, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 23).padding(.vertical, 19)
            .background(Color(red: 0.78, green: 0.31, blue: 0.18), in: RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}
