import SwiftUI

/// Chiaroscuro vignette: near-black at the top edge fading to clear.
/// Achromatic — no chromatic cast, no time-of-day tinting.
struct GradientBackdrop: View {
    var body: some View {
        RadialGradient(
            stops: [
                .init(color: Color.black.opacity(0.16), location: 0),
                .init(color: Color(red: 0.06, green: 0.06, blue: 0.07).opacity(0.06), location: 0.6),
                .init(color: .clear, location: 1),
            ],
            center: UnitPoint(x: 0.5, y: 0),
            startRadius: 0,
            endRadius: 320
        )
        .frame(height: 260)
        .frame(maxWidth: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}
