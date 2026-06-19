import SwiftUI

enum SupplementUnit {
    /// Curated list, ordered roughly by frequency of use on real supplement labels.
    static let all: [String] = [
        "µg",
        "mg",
        "g",
        "IU",
        "mL",
        "billion CFU",
        "capsule",
        "softgel",
        "gummy",
        "tablet",
        "scoop",
        "drop",
        "serving",
    ]
}

struct UnitPicker: View {
    @Binding var unit: String

    var body: some View {
        Picker("Unit", selection: $unit) {
            ForEach(options, id: \.self) { value in
                Text(value).tag(value)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }

    private var options: [String] {
        if unit.isEmpty || SupplementUnit.all.contains(unit) {
            return SupplementUnit.all
        }
        return SupplementUnit.all + [unit]
    }
}

struct AmountUnitField: View {
    @Binding var amount: Double
    @Binding var unit: String

    var body: some View {
        HStack(spacing: 8) {
            TextField("Amount", value: $amount, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
            UnitPicker(unit: $unit)
                .tint(.accentColor)
        }
    }
}
