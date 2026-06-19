import SwiftUI
import SwiftData

struct AddBloodTestSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var lab: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Test") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Lab (optional)", text: $lab)
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section {
                    Text("You'll add markers (Vitamin D, Testosterone, etc.) after saving.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Blood Test")
            #if os(iOS)
            .toolbarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let test = BloodTest(date: date, lab: lab, notes: notes)
                        modelContext.insert(test)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddReadingSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let test: BloodTest

    @State private var selectedCommon: CommonBloodMarker? = nil
    @State private var name: String = ""
    @State private var value: Double = 0
    @State private var unit: String = ""
    @State private var referenceLow: Double = 0
    @State private var referenceHigh: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Marker") {
                    Picker("Common markers", selection: $selectedCommon) {
                        Text("Custom…").tag(CommonBloodMarker?.none)
                        ForEach(CommonBloodMarker.allCases) { m in
                            Text(m.rawValue).tag(CommonBloodMarker?.some(m))
                        }
                    }
                    .onChange(of: selectedCommon) { _, new in
                        if let new {
                            name = new.rawValue
                            unit = new.defaultUnit
                            referenceLow = new.defaultRange.low
                            referenceHigh = new.defaultRange.high
                        }
                    }
                    TextField("Name", text: $name)
                }

                Section("Value") {
                    HStack {
                        TextField("Value", value: $value, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                        TextField("Unit", text: $unit)
                            .frame(maxWidth: 100)
                    }
                }

                Section("Reference range") {
                    HStack {
                        TextField("Low", value: $referenceLow, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                        Text("—")
                        TextField("High", value: $referenceHigh, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
            }
            .navigationTitle("Add Reading")
            #if os(iOS)
            .toolbarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let reading = BloodMarkerReading(
            name: name,
            value: value,
            unit: unit,
            referenceLow: referenceLow,
            referenceHigh: referenceHigh,
            date: test.date,
            test: test
        )
        modelContext.insert(reading)
        dismiss()
    }
}
