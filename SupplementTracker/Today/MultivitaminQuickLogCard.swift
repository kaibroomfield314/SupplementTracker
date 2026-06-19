import SwiftUI
import SwiftData

struct MultivitaminQuickLogCard: View {
    let multivitamins: [Multivitamin]
    let onLog: (Multivitamin, Int) -> Int

    @State private var flashID: PersistentIdentifier?
    @State private var flashCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your multivitamins")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(.tint)
                    .font(.caption)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(multivitamins) { multi in
                        MultivitaminChip(
                            multivitamin: multi,
                            flashing: flashID == multi.persistentModelID,
                            flashCount: flashCount,
                            onTap: { handleTap(multi, servings: 1) },
                            onLogServings: { servings in handleTap(multi, servings: servings) }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            Text("Long-press a multivitamin to log 2+ servings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
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
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: flashing ? "checkmark.circle.fill" : "rectangle.stack.fill")
                        .font(.title3)
                        .foregroundStyle(flashing ? Color.green : Color.accentColor)
                        .contentTransition(.symbolEffect(.replace))
                    Spacer()
                }
                Text(multivitamin.name.isEmpty ? "Multivitamin" : multivitamin.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(flashing ? "+\(flashCount) logged" : "\(multivitamin.ingredientCount) ingredients")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .frame(width: 160, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(flashing ? 1.03 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: flashing)
        .contextMenu {
            ForEach(1...5, id: \.self) { count in
                Button {
                    onLogServings(count)
                } label: {
                    Label(count == 1 ? "Log 1 serving" : "Log \(count) servings",
                          systemImage: count == 1 ? "1.circle" : "\(count).circle")
                }
            }
        }
    }
}
