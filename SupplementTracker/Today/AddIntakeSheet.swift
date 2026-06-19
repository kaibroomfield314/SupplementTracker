import SwiftUI
import SwiftData

struct AddIntakeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var supplements: [Supplement]

    @State private var selected: Supplement?
    @State private var amount: Double = 0
    @State private var unit: String = "mg"
    @State private var date: Date = .now
    @State private var notes: String = ""

    init(preselected: Supplement? = nil) {
        _selected = State(initialValue: preselected)
        if let pre = preselected {
            _amount = State(initialValue: pre.defaultDose)
            _unit = State(initialValue: pre.unit)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement") {
                    Picker("Supplement", selection: $selected) {
                        Text("Select…").tag(Supplement?.none)
                        ForEach(supplements.sorted(by: { $0.name < $1.name })) { sup in
                            Text(sup.name).tag(Supplement?.some(sup))
                        }
                    }
                    .onChange(of: selected) { _, new in
                        if let new {
                            if amount == 0 { amount = new.defaultDose }
                            if unit.isEmpty || unit == "mg" { unit = new.unit }
                        }
                    }
                }

                Section("Amount") {
                    AmountUnitField(amount: $amount, unit: $unit)
                    DatePicker("Time", selection: $date)
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Log Intake")
            #if os(iOS)
            .toolbarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selected == nil || amount <= 0)
                }
            }
        }
    }

    private func save() {
        guard let selected else { return }
        let intake = SupplementIntake(
            date: date,
            amount: amount,
            unit: unit,
            notes: notes,
            supplement: selected
        )
        modelContext.insert(intake)
        dismiss()
    }
}
