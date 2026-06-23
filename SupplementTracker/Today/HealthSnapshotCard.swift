import SwiftUI
import HealthKit

struct HealthSnapshotCard: View {
    private let service = HealthService.shared
    @AppStorage(UserPreferenceKeys.healthKitConnected) private var healthKitConnected = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.cardSpacing) {
            SectionLabel(text: "Apple Health")
            content
        }
        .cardSurface()
        .task { await service.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        if !service.isAvailable {
            Text("Health data not available on this device.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let snap = service.snapshot {
            metricsGrid(snap)
        } else if healthKitConnected {
            // Authorized but still loading or no data yet
            HStack {
                ProgressView()
                Text("Loading health data…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            connectPrompt
        }
    }

    // MARK: - Connect prompt

    private var connectPrompt: some View {
        Button {
            Task {
                await service.requestAuthorization()
                healthKitConnected = true
                await service.refresh()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Apple Health")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Weight, workouts, sleep & heart rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Metrics grid

    @ViewBuilder
    private func metricsGrid(_ snap: HealthSnapshot) -> some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
            weightCell(snap)
            rhrCell(snap)
            sleepCell(snap)
            workoutCell(snap)
        }
    }

    @ViewBuilder
    private func weightCell(_ snap: HealthSnapshot) -> some View {
        let lbs = snap.weightKg.map { $0 * 2.20462 }
        HealthMetricCell(
            icon: "scalemass.fill",
            label: "Weight",
            value: lbs.map { String(format: "%.1f", $0) } ?? "—",
            unit: lbs != nil ? "lbs" : nil,
            trend: snap.weightTrend.map { $0 * 2.20462 },
            tint: .blue
        )
    }

    @ViewBuilder
    private func rhrCell(_ snap: HealthSnapshot) -> some View {
        HealthMetricCell(
            icon: "heart.fill",
            label: "Resting HR",
            value: snap.restingHeartRate.map { "\(Int($0))" } ?? "—",
            unit: snap.restingHeartRate != nil ? "bpm" : nil,
            tint: .pink
        )
    }

    @ViewBuilder
    private func sleepCell(_ snap: HealthSnapshot) -> some View {
        HealthMetricCell(
            icon: "bed.double.fill",
            label: "Sleep",
            value: snap.sleepHours.map { formatSleep($0) } ?? "—",
            unit: nil,
            tint: .indigo
        )
    }

    @ViewBuilder
    private func workoutCell(_ snap: HealthSnapshot) -> some View {
        if let w = snap.yesterdayWorkout {
            HealthMetricCell(
                icon: "figure.run",
                label: "Workout",
                value: "\(Int(w.durationMinutes))m",
                unit: w.activityType.displayName,
                tint: .orange
            )
        } else {
            HealthMetricCell(
                icon: "figure.walk",
                label: "Workout",
                value: "Rest",
                unit: "yesterday",
                tint: .secondary
            )
        }
    }

    private func formatSleep(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

// MARK: - HealthMetricCell

private struct HealthMetricCell: View {
    let icon: String
    let label: String
    let value: String
    var unit: String? = nil
    var trend: [Double] = []
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(tint)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let unit {
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            if trend.count >= 2 {
                Sparkline(values: trend, color: tint)
                    .frame(height: 20)
            } else {
                Spacer().frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: DS.chipRadius, style: .continuous)
                .fill(DS.chipBG)
        )
    }
}

// MARK: - Sparkline

private struct Sparkline: View {
    let values: [Double]
    var color: Color = .accentColor

    var body: some View {
        Canvas { context, size in
            guard values.count >= 2, size.height > 0 else { return }
            let minV = values.min()!
            let maxV = values.max()!
            let range = maxV == minV ? 1.0 : maxV - minV
            let step = size.width / CGFloat(values.count - 1)
            var path = Path()
            for (i, val) in values.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height - CGFloat((val - minV) / range) * size.height
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else       { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(color.opacity(0.8)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}
