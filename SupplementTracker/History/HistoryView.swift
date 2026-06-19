import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplementIntake.date, order: .reverse) private var intakes: [SupplementIntake]

    private var sections: [LogDaySection] {
        LogGrouping.sections(from: intakes)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("History")
        }
    }

    @ViewBuilder
    private var content: some View {
        if intakes.isEmpty {
            HistoryEmptyState()
        } else {
            List {
                ForEach(sections) { section in
                    LogDayBlock(
                        section: section,
                        onDeleteEntries: deleteEntries
                    )
                }
            }
        }
    }

    private func deleteEntries(in section: LogDaySection, at offsets: IndexSet) {
        for index in offsets {
            switch section.entries[index] {
            case .individual(let intake):
                modelContext.delete(intake)
            case .multivitamin(let group):
                for intake in group.intakes {
                    modelContext.delete(intake)
                }
            }
        }
    }
}

private struct HistoryEmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("No logs yet", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Once you log a supplement or multivitamin, the full history shows up here.")
        }
    }
}

private struct LogDayBlock: View {
    let section: LogDaySection
    let onDeleteEntries: (LogDaySection, IndexSet) -> Void

    var body: some View {
        Section {
            ForEach(section.entries) { entry in
                LogEntryRow(entry: entry)
            }
            .onDelete { offsets in
                onDeleteEntries(section, offsets)
            }
        } header: {
            Text(section.title)
        }
    }
}

private struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        switch entry {
        case .multivitamin(let group):
            NavigationLink {
                LogGroupDetailView(group: group)
            } label: {
                MultivitaminLogRow(group: group)
            }
        case .individual(let intake):
            IndividualLogRow(intake: intake)
        }
    }
}

private struct MultivitaminLogRow: View {
    let group: MultivitaminLogGroup

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(group.multivitamin.name.isEmpty ? "Multivitamin" : group.multivitamin.name)
                        .font(.body.weight(.medium))
                    if group.servings > 1 {
                        Text("× \(group.servings)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.tint)
                    }
                }
                Text("\(group.ingredientCount) ingredients · \(group.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct IndividualLogRow: View {
    let intake: SupplementIntake

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: intake.supplement?.category.symbol ?? "pills")
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(intake.supplement?.name ?? "Unknown")
                    .font(.body)
                Text("\(intake.amount.clean) \(intake.unit) · \(intake.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
