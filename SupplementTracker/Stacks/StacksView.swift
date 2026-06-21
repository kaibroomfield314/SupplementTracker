import SwiftUI
import SwiftData

struct StacksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplementStack.name) private var stacks: [SupplementStack]
    @State private var showingAdd = false

    var body: some View {
        content
            .navigationTitle("Stacks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddStackSheet()
            }
    }

    @ViewBuilder
    private var content: some View {
        if stacks.isEmpty {
            StacksEmptyState { showingAdd = true }
        } else {
            List {
                ForEach(stacks) { stack in
                    NavigationLink {
                        StackDetailView(stack: stack)
                    } label: {
                        StackRow(stack: stack)
                    }
                }
                .onDelete(perform: delete)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(stacks[index])
        }
    }
}

private struct StacksEmptyState: View {
    let onAdd: () -> Void
    var body: some View {
        ContentUnavailableView {
            Label("No stacks yet", systemImage: "square.stack.3d.up")
        } description: {
            Text("Group supplements you take together (morning stack, pre-workout) and log them with one tap.")
        } actions: {
            Button("New Stack", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct StackRow: View {
    let stack: SupplementStack
    var body: some View {
        HStack(spacing: 12) {
            Text(stack.emoji.isEmpty ? "💊" : stack.emoji)
                .font(.title2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(stack.name.isEmpty ? "Untitled stack" : stack.name)
                Text("\(stack.itemCount) supplement\(stack.itemCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
