import SwiftUI
import SwiftData

struct BloodMarkersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BloodTest.date, order: .reverse) private var tests: [BloodTest]
    @Query private var allReadings: [BloodMarkerReading]
    @State private var showingAdd = false

    private var uniqueMarkerNames: [String] {
        Array(Set(allReadings.map(\.name))).sorted()
    }

    var body: some View {
        NavigationStack {
            Group {
                if tests.isEmpty {
                    ContentUnavailableView {
                        Label("No blood tests", systemImage: "drop")
                    } description: {
                        Text("Record your blood panel results to track trends over time.")
                    } actions: {
                        Button("Add Blood Test") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if !uniqueMarkerNames.isEmpty {
                            Section("Trends") {
                                ForEach(uniqueMarkerNames, id: \.self) { name in
                                    NavigationLink {
                                        MarkerTrendView(markerName: name)
                                    } label: {
                                        HStack {
                                            Image(systemName: "chart.line.uptrend.xyaxis")
                                                .foregroundStyle(.tint)
                                                .frame(width: 28)
                                            Text(name)
                                            Spacer()
                                            Text("\(readingsCount(for: name))")
                                                .foregroundStyle(.secondary)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }

                        Section("Tests") {
                            ForEach(tests) { test in
                                NavigationLink {
                                    BloodTestDetailView(test: test)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(test.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.body)
                                        HStack(spacing: 6) {
                                            if !test.lab.isEmpty {
                                                Text(test.lab)
                                            }
                                            Text("· \((test.readings ?? []).count) markers")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .onDelete(perform: deleteTests)
                        }
                    }
                }
            }
            .navigationTitle("Blood Markers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddBloodTestSheet()
            }
        }
    }

    private func readingsCount(for name: String) -> Int {
        allReadings.filter { $0.name == name }.count
    }

    private func deleteTests(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tests[index])
        }
    }
}
