import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap(.medium)
            action()
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.accentColor.gradient)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log intake")
    }
}
