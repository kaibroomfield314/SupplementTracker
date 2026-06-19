import SwiftUI
import SwiftData
import Charts

struct MarkerTrendView: View {
    let markerName: String
    @Query private var readings: [BloodMarkerReading]

    init(markerName: String) {
        self.markerName = markerName
        let predicate = #Predicate<BloodMarkerReading> { $0.name == markerName }
        _readings = Query(filter: predicate, sort: \.date)
    }

    private var refLow: Double { readings.last?.referenceLow ?? 0 }
    private var refHigh: Double { readings.last?.referenceHigh ?? 0 }
    private var unit: String { readings.last?.unit ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if readings.count < 2 {
                    ContentUnavailableView(
                        "Need more readings",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Add at least two \(markerName) readings to see a trend.")
                    )
                    .padding(.top, 40)
                } else {
                    Chart {
                        if refHigh > refLow {
                            RectangleMark(
                                xStart: .value("Start", readings.first?.date ?? .now),
                                xEnd: .value("End", readings.last?.date ?? .now),
                                yStart: .value("Low", refLow),
                                yEnd: .value("High", refHigh)
                            )
                            .foregroundStyle(.green.opacity(0.12))
                        }
                        ForEach(readings) { r in
                            LineMark(
                                x: .value("Date", r.date),
                                y: .value("Value", r.value)
                            )
                            .foregroundStyle(.tint)
                            PointMark(
                                x: .value("Date", r.date),
                                y: .value("Value", r.value)
                            )
                            .foregroundStyle(color(for: r.status))
                        }
                    }
                    .frame(height: 260)
                    .padding(.horizontal)

                    if refHigh > refLow {
                        Text("Reference range: \(refLow.clean)–\(refHigh.clean) \(unit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("History").font(.headline).padding(.horizontal)
                    ForEach(readings.reversed()) { r in
                        HStack {
                            Text(r.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text("\(r.value.clean) \(r.unit)")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(color(for: r.status))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        Divider()
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(markerName)
        #if os(iOS)
        .toolbarTitleDisplayMode(.inline)
        #endif
    }

    private func color(for status: BloodMarkerReading.Status) -> Color {
        switch status {
        case .low: .blue
        case .normal: .green
        case .high: .red
        case .unknown: .gray
        }
    }
}
