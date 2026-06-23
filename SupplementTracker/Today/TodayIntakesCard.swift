import SwiftUI
import SwiftData

struct TodayIntakesCard: View {
    let intakes: [SupplementIntake]
    let onDelete: (SupplementIntake) -> Void
    let onAdd: () -> Void
    let onDeleteAll: () -> Void

    @State private var confirmingDeleteAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(text: "Log", trailing: "\(intakes.count)")
                if !intakes.isEmpty {
                    Menu {
                        Button {
                            onAdd()
                        } label: {
                            Label("Log intake", systemImage: "plus")
                        }
                        Divider()
                        Button(role: .destructive) {
                            confirmingDeleteAll = true
                        } label: {
                            Label("Clear today (\(intakes.count))", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(6)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if intakes.isEmpty {
                EmptyIntakeRow(onAdd: onAdd)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(intakes.enumerated()), id: \.element.id) { idx, intake in
                        IntakeRowItem(intake: intake, onDelete: { onDelete(intake) })
                        if idx < intakes.count - 1 {
                            Divider().overlay(DS.divider).padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .cardSurface()
        .confirmationDialog(
            "Delete all \(intakes.count) intakes from today?",
            isPresented: $confirmingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Delete all", role: .destructive) {
                Haptics.warning()
                onDeleteAll()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct EmptyIntakeRow: View {
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("LOG FIRST INTAKE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.4)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct IntakeRowItem: View {
    let intake: SupplementIntake
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: intake.supplement?.category.symbol ?? "pills")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(intake.supplement?.name ?? "Unknown")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(intake.date.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(intake.amount.clean) \(intake.unit)")
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                Haptics.warning()
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
