import SwiftUI

struct RecentBloodCard: View {
    let markers: [MarkerSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Blood", trailing: "\(markers.count)")
            if markers.isEmpty {
                EmptyStateIllustration(
                    imageName: "NoBloodMarkersEmptyState",
                    headline: "No blood test data"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(markers.enumerated()), id: \.element.id) { idx, marker in
                        MarkerRow(marker: marker)
                        if idx < markers.count - 1 {
                            Divider()
                                .overlay(DS.divider)
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .cardSurface()
    }
}

private struct MarkerRow: View {
    let marker: MarkerSnapshot

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(statusColor)
                .frame(width: 3, height: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(marker.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(marker.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(marker.value.clean) \(marker.unit)")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                deltaView
            }
        }
    }

    @ViewBuilder
    private var deltaView: some View {
        if let pct = marker.deltaPercent {
            HStack(spacing: 2) {
                Image(systemName: deltaSymbol(for: pct))
                    .font(.system(size: 9, weight: .semibold))
                Text(deltaText(for: pct))
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
            }
            .foregroundStyle(.secondary)
        } else {
            Text("BASELINE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
        }
    }

    private func deltaSymbol(for pct: Double) -> String {
        if pct > 0.005 { return "arrow.up.right" }
        if pct < -0.005 { return "arrow.down.right" }
        return "minus"
    }

    private func deltaText(for pct: Double) -> String {
        let sign = pct > 0 ? "+" : ""
        return "\(sign)\(Int((pct * 100).rounded()))%"
    }

    private var statusColor: Color {
        switch marker.status {
        case .normal: return .accentColor
        case .low, .high: return .secondary
        case .unknown: return DS.divider
        }
    }
}
