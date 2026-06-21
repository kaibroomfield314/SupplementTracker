import SwiftUI
import SwiftData

struct StackTemplatesCard: View {
    let stacks: [SupplementStack]
    let onLog: (SupplementStack) -> Int

    @State private var flashID: PersistentIdentifier?
    @State private var flashCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your stacks")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(.tint)
                    .font(.caption)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(stacks) { stack in
                        StackChip(
                            stack: stack,
                            flashing: flashID == stack.persistentModelID,
                            flashCount: flashCount,
                            onTap: { handleTap(stack) }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func handleTap(_ stack: SupplementStack) {
        let n = onLog(stack)
        flashCount = n
        flashID = stack.persistentModelID
        if n > 0 { Haptics.success() } else { Haptics.warning() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if flashID == stack.persistentModelID {
                flashID = nil
            }
        }
    }
}

private struct StackChip: View {
    let stack: SupplementStack
    let flashing: Bool
    let flashCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(stack.emoji.isEmpty ? "💊" : stack.emoji)
                    .font(.title2)
                Text(stack.name.isEmpty ? "Stack" : stack.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(flashing ? "+\(flashCount) logged" : "\(stack.itemCount) supplements")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .frame(width: 150, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(flashing ? 1.04 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: flashing)
    }
}
