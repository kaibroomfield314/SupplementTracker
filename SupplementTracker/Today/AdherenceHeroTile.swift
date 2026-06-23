import SwiftUI

struct AdherenceHeroTile: View {
    let taken: Int
    let target: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Today")

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(taken)")
                    .font(.system(size: 88, weight: .semibold, design: .default).monospacedDigit())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text("/")
                    .font(.system(size: 44, weight: .light, design: .default))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 2)
                Text("\(target)")
                    .font(.system(size: 44, weight: .medium, design: .default).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            Text("OF \(target) TODAY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(DS.trackColor, lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: max(0.001, min(progress, 1.0)))
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(DS.snap, value: progress)
                }
                .frame(width: 26, height: 26)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())

                Spacer()

                Text(footerText)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
            }
        }
        .cardSurface(radius: DS.chipRadius)
        .frame(maxWidth: .infinity)
    }

    private var footerText: String {
        guard target > 0 else { return "CONFIGURE STACK" }
        if taken >= target { return "TARGET MET" }
        return "\(max(0, target - taken)) REMAINING"
    }
}
