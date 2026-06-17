import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [Supplement]
    @Query private var allIntakes: [SupplementIntake]

    @State private var showingAdd = false
    @State private var prefillSupplement: Supplement?

    private var todayIntakes: [SupplementIntake] {
        let cal = Calendar.current
        return allIntakes
            .filter { cal.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today, \(Date.now.formatted(date: .complete, time: .omitted))") {
                    if todayIntakes.isEmpty {
                        ContentUnavailableView(
                            "Nothing logged yet",
                            systemImage: "sun.max",
                            description: Text("Tap a supplement below or use + to log an intake.")
                        )
                    } else {
                        ForEach(todayIntakes) { intake in
                            IntakeRow(intake: intake)
                        }
                        .onDelete(perform: deleteIntakes)
                    }
                }

                if !supplements.isEmpty {
                    Section("Quick log") {
                        ForEach(supplements.sorted(by: { $0.name < $1.name })) { sup in
                            Button {
                                prefillSupplement = sup
                                showingAdd = true
                            } label: {
                                HStack {
                                    Image(systemName: sup.category.symbol)
                                        .frame(width: 28)
                                        .foregroundStyle(.tint)
                                    VStack(alignment: .leading) {
                                        Text(sup.name).font(.body)
                                        if sup.defaultDose > 0 {
                                            Text("\(sup.defaultDose.clean) \(sup.unit)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Today")
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

    private func deleteIntakes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todayIntakes[index])
        }
    }
}

struct IntakeRow: View {
    let intake: SupplementIntake

    var body: some View {
        HStack {
            Image(systemName: intake.supplement?.category.symbol ?? "pills")
                .frame(width: 28)
                .foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text(intake.supplement?.name ?? "Unknown")
                    .font(.body)
                Text("\(intake.amount.clean) \(intake.unit) · \(intake.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%g", self)
    }
}
