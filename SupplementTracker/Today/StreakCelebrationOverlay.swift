import SwiftUI

/// Compact banner pinned at the top of the dashboard for streak milestones.
/// Replaces the old full-screen confetti overlay.
struct StreakCelebrationOverlay: View {
    let milestone: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentColor)
                .frame(width: 3, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("MILESTONE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
                Text("\(milestone)-day streak")
                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
            }
            Spacer()
            Button {
                Haptics.tap(.light)
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear { Haptics.success() }
    }
}

enum StreakMilestones {
    static let levels: [Int] = [7, 14, 30, 60, 100, 365]

    static func milestone(for streak: Int) -> Int? {
        levels.first(where: { $0 == streak })
    }
}
