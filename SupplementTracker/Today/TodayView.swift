import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [Supplement]
    @Query private var intakes: [SupplementIntake]
    @Query private var readings: [BloodMarkerReading]

    @State private var showingAdd = false
    @State private var prefillSupplement: Supplement?

    private var metrics: DashboardMetrics {
        DashboardMetrics.compute(
            supplements: supplements,
            intakes: intakes,
            readings: readings
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GreetingHeader()

                    TodayRingCard(
                        taken: metrics.todayUniqueCount,
                        target: max(metrics.typicalCount, 1),
                        progress: metrics.completionProgress
                    )

                    StatsRowCards(
                        streak: metrics.topStreak,
                        weekDelta: metrics.weekDeltaPercent
                    )

                    WeekChartCard(days: metrics.last7Days)

                    RecentBloodCard(markers: metrics.recentMarkers)

                    if !supplements.isEmpty {
                        QuickLogStrip(
                            supplements: supplements.sorted(by: { $0.name < $1.name }),
                            onLog: { sup in
                                prefillSupplement = sup
                                showingAdd = true
                            }
                        )
                    }

                    TodayIntakesCard(
                        intakes: metrics.todayIntakes,
                        onDelete: { intake in
                            modelContext.delete(intake)
                        },
                        onAdd: { showingAdd = true }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: metrics.todayUniqueCount)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: metrics.topStreak)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd, onDismiss: { prefillSupplement = nil }) {
                AddIntakeSheet(preselected: prefillSupplement)
            }
        }
    }
}

struct GreetingHeader: View {
    private let date = Date.now

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(.title, design: .rounded).weight(.bold))
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hey, night owl"
        }
    }
}

struct QuickLogStrip: View {
    let supplements: [Supplement]
    let onLog: (Supplement) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Quick log")
                    .font(.subheadline.bold())
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(supplements) { sup in
                        QuickLogChip(supplement: sup, onTap: { onLog(sup) })
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct QuickLogChip: View {
    let supplement: Supplement
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: supplement.category.symbol)
                    .font(.title3)
                    .foregroundStyle(.tint)
                Text(supplement.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if supplement.defaultDose > 0 {
                    Text("\(supplement.defaultDose.clean) \(supplement.unit)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 130, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%g", self)
    }
}
