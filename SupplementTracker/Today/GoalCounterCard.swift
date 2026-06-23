import SwiftUI

struct GoalCounterCard: View {
    @AppStorage(UserPreferenceKeys.goalName) private var goalName: String = ""
    @AppStorage(UserPreferenceKeys.goalStart) private var goalStartTimestamp: Double = 0
    @AppStorage(UserPreferenceKeys.goalDays) private var goalDays: Int = 0

    var body: some View {
        if let goal {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: goal.name, trailing: "\(Int(goal.progress * 100))%")
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(goal.elapsedDays)")
                        .font(.system(size: 32, weight: .semibold).monospacedDigit())
                        .contentTransition(.numericText())
                    Text("/ \(goal.totalDays)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("DAYS")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(.secondary)
                }
                ProgressBar(progress: goal.progress)
                    .frame(height: 4)
            }
            .cardSurface(radius: DS.chipRadius)
        }
    }

    private var goal: GoalInfo? {
        guard !goalName.isEmpty, goalStartTimestamp > 0, goalDays > 0 else { return nil }
        return GoalInfo(
            name: goalName,
            startDate: Date(timeIntervalSince1970: goalStartTimestamp),
            totalDays: goalDays
        )
    }
}

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(DS.trackColor)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * max(0, min(progress, 1.0)))
                    .animation(DS.snap, value: progress)
            }
        }
    }
}
