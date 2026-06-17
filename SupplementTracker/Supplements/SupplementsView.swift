import SwiftUI
import SwiftData

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Supplement.name) private var supplements: [Supplement]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Supplements")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingAdd = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    AddSupplementSheet()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if supplements.isEmpty {
            SupplementsEmptyState { showingAdd = true }
        } else {
            SupplementsList(groups: grouped, deleteAction: handleDelete)
        }
    }

    private var grouped: [CategoryGroup] {
        let dict = Dictionary(grouping: supplements, by: { $0.category })
        return SupplementCategory.allCases.compactMap { cat in
            guard let items = dict[cat], !items.isEmpty else { return nil }
            return CategoryGroup(category: cat, items: items)
        }
    }

    private func handleDelete(items: [Supplement], offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}

private struct CategoryGroup: Identifiable {
    let category: SupplementCategory
    let items: [Supplement]
    var id: SupplementCategory { category }
}

private struct SupplementsEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No supplements yet", systemImage: "pills")
        } description: {
            Text("Add the vitamins, minerals, and supplements you take.")
        } actions: {
            Button("Add Supplement", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct SupplementsList: View {
    let groups: [CategoryGroup]
    let deleteAction: ([Supplement], IndexSet) -> Void

    var body: some View {
        List {
            ForEach(groups) { group in
                CategorySection(group: group, deleteAction: deleteAction)
            }
        }
    }
}

private struct CategorySection: View {
    let group: CategoryGroup
    let deleteAction: ([Supplement], IndexSet) -> Void

    var body: some View {
        Section {
            ForEach(group.items) { sup in
                SupplementRowLink(supplement: sup)
            }
            .onDelete { offsets in
                deleteAction(group.items, offsets)
            }
        } header: {
            Text(group.category.rawValue)
        }
    }
}

private struct SupplementRowLink: View {
    let supplement: Supplement

    var body: some View {
        NavigationLink {
            SupplementDetailView(supplement: supplement)
        } label: {
            SupplementRow(supplement: supplement)
        }
    }
}

struct SupplementRow: View {
    let supplement: Supplement

    var body: some View {
        HStack {
            Image(systemName: supplement.category.symbol)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading) {
                Text(supplement.name)
                HStack(spacing: 6) {
                    if !supplement.brand.isEmpty {
                        Text(supplement.brand)
                    }
                    if supplement.defaultDose > 0 {
                        Text("· \(supplement.defaultDose.clean) \(supplement.unit)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
