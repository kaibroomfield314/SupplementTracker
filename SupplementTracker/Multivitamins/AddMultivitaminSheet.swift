import SwiftUI
import SwiftData

struct AddMultivitaminSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existing: Multivitamin?

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var notes: String = ""

    init(existing: Multivitamin? = nil) {
        self.existing = existing
        if let existing {
            _name = State(initialValue: existing.name)
            _brand = State(initialValue: existing.brand)
            _notes = State(initialValue: existing.notes)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (e.g. Animal Pak)", text: $name)
                    TextField("Brand (optional)", text: $brand)
                } header: {
                    Text("Basics")
                }

                Section {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add ingredients on the next screen after saving.")
                }
            }
            .navigationTitle(existing == nil ? "New Multivitamin" : "Edit Multivitamin")
            .toolbarTitleDisplayMode(.inline)
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
            existing.notes = notes
        } else {
            let multi = Multivitamin(name: name, brand: brand, notes: notes)
            modelContext.insert(multi)
        }
        dismiss()
    }
}
