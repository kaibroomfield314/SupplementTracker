import SwiftUI

struct MiniCalendarCard: View {
    /// Set of date-start-of-day values where intakes occurred
    let activeDays: Set<Date>
    private let today: Date = Calendar.current.startOfDay(for: .now)

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(monthTitle)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(activeThisMonth) days active")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                ForEach(monthCells, id: \.id) { cell in
                    cellView(cell)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var monthTitle: String {
        today.formatted(.dateTime.month(.wide).year())
    }

    private var weekdaySymbols: [String] {
        let f = DateFormatter()
        return f.veryShortWeekdaySymbols
    }

    private var activeThisMonth: Int {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: today) ?? 1..<31
        let comp = cal.dateComponents([.year, .month], from: today)
        var count = 0
        for d in range {
            var c = comp
            c.day = d
            if let date = cal.date(from: c), activeDays.contains(date) {
                count += 1
            }
        }
        return count
    }

    private struct Cell: Identifiable {
        let id = UUID()
        let date: Date?
        let day: Int?
    }

    private var monthCells: [Cell] {
        let cal = Calendar.current
        let comp = cal.dateComponents([.year, .month], from: today)
        guard let first = cal.date(from: comp),
              let range = cal.range(of: .day, in: .month, for: today)
        else { return [] }
        let firstWeekday = cal.component(.weekday, from: first) // 1 = Sunday
        var cells: [Cell] = []
        for _ in 1..<firstWeekday { cells.append(Cell(date: nil, day: nil)) }
        for d in range {
            var c = comp
            c.day = d
            cells.append(Cell(date: cal.date(from: c), day: d))
        }
        return cells
    }

    private func cellView(_ cell: Cell) -> some View {
        Group {
            if let date = cell.date, let day = cell.day {
                let isActive = activeDays.contains(date)
                let isToday = Calendar.current.isDate(date, inSameDayAs: today)
                ZStack {
                    if isActive {
                        Circle().fill(Color.green.opacity(isToday ? 1.0 : 0.55))
                    } else if isToday {
                        Circle().strokeBorder(.tint, lineWidth: 1.5)
                    }
                    Text("\(day)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(isActive ? Color.white : .primary)
                }
                .aspectRatio(1, contentMode: .fit)
            } else {
                Color.clear.aspectRatio(1, contentMode: .fit)
            }
        }
    }
}
