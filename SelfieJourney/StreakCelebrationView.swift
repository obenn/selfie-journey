import SwiftUI

/// A quiet acknowledgement after a successful save, including honest milestones.
struct StreakCelebrationView: View {
    let streak: Int
    var isRetake = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isRetake ? "checkmark" : "flame.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(JourneyTheme.accent)
                .frame(width: 45, height: 45)
                .background(JourneyTheme.softAccent, in: Circle())
                .symbolEffect(.bounce, value: appeared)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(StreakProgress.celebrationTitle(streak: streak, isRetake: isRetake))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(isRetake ? "Your daily streak stays right on track." : "Today's portrait is part of your story.")
                    .font(.caption).foregroundStyle(JourneyTheme.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: 500)
        .background(JourneyTheme.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(JourneyTheme.line, lineWidth: 0.7))
        .foregroundStyle(JourneyTheme.ink)
        .shadow(color: .black.opacity(0.08), radius: 16, y: 5)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("portrait.saved")
        .onAppear { if !reduceMotion { appeared = true } }
    }
}
