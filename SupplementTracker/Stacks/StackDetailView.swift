import SwiftUI
import SwiftData

struct StackDetailView: View {
    @Bindable var stack: SupplementStack
    @Environment(\.modelContext) private var modelContext
    @State private var showingEdit = false
    @State private var showingAddItem = false
    @State private var lastLoggedCount: Int?

    private var sortedItems: [StackItem] {
        (stack.items ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Section {
                if !stack.notes.isEmpty {
                    Text(stack.notes)
                        .foregroundStyle(.secondary)
                }
                Button {
                    logAll()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log all now")
                        Spacer()
                        if let n = lastLoggedCount {
                            Text("logged \(n)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.body.weight(.medium))
                }
                .disabled(sortedItems.isEmpty)
            }

            Section {
                if sortedItems.isEmpty {
                    Text("No supplements yet. Tap + to add one.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedItems) { item in
                        StackItemRow(item: item)
                    }
                    .onDelete { offsets in
                        for i in offsets { modelContext.delete(sortedItems[i]) }
                    }
                }
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Supplement", systemImage: "plus.circle")
                }
            } header: {
                Text("Supplements")
            }
        }
        .navigationTitle("\(stack.emoji) \(stack.name)")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddStackSheet(existing: stack)
        }
        .sheet(isPresented: $showingAddItem) {
            StackItemEditorSheet(stack: stack)
        }
    }

    private func logAll() {
        do {
            let n = try StackLogger.log(stack: stack, in: modelContext)
            lastLoggedCount = n
            Haptics.success()
        } catch {
            lastLoggedCount = nil
            Haptics.error()
        }
    }
}

private struct StackItemRow: View {
    let item: StackItem
    var body: some View {
        HStack {
            Image(systemName: item.supplement?.category.symbol ?? "pills")
                .foregroundStyle(.tint)
                .frame(width: 28)
            Text(item.supplement?.name ?? "—")
            Spacer()
            Text("\(item.amount.clean) \(item.unit)")
                .foregroundStyle(.secondary)
                .font(.subheadline.monospacedDigit())
        }
    }
}

struct StackItemEditorSheet: View {
    let stack: SupplementStack
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Supplement.name) private var supplements: [Supplement]

    @State private var selected: Supplement?
    @State private var amount: Double = 0
    @State private var unit: String = "mg"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Supplement", selection: $selected) {
                        Text("Select…").tag(Supplement?.none)
                        ForEach(supplements) { sup in
                            Text(sup.name).tag(Supplement?.some(sup))
                        }
                    }
                    .onChange(of: selected) { _, new in
                        if let new {
                            if amount == 0 { amount = new.defaultDose }
                            if unit == "mg" { unit = new.unit }
                        }
                    }
                }
                Section {
                    AmountUnitField(amount: $amount, unit: $unit)
                } header: { Text("Dose per serving of the stack") }
            }
            .navigationTitle("Add to Stack")
            .toolbarTitleDisplayMode(.inline)
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
        let nextOrder = ((stack.items ?? []).map(\.sortOrder).max() ?? -1) + 1
        let item = StackItem(
            amount: amount,
            unit: unit,
            sortOrder: nextOrder,
            supplement: selected,
            stack: stack
        )
        modelContext.insert(item)
        dismiss()
    }
}
