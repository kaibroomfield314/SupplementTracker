import SwiftUI
import SwiftData

struct AddStackSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existing: SupplementStack?

    @State private var name: String = ""
    @State private var notes: String = ""

    init(existing: SupplementStack? = nil) {
        self.existing = existing
        if let existing {
            _name = State(initialValue: existing.name)
            _notes = State(initialValue: existing.notes)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (e.g. Morning Stack)", text: $name)
                        .frame(maxWidth: 300)
                } header: { Text("Basics") }
                Section {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                } header: { Text("Notes") }
                Section {} footer: {
                    Text("Add supplements with their doses on the next screen after saving.")
                }
            }
            .navigationTitle(existing == nil ? "New Stack" : "Edit Stack")
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
            existing.notes = notes
        } else {
            let stack = SupplementStack(name: name, notes: notes)
            modelContext.insert(stack)
        }
        dismiss()
    }
}
