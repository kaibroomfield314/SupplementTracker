import SwiftUI
import SwiftData

struct MultivitaminsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Multivitamin.name) private var multivitamins: [Multivitamin]
    @State private var showingAdd = false

    var body: some View {
        content
            .navigationTitle("Multivitamins")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddMultivitaminSheet()
            }
    }

    @ViewBuilder
    private var content: some View {
        if multivitamins.isEmpty {
            MultivitaminsEmptyState { showingAdd = true }
        } else {
            List {
                ForEach(multivitamins) { multi in
                    MultivitaminRowLink(multivitamin: multi)
                }
                .onDelete(perform: delete)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(multivitamins[index])
        }
    }
}

private struct MultivitaminsEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No multivitamins yet", systemImage: "rectangle.stack.fill")
        } description: {
            Text("Add a multivitamin once, log every ingredient with one tap.")
        } actions: {
            Button("Add Multivitamin", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct MultivitaminRowLink: View {
    let multivitamin: Multivitamin

    var body: some View {
        NavigationLink {
            MultivitaminDetailView(multivitamin: multivitamin)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(.tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(multivitamin.name.isEmpty ? "Untitled multivitamin" : multivitamin.name)
                    HStack(spacing: 6) {
                        if !multivitamin.brand.isEmpty {
                            Text(multivitamin.brand)
                        }
                        Text("· \(multivitamin.ingredientCount) ingredients")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
