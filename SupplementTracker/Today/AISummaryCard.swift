import SwiftUI

struct AISummaryCard: View {
    let metrics: DashboardMetrics
    let refreshID: Int

    private let service = DailySummaryService.shared

    var body: some View {
        Group {
            if let summary = service.summary {
                cardRow(summary: summary)
            }
        }
        .task { await service.load(metrics: metrics) }
        .onChange(of: refreshID) { _, newID in
            guard newID > 0 else { return }
            Task { await service.refresh(metrics: metrics) }
        }
        .animation(DS.snap, value: service.summary)
    }

    private func cardRow(summary: String) -> some View {
        HStack(spacing: DS.inlineGap) {
            Text(summary)
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            if service.isGenerating {
                ProgressView()
                    .scaleEffect(0.65)
                    .frame(width: 16, height: 16)
            } else {
                Button {
                    Task { await service.refresh(metrics: metrics) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .cardSurface(radius: DS.chipRadius)
    }
}
