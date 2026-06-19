import SwiftUI
import SwiftData

struct LogGroupDetailView: View {
    let group: MultivitaminLogGroup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false

    private var sortedIntakes: [SupplementIntake] {
        group.intakes.sorted { (a, b) in
            (a.supplement?.name ?? "") < (b.supplement?.name ?? "")
        }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Multivitamin", value: group.multivitamin.name.isEmpty ? "—" : group.multivitamin.name)
                LabeledContent("Servings logged", value: "\(group.servings)")
                LabeledContent("Logged at", value: group.date.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Ingredients", value: "\(group.ingredientCount)")
            }

            Section {
                ForEach(sortedIntakes) { intake in
                    IntakeRow(intake: intake)
                }
            } header: {
                Text("Logged ingredients")
            } footer: {
                Text("Each row was created as an individual intake so the dashboard counts it.")
            }

            Section {
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("Delete entire log", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Log Detail")
        .toolbarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete all \(group.ingredientCount) ingredient logs from this multivitamin?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteAll()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func deleteAll() {
        for intake in group.intakes {
            modelContext.delete(intake)
        }
        dismiss()
    }
}

private struct IntakeRow: View {
    let intake: SupplementIntake

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: intake.supplement?.category.symbol ?? "pills")
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(intake.supplement?.name ?? "Unknown")
                Text("\(intake.amount.clean) \(intake.unit)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
