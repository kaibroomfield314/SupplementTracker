import SwiftUI

/// A near-invisible single-hue tint strip at the very top of the screen,
/// just enough to nod to time of day without screaming "wellness app".
struct GradientBackdrop: View {
    private let hour: Int

    init(date: Date = .now) {
        self.hour = Calendar.current.component(.hour, from: date)
    }

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [tint.opacity(0.22), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 180)
            .frame(maxWidth: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }

    private var tint: Color {
        switch hour {
        case 5..<8:   return .orange
        case 8..<12:  return .yellow
        case 12..<16: return .cyan
        case 16..<19: return .red
        case 19..<22: return .indigo
        default:      return .purple
        }
    }
}
