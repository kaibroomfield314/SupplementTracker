import SwiftUI

struct TodayRingCard: View {
    let taken: Int
    let target: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 24) {
            ringView
            statsView
            Spacer()
        }
        .padding(20)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var ringView: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.green, Color.mint, Color.cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .frame(width: 110, height: 110)
    }

    private var statsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text("\(taken) of \(target)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(supportText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var supportText: String {
        if target == 0 { return "Add supplements to track" }
        if taken >= target { return "Stack complete 🎯" }
        let remaining = max(0, target - taken)
        return "\(remaining) more to hit your usual stack"
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
    }
}
