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
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loggedCount != nil ? "Logged \(loggedCount!) intakes" : "Repeat yesterday")
                        .font(.subheadline.weight(.medium))
                        .contentTransition(.numericText())
                    Text(yesterdayCount > 0
                         ? "Copy all \(yesterdayCount) of yesterday's intakes to today"
                         : "Nothing logged yesterday yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .disabled(yesterdayCount == 0)
        .opacity(yesterdayCount == 0 ? 0.55 : 1.0)
    }
}
