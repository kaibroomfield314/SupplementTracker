import SwiftUI
import SwiftData

struct AddSupplementSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existing: Supplement?

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var category: SupplementCategory = .vitamin
    @State private var defaultDose: Double = 0
    @State private var unit: String = "mg"
    @State private var notes: String = ""

    init(existing: Supplement? = nil) {
        self.existing = existing
        if let existing {
            _name = State(initialValue: existing.name)
            _brand = State(initialValue: existing.brand)
            _category = State(initialValue: existing.category)
            _defaultDose = State(initialValue: existing.defaultDose)
            _unit = State(initialValue: existing.unit)
            _notes = State(initialValue: existing.notes)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name (e.g. Vitamin D3)", text: $name)
                    TextField("Brand (optional)", text: $brand)
                    Picker("Category", selection: $category) {
                        ForEach(SupplementCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbol).tag(cat)
                        }
                    }
                }
                Section("Default dose") {
                    AmountUnitField(amount: $defaultDose, unit: $unit)
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(existing == nil ? "New Supplement" : "Edit Supplement")
            #if os(iOS)
            .toolbarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        if let existing {
            existing.name = name
            existing.brand = brand
            existing.category = category
            existing.defaultDose = defaultDose
            existing.unit = unit
            existing.notes = notes
        } else {
            let sup = Supplement(
                name: name,
                brand: brand,
                category: category,
                defaultDose: defaultDose,
                unit: unit,
                notes: notes
            )
            modelContext.insert(sup)
        }
        dismiss()
    }
}
