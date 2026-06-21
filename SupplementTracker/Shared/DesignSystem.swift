import SwiftUI

enum DS {
    // Radius
    static let cardRadius: CGFloat = 12
    static let chipRadius: CGFloat = 8

    // Spacing
    static let cardPadding: CGFloat = 14
    static let cardSpacing: CGFloat = 10
    static let inlineGap: CGFloat = 8

    // Stroke widths
    static let ringStroke: CGFloat = 8

    // Animations
    static let snap = Animation.easeOut(duration: 0.22)
    static let pop = Animation.easeOut(duration: 0.18)

    // Colors
    static var trackColor: Color { .secondary.opacity(0.12) }
    static var divider: Color { .secondary.opacity(0.18) }
    static var cardBG: Color { Color(uiColor: .secondarySystemBackground) }
    static var chipBG: Color { Color(uiColor: .tertiarySystemBackground) }
}

extension View {
    func cardSurface() -> some View {
        self
            .padding(DS.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.cardBG)
            )
    }
}

struct SectionLabel: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .default))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct BigStat: View {
    let value: String
    var unit: String? = nil
    var size: CGFloat = 36

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(size: size, weight: .semibold, design: .default).monospacedDigit())
                .contentTransition(.numericText())
            if let unit {
                Text(unit)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
