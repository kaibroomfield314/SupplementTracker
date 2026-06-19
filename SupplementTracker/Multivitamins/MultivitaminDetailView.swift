import SwiftUI
import SwiftData

struct MultivitaminDetailView: View {
    @Bindable var multivitamin: Multivitamin
    @Environment(\.modelContext) private var modelContext
    @State private var showingEdit = false
    @State private var showingAddIngredient = false
    @State private var showingScan = false
    @State private var lastLoggedCount: Int?
    @State private var servingsToLog: Int = 1

    private var sortedIngredients: [MultivitaminIngredient] {
        (multivitamin.ingredients ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            headerSection
            logSection
            ingredientsSection
        }
        .navigationTitle(multivitamin.name.isEmpty ? "Multivitamin" : multivitamin.name)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingScan = true
                    } label: {
                        Label("Scan Label", systemImage: "doc.text.viewfinder")
                    }
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit Multivitamin", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddMultivitaminSheet(existing: multivitamin)
        }
        .sheet(isPresented: $showingAddIngredient) {
            IngredientEditorSheet(multivitamin: multivitamin)
        }
        .sheet(isPresented: $showingScan) {
            ScanReviewSheet(multivitamin: multivitamin)
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        Section {
            if !multivitamin.brand.isEmpty {
                LabeledContent("Brand", value: multivitamin.brand)
            }
            LabeledContent("Ingredients", value: "\(multivitamin.ingredientCount)")
            if !multivitamin.notes.isEmpty {
                Text(multivitamin.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var logSection: some View {
        Section {
            Stepper(value: $servingsToLog, in: 1...10) {
                HStack {
                    Text("Servings")
                    Spacer()
                    Text("\(servingsToLog)")
                        .font(.body.monospacedDigit().weight(.semibold))
                        .contentTransition(.numericText())
                }
            }
            Button {
                logAll()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(servingsToLog == 1 ? "Log 1 serving" : "Log \(servingsToLog) servings")
                    Spacer()
                    if let count = lastLoggedCount {
                        Text("logged \(count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.body.weight(.medium))
            }
            .disabled(sortedIngredients.isEmpty)
        } footer: {
            Text("Each ingredient is recorded as its own intake at the current time, scaled by the serving count.")
        }
    }

    @ViewBuilder
    private var ingredientsSection: some View {
        Section {
            if sortedIngredients.isEmpty {
                Text("No ingredients yet. Tap + to add one.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedIngredients) { ingredient in
                    IngredientRow(ingredient: ingredient)
                }
                .onDelete(perform: deleteIngredients)
            }
            Button {
                showingAddIngredient = true
            } label: {
                Label("Add Ingredient", systemImage: "plus.circle")
            }
        } header: {
            Text("Ingredients")
        }
    }

    private func logAll() {
        do {
            let n = try MultivitaminLogger.log(
                multivitamin: multivitamin,
                servings: servingsToLog,
                in: modelContext
            )
            lastLoggedCount = n
        } catch {
            lastLoggedCount = nil
        }
    }

    private func deleteIngredients(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedIngredients[index])
        }
    }
}

private struct IngredientRow: View {
    let ingredient: MultivitaminIngredient

    var body: some View {
        HStack {
            Text(ingredient.name)
            Spacer()
            Text("\(ingredient.amount.clean) \(ingredient.unit)")
                .foregroundStyle(.secondary)
                .font(.subheadline.monospacedDigit())
        }
    }
}

struct IngredientEditorSheet: View {
    let multivitamin: Multivitamin
    var existing: MultivitaminIngredient?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var amount: Double = 0
    @State private var unit: String = "mg"

    init(multivitamin: Multivitamin, existing: MultivitaminIngredient? = nil) {
        self.multivitamin = multivitamin
        self.existing = existing
        if let existing {
            _name = State(initialValue: existing.name)
            _amount = State(initialValue: existing.amount)
            _unit = State(initialValue: existing.unit)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (e.g. Vitamin D3)", text: $name)
                    AmountUnitField(amount: $amount, unit: $unit)
                }
            }
            .navigationTitle(existing == nil ? "Add Ingredient" : "Edit Ingredient")
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
            existing.amount = amount
            existing.unit = unit
        } else {
            let nextOrder = ((multivitamin.ingredients ?? []).map(\.sortOrder).max() ?? -1) + 1
            let ingredient = MultivitaminIngredient(
                name: name,
                amount: amount,
                unit: unit,
                sortOrder: nextOrder,
                multivitamin: multivitamin
            )
            modelContext.insert(ingredient)
        }
        dismiss()
    }
}
