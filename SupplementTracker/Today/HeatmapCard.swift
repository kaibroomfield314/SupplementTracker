import SwiftUI

struct HeatmapCard: View {
    let days: [DayCount]   // expects 30 entries, oldest first

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 4), count: 10)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last 30 days")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(activeCount) active")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days) { day in
                    cell(for: day)
                }
            }
            HStack(spacing: 6) {
                Text("Less").font(.caption2).foregroundStyle(.secondary)
                ForEach([0, 1, 3, 6, 10], id: \.self) { v in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(for: v))
                        .frame(width: 12, height: 12)
                }
                Text("More").font(.caption2).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var activeCount: Int {
        days.filter { $0.count > 0 }.count
    }

    private func cell(for day: DayCount) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color(for: day.count))
            .aspectRatio(1, contentMode: .fit)
            .help(day.date.formatted(date: .abbreviated, time: .omitted))
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: return Color.secondary.opacity(0.15)
        case 1...2: return .green.opacity(0.35)
        case 3...5: return .green.opacity(0.6)
        case 6...9: return .green.opacity(0.85)
        default: return .green
        }
    }
}
