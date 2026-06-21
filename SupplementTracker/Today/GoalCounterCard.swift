import SwiftUI

struct GoalCounterCard: View {
    @AppStorage(UserPreferenceKeys.goalName) private var goalName: String = ""
    @AppStorage(UserPreferenceKeys.goalStart) private var goalStartTimestamp: Double = 0
    @AppStorage(UserPreferenceKeys.goalDays) private var goalDays: Int = 0

    var body: some View {
        if let goal {
            HStack(spacing: 14) {
                Image(systemName: "flag.checkered")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.subheadline.bold())
                    HStack(spacing: 6) {
                        Text("Day \(goal.elapsedDays)")
                            .font(.title2.bold().monospacedDigit())
                            .contentTransition(.numericText())
                        Text("of \(goal.totalDays)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: goal.progress)
                        .tint(.indigo)
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
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
