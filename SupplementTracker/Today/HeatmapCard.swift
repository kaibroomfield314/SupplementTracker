import SwiftUI

struct HeatmapCard: View {
    let days: [DayCount]   // 30 entries, oldest first

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 3), count: 10)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "30D", trailing: "\(activeCount) active")
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(days) { day in
                    cell(for: day)
                }
            }
            HStack(spacing: 4) {
                Text("LOW")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(.secondary)
                ForEach([0, 1, 3, 6, 10], id: \.self) { v in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: v))
                        .frame(width: 10, height: 10)
                }
                Text("HIGH")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.top, 2)
        }
        .cardSurface()
    }

    private var activeCount: Int {
        days.filter { $0.count > 0 }.count
    }

    private func cell(for day: DayCount) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color(for: day.count))
            .aspectRatio(1, contentMode: .fit)
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: return DS.trackColor
        case 1...2: return .accentColor.opacity(0.3)
        case 3...5: return .accentColor.opacity(0.55)
        case 6...9: return .accentColor.opacity(0.8)
        default: return .accentColor
        }
    }
}
