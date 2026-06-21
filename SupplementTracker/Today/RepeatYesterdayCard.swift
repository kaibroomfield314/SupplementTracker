import SwiftUI

struct RepeatYesterdayCard: View {
    let yesterdayCount: Int
    let onRepeat: () -> Int
    @State private var loggedCount: Int?

    var body: some View {
        Button {
            let n = onRepeat()
            loggedCount = n
            if n > 0 { Haptics.success() } else { Haptics.warning() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(loggedCount != nil ? "Logged \(loggedCount!)" : "Repeat yesterday")
                    .font(.system(size: 13, weight: .semibold))
                    .contentTransition(.numericText())
                Spacer()
                Text("\(yesterdayCount) ITEMS")
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .tracking(0.4)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DS.cardPadding)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.cardBG)
            )
        }
        .buttonStyle(.plain)
        .disabled(yesterdayCount == 0)
        .opacity(yesterdayCount == 0 ? 0.5 : 1.0)
    }
}
