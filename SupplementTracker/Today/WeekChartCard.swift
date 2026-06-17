import SwiftUI
import Charts

struct WeekChartCard: View {
    let days: [DayCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last 7 days")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(totalCount) logs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            chart
                .frame(height: 130)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            .cornerRadius(6)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.cyan, Color.mint],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.weekday(.narrow))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
    }
}
