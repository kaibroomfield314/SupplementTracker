import SwiftUI
import SwiftData

struct MultivitaminQuickLogCard: View {
    let multivitamins: [Multivitamin]
    let onLog: (Multivitamin, Int) -> Int

    @State private var flashID: PersistentIdentifier?
    @State private var flashCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Multis", trailing: "long-press for ×N")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(multivitamins) { multi in
                        MultivitaminChip(
                            multivitamin: multi,
                            flashing: flashID == multi.persistentModelID,
                            flashCount: flashCount,
                            onTap: { handleTap(multi, servings: 1) },
                            onLogServings: { handleTap(multi, servings: $0) }
                        )
                    }
                }
            }
        }
        .cardSurface()
    }

    private func handleTap(_ multi: Multivitamin, servings: Int) {
        let n = onLog(multi, servings)
        flashCount = n
        flashID = multi.persistentModelID
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if flashID == multi.persistentModelID {
                flashID = nil
            }
        }
    }
}

private struct MultivitaminChip: View {
    let multivitamin: Multivitamin
    let flashing: Bool
    let flashCount: Int
    let onTap: () -> Void
    let onLogServings: (Int) -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: flashing ? "checkmark" : "rectangle.stack")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(flashing ? Color.accentColor : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                    Spacer()
                    if flashing {
                        Text("+\(flashCount)")
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Color.accentColor)
                            .contentTransition(.numericText())
                    }
                }
                Text(multivitamin.name.isEmpty ? "Multi" : multivitamin.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text("\(multivitamin.ingredientCount) items")
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 140, alignment: .leading)
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
        .contextMenu {
            ForEach(1...5, id: \.self) { n in
                Button("Log ×\(n)") { onLogServings(n) }
            }
        }
    }
}
