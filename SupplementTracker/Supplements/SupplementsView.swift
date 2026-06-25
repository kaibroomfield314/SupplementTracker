import SwiftUI
import SwiftData

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Supplement> { $0.isIngredient == false }, sort: \Supplement.name) private var supplements: [Supplement]
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
        List {
            MultivitaminsNavLink()
            StacksNavLink()
            if supplements.isEmpty {
                Section {
                    SupplementsEmptyState { showingAdd = true }
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(grouped) { group in
                    CategorySection(group: group, deleteAction: handleDelete)
                }
            }
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
        EmptyStateIllustration(
            imageName: "NoSupplementsEmptyState",
            headline: "No supplements yet",
            actionLabel: "Add your first supplement",
            onAction: onAdd
        )
    }
}

private struct MultivitaminsNavLink: View {
    var body: some View {
        Section {
            NavigationLink {
                MultivitaminsView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundStyle(.tint)
                        .frame(width: 28)
                    VStack(alignment: .leading) {
                        Text("Multivitamins")
                        Text("Log every ingredient in one tap")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct StacksNavLink: View {
    var body: some View {
        Section {
            NavigationLink {
                StacksView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundStyle(.tint)
                        .frame(width: 28)
                    VStack(alignment: .leading) {
                        Text("Stacks")
                        Text("Bundle daily supplements into routines")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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
