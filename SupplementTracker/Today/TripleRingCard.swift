import SwiftUI

struct TripleRingCard: View {
    let vitaminsTaken: Int
    let vitaminsTarget: Int
    let mineralsTaken: Int
    let mineralsTarget: Int
    let otherTaken: Int
    let otherTarget: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Breakdown")
            HStack(spacing: 18) {
                ringStack
                    .frame(width: 92, height: 92)
                VStack(spacing: 8) {
                    row(label: "Vitamins", taken: vitaminsTaken, target: vitaminsTarget, accent: .accentColor)
                    row(label: "Minerals", taken: mineralsTaken, target: mineralsTarget, accent: .primary.opacity(0.45))
                    row(label: "Other",    taken: otherTaken,    target: otherTarget,    accent: .primary.opacity(0.25))
                }
                Spacer()
            }
        }
        .cardSurface()
    }

    private var ringStack: some View {
        ZStack {
            ring(progress: progress(vitaminsTaken, vitaminsTarget),
                 color: .accentColor,
                 inset: 0)
            ring(progress: progress(mineralsTaken, mineralsTarget),
                 color: .primary.opacity(0.45),
                 inset: 14)
            ring(progress: progress(otherTaken, otherTarget),
                 color: .primary.opacity(0.25),
                 inset: 28)
        }
    }

    private func ring(progress: Double, color: Color, inset: CGFloat) -> some View {
        ZStack {
            Circle().stroke(DS.trackColor, lineWidth: DS.ringStroke)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: DS.ringStroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(DS.snap, value: progress)
        }
        .padding(inset)
    }

    private func row(label: String, taken: Int, target: Int, accent: Color) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 8, height: 8)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text("\(taken)/\(max(1, target))")
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .contentTransition(.numericText())
        }
    }

    private func progress(_ taken: Int, _ target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(taken) / Double(target))
    }
}
