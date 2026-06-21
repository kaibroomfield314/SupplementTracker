import SwiftUI
import Charts

struct WeekChartCard: View {
    let days: [DayCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "7D", trailing: "\(totalCount) logs")
            chart.frame(height: 110)
        }
        .cardSurface()
    }

    private var totalCount: Int {
        days.reduce(0) { $0 + $1.count }
    }

    private var chart: some View {
        Chart(days) { day in
            BarMark(
                x: .value("Day", day.date, unit: .day),
                y: .value("Logs", day.count)
            )
            .cornerRadius(3)
            .foregroundStyle(Color.accentColor)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.weekday(.narrow))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
    }
}
