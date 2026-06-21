import SwiftUI

struct TripleRingCard: View {
    let vitaminsTaken: Int
    let vitaminsTarget: Int
    let mineralsTaken: Int
    let mineralsTarget: Int
    let otherTaken: Int
    let otherTarget: Int

    var body: some View {
        HStack(spacing: 18) {
            ringStack
                .frame(width: 120, height: 120)
            VStack(alignment: .leading, spacing: 8) {
                ringLegend(color: .green, label: "Vitamins", taken: vitaminsTaken, target: vitaminsTarget)
                ringLegend(color: .blue, label: "Minerals", taken: mineralsTaken, target: mineralsTarget)
                ringLegend(color: .orange, label: "Other", taken: otherTaken, target: otherTarget)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var ringStack: some View {
        ZStack {
            ring(progress: progress(vitaminsTaken, vitaminsTarget),
                 gradient: [.green, .mint],
                 inset: 0)
            ring(progress: progress(mineralsTaken, mineralsTarget),
                 gradient: [.blue, .cyan],
                 inset: 16)
            ring(progress: progress(otherTaken, otherTarget),
                 gradient: [.orange, .red],
                 inset: 32)
        }
    }

    private func ring(progress: Double, gradient: [Color], inset: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1.0)))
                .stroke(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
        .padding(inset)
    }

    private func ringLegend(color: Color, label: String, taken: Int, target: Int) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.subheadline)
            Spacer(minLength: 4)
            Text("\(taken) / \(max(1, target))")
                .font(.subheadline.monospacedDigit().weight(.medium))
                .contentTransition(.numericText())
        }
    }

    private func progress(_ taken: Int, _ target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(taken) / Double(target))
    }
}
