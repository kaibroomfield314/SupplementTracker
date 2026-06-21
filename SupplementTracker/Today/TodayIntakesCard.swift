import SwiftUI
import SwiftData

struct TodayIntakesCard: View {
    let intakes: [SupplementIntake]
    let onDelete: (SupplementIntake) -> Void
    let onAdd: () -> Void
    let onDeleteAll: () -> Void

    @State private var confirmingDeleteAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's log")
                    .font(.subheadline.bold())
                Spacer()
                if !intakes.isEmpty {
                    Menu {
                        Button {
                            onAdd()
                        } label: {
                            Label("Log intake", systemImage: "plus.circle")
                        }
                        Divider()
                        Button(role: .destructive) {
                            confirmingDeleteAll = true
                        } label: {
                            Label("Delete all today (\(intakes.count))", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                    .foregroundStyle(.tint)
                } else {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                }
            }

            if intakes.isEmpty {
                EmptyIntakeRow(onAdd: onAdd)
            } else {
                VStack(spacing: 8) {
                    ForEach(intakes) { intake in
                        IntakeRowItem(intake: intake, onDelete: { onDelete(intake) })
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
    }
}

private struct EmptyIntakeRow: View {
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack {
                Image(systemName: "plus.circle.dashed")
                    .font(.title3)
                Text("Tap to log your first intake today")
                    .font(.subheadline)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

private struct IntakeRowItem: View {
    let intake: SupplementIntake
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: intake.supplement?.category.symbol ?? "pills")
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(intake.supplement?.name ?? "Unknown")
                    .font(.subheadline)
                Text("\(intake.amount.clean) \(intake.unit) · \(intake.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
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
