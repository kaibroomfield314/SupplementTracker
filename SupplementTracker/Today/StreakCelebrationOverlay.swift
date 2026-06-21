import SwiftUI

struct StreakCelebrationOverlay: View {
    let milestone: Int
    let onDismiss: () -> Void

    @State private var animateBurst = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 18) {
                Text("🔥")
                    .font(.system(size: 80))
                    .scaleEffect(animateBurst ? 1.1 : 0.6)
                    .rotationEffect(.degrees(animateBurst ? 10 : -10))
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).repeatForever(autoreverses: true), value: animateBurst)
                Text("\(milestone)-day streak!")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button {
                    Haptics.tap(.medium)
                    onDismiss()
                } label: {
                    Text("Keep it going")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 36)
                        .background(
                            Capsule().fill(.white)
                        )
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            animateBurst = true
            Haptics.success()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.85)))
    }

    private var message: String {
        switch milestone {
        case 7: return "A full week locked in. Compound interest beats hype."
        case 14: return "Two weeks. The habit is forming."
        case 30: return "A month. This is who you are now."
        case 60: return "Two months of consistency. Elite tier."
        case 100: return "Triple digits. You're the kind of person who shows up."
        case 365: return "A YEAR. Take a moment."
        default: return "Streak milestone unlocked."
        }
    }
}

enum StreakMilestones {
    static let levels: [Int] = [7, 14, 30, 60, 100, 365]

    /// Returns the highest milestone reached at exactly this streak length,
    /// or nil if the current streak isn't a celebration value.
    static func milestone(for streak: Int) -> Int? {
        levels.first(where: { $0 == streak })
    }
}
