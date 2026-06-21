import SwiftUI

struct TodayRingCard: View {
    let taken: Int
    let target: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 18) {
            ringView
                .frame(width: 92, height: 92)
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Today")
                BigStat(value: "\(taken)", unit: "/ \(target)", size: 30)
                Text(supportText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .cardSurface()
    }

    private var ringView: some View {
        ZStack {
            Circle()
                .stroke(DS.trackColor, lineWidth: DS.ringStroke)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1.0)))
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: DS.ringStroke, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DS.snap, value: progress)
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))")
                    .font(.system(size: 22, weight: .semibold).monospacedDigit())
                    .contentTransition(.numericText())
                Text("%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .offset(y: -2)
            }
        }
    }

    private var supportText: String {
        if target == 0 { return "Configure typical stack" }
        if taken >= target { return "Target met" }
        return "\(max(0, target - taken)) remaining"
    }
}
