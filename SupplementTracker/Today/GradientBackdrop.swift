import SwiftUI

struct GradientBackdrop: View {
    private let hour: Int

    init(date: Date = .now) {
        self.hour = Calendar.current.component(.hour, from: date)
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .opacity(0.35)
    }

    private var colors: [Color] {
        switch hour {
        case 5..<8:   return [.orange, .pink, .purple]      // sunrise
        case 8..<12:  return [.yellow, .orange, .cyan]      // morning
        case 12..<16: return [.cyan, .blue, .indigo]        // midday
        case 16..<19: return [.orange, .red, .purple]       // sunset
        case 19..<22: return [.purple, .indigo, .blue]      // evening
        default:      return [.indigo, .black, .purple]     // night
        }
    }
}
