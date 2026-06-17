import SwiftUI
import SwiftData

struct BloodTestDetailView: View {
    @Bindable var test: BloodTest
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddReading = false

    private var sortedReadings: [BloodMarkerReading] {
        (test.readings ?? []).sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: test.date.formatted(date: .long, time: .omitted))
                if !test.lab.isEmpty {
                    LabeledContent("Lab", value: test.lab)
                }
            }

            if !test.notes.isEmpty {
                Section("Notes") { Text(test.notes) }
            }

            Section("Readings") {
                if sortedReadings.isEmpty {
                    Text("No readings yet").foregroundStyle(.secondary)
                } else {
                    ForEach(sortedReadings) { reading in
                        ReadingRow(reading: reading)
                    }
                    .onDelete(perform: deleteReadings)
                }

                Button {
                    showingAddReading = true
                } label: {
                    Label("Add Reading", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(test.date.formatted(date: .abbreviated, time: .omitted))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingAddReading) {
            AddReadingSheet(test: test)
        }
    }

    private func deleteReadings(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedReadings[index])
        }
    }
}

struct ReadingRow: View {
    let reading: BloodMarkerReading

    private var statusColor: Color {
        switch reading.status {
        case .low: .blue
        case .normal: .green
        case .high: .red
        case .unknown: .gray
        }
    }

    private var statusLabel: String {
        switch reading.status {
        case .low: "Low"
        case .normal: "In range"
        case .high: "High"
        case .unknown: "—"
        }
    }

    var body: some View {
        HStack {
            Circle().fill(statusColor).frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                Text(reading.name).font(.body)
                Text("Ref: \(reading.referenceLow.clean)–\(reading.referenceHigh.clean) \(reading.unit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(reading.value.clean) \(reading.unit)").font(.body.monospacedDigit())
                Text(statusLabel).font(.caption).foregroundStyle(statusColor)
            }
        }
    }
}
