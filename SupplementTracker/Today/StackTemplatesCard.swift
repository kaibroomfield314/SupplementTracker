import SwiftUI
import SwiftData

struct StackTemplatesCard: View {
    let stacks: [SupplementStack]
    let onLog: (SupplementStack) -> Int

    @State private var flashID: PersistentIdentifier?
    @State private var flashCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Stacks", trailing: "\(stacks.count)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stacks) { stack in
                        StackChip(
                            stack: stack,
                            flashing: flashID == stack.persistentModelID,
                            flashCount: flashCount,
                            onTap: { handleTap(stack) }
                        )
                    }
                }
            }
        }
        .cardSurface()
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stack.emoji.isEmpty ? "▮" : stack.emoji)
                        .font(.system(size: 14))
                    Spacer()
                    if flashing {
                        Text("+\(flashCount)")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text(stack.name.isEmpty ? "Stack" : stack.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text("\(stack.itemCount) items")
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 130, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: DS.chipRadius, style: .continuous)
                    .fill(DS.chipBG)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.chipRadius, style: .continuous)
                    .strokeBorder(flashing ? Color.accentColor : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(DS.pop, value: flashing)
    }
}
