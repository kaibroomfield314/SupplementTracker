import SwiftUI

struct RecentBloodCard: View {
    let markers: [MarkerSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent blood markers")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "drop.fill")
                    .foregroundStyle(.tint)
                    .font(.caption)
            }
            if markers.isEmpty {
                Text("Log a blood test to see trends here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(markers) { marker in
                        MarkerRow(marker: marker)
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
    }
}

private struct MarkerRow: View {
    let marker: MarkerSnapshot

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(marker.name)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(marker.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(marker.value.clean) \(marker.unit)")
                    .font(.subheadline.monospacedDigit())
                deltaView
            }
        }
    }

    @ViewBuilder
    private var deltaView: some View {
        if let pct = marker.deltaPercent {
            HStack(spacing: 2) {
                Image(systemName: deltaSymbol(for: pct))
                    .font(.caption2)
                Text(deltaText(for: pct))
                    .font(.caption2.monospacedDigit())
            }
            .foregroundStyle(deltaColor(for: pct))
        } else {
            Text("first reading")
                .font(.caption2)
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
        let n = Int((pct * 100).rounded())
        return "\(sign)\(n)%"
    }

    private func deltaColor(for pct: Double) -> Color {
        guard abs(pct) > 0.005 else { return .secondary }
        switch marker.status {
        case .normal: return .green
        case .low: return .blue
        case .high: return .red
        case .unknown: return .secondary
        }
    }

    private var statusColor: Color {
        switch marker.status {
        case .low: return .blue
        case .normal: return .green
        case .high: return .red
        case .unknown: return .gray
        }
    }
}
