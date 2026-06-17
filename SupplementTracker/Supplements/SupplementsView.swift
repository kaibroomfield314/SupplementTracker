import SwiftUI
import SwiftData

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Supplement.name) private var supplements: [Supplement]
    @State private var showingAdd = false

    private var grouped: [(SupplementCategory, [Supplement])] {
        let dict = Dictionary(grouping: supplements, by: { $0.category })
        return SupplementCategory.allCases.compactMap { cat in
            guard let items = dict[cat], !items.isEmpty else { return nil }
            return (cat, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if supplements.isEmpty {
                    ContentUnavailableView {
                        Label("No supplements yet", systemImage: "pills")
                    } description: {
                        Text("Add the vitamins, minerals, and supplements you take.")
                    } actions: {
                        Button("Add Supplement") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(grouped, id: \.0) { cat, items in
                            Section(cat.rawValue) {
                                ForEach(items) { sup in
                                    NavigationLink {
                                        SupplementDetailView(supplement: sup)
                                    } label: {
                                        SupplementRow(supplement: sup)
                                    }
                                }
                                .onDelete { offsets in
                                    delete(from: items, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
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

    private func delete(from items: [Supplement], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
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
