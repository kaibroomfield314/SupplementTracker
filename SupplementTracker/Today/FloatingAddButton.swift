import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap(.medium)
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor)
                        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log intake")
    }
}
