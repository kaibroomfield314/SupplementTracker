import SwiftUI
import SwiftData

struct SupplementDetailView: View {
    @Bindable var supplement: Supplement
    @State private var showingEdit = false

    private var sortedIntakes: [SupplementIntake] {
        (supplement.intakes ?? []).sorted { $0.date > $1.date }
    }

    private var last30DaysCount: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return sortedIntakes.filter { $0.date >= cutoff }.count
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Category", value: supplement.category.rawValue)
                if !supplement.brand.isEmpty {
                    LabeledContent("Brand", value: supplement.brand)
                }
                if supplement.defaultDose > 0 {
                    LabeledContent("Default dose", value: "\(supplement.defaultDose.clean) \(supplement.unit)")
                }
                LabeledContent("Last 30 days", value: "\(last30DaysCount) intakes")
            }

            if !supplement.notes.isEmpty {
                Section("Notes") {
                    Text(supplement.notes)
                }
            }

            Section("History") {
                if sortedIntakes.isEmpty {
                    Text("No intakes logged yet").foregroundStyle(.secondary)
                } else {
                    ForEach(sortedIntakes) { intake in
                        VStack(alignment: .leading) {
                            Text(intake.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.body)
                            Text("\(intake.amount.clean) \(intake.unit)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(supplement.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddSupplementSheet(existing: supplement)
        }
    }
}
