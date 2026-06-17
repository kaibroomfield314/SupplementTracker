import SwiftUI

struct StatsRowCards: View {
    let streak: StreakInfo?
    let weekDelta: Double?

    var body: some View {
        HStack(spacing: 12) {
            StreakCard(streak: streak)
            WeekDeltaCard(delta: weekDelta)
        }
    }
}

struct StreakCard: View {
    let streak: StreakInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("🔥")
                Text("Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            Text(daysText)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var daysText: String {
        guard let streak else { return "—" }
        return streak.days == 1 ? "1 day" : "\(streak.days) days"
    }

    private var subtitle: String {
        streak?.supplementName ?? "No streak yet"
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
    }
}

struct WeekDeltaCard: View {
    let delta: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: arrowSymbol)
                    .foregroundStyle(deltaColor)
                Text("This week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            Text(percentText)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(deltaColor)
                .contentTransition(.numericText())
            Text("vs previous 7 days")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var arrowSymbol: String {
        guard let delta else { return "minus" }
        if delta > 0.01 { return "arrow.up.right" }
        if delta < -0.01 { return "arrow.down.right" }
        return "minus"
    }

    private var deltaColor: Color {
        guard let delta else { return .secondary }
        if delta > 0.01 { return .green }
        if delta < -0.01 { return .orange }
        return .secondary
    }

    private var percentText: String {
        guard let delta else { return "—" }
        let sign = delta > 0 ? "+" : ""
        let pct = Int((delta * 100).rounded())
        return "\(sign)\(pct)%"
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
    }
}
