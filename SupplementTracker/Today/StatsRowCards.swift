import SwiftUI

struct StatsRowCards: View {
    let streak: StreakInfo?
    let weekDelta: Double?

    var body: some View {
        HStack(spacing: 10) {
            StreakCard(streak: streak)
            WeekDeltaCard(delta: weekDelta)
        }
    }
}

struct StreakCard: View {
    let streak: StreakInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "Streak")
            BigStat(value: streakValue, unit: streak == nil ? nil : "d", size: 28)
            Text(subtitle.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: DS.chipRadius)
    }

    private var streakValue: String {
        guard let streak else { return "—" }
        return "\(streak.days)"
    }

    private var subtitle: String {
        streak?.supplementName ?? "No active streak"
    }
}

struct WeekDeltaCard: View {
    let delta: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "7D vs prev")
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: arrowSymbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(deltaColor)
                Text(percentText)
                    .font(.system(size: 28, weight: .semibold).monospacedDigit())
                    .foregroundStyle(deltaColor)
                    .contentTransition(.numericText())
            }
            Text("INTAKE VOLUME")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: DS.chipRadius)
    }

    private var arrowSymbol: String {
        guard let delta else { return "minus" }
        if delta > 0.01 { return "arrow.up.right" }
        if delta < -0.01 { return "arrow.down.right" }
        return "minus"
    }

    private var deltaColor: Color {
        guard let delta else { return .secondary }
        if delta > 0.01 { return .accentColor }
        if delta < -0.01 { return .secondary }
        return .secondary
    }

    private var percentText: String {
        guard let delta else { return "—" }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(Int((delta * 100).rounded()))%"
    }
}
