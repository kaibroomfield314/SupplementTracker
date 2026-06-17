import Foundation
import SwiftData

@Model
final class BloodMarkerReading {
    var name: String = ""
    var value: Double = 0
    var unit: String = ""
    var referenceLow: Double = 0
    var referenceHigh: Double = 0
    var date: Date = Date()

    var test: BloodTest?

    init(
        name: String = "",
        value: Double = 0,
        unit: String = "",
        referenceLow: Double = 0,
        referenceHigh: Double = 0,
        date: Date = Date(),
        test: BloodTest? = nil
    ) {
        self.name = name
        self.value = value
        self.unit = unit
        self.referenceLow = referenceLow
        self.referenceHigh = referenceHigh
        self.date = date
        self.test = test
    }

    enum Status { case low, normal, high, unknown }

    var status: Status {
        guard referenceHigh > referenceLow else { return .unknown }
        if value < referenceLow { return .low }
        if value > referenceHigh { return .high }
        return .normal
    }
}

enum CommonBloodMarker: String, CaseIterable, Identifiable {
    case vitaminD = "Vitamin D (25-OH)"
    case vitaminB12 = "Vitamin B12"
    case ferritin = "Ferritin"
    case iron = "Iron"
    case magnesium = "Magnesium"
    case zinc = "Zinc"
    case testosteroneTotal = "Testosterone (Total)"
    case testosteroneFree = "Testosterone (Free)"
    case shbg = "SHBG"
    case estradiol = "Estradiol"
    case cortisol = "Cortisol"
    case tsh = "TSH"
    case t3 = "Free T3"
    case t4 = "Free T4"
    case hba1c = "HbA1c"
    case fastingGlucose = "Fasting Glucose"
    case ldl = "LDL Cholesterol"
    case hdl = "HDL Cholesterol"
    case triglycerides = "Triglycerides"
    case crp = "CRP (hs-CRP)"
    case creatinine = "Creatinine"
    case alt = "ALT"
    case ast = "AST"

    var id: String { rawValue }

    var defaultUnit: String {
        switch self {
        case .vitaminD: "ng/mL"
        case .vitaminB12: "pg/mL"
        case .ferritin: "ng/mL"
        case .iron: "µg/dL"
        case .magnesium: "mg/dL"
        case .zinc: "µg/dL"
        case .testosteroneTotal, .testosteroneFree, .estradiol, .cortisol: "ng/dL"
        case .shbg: "nmol/L"
        case .tsh: "mIU/L"
        case .t3, .t4: "pg/mL"
        case .hba1c: "%"
        case .fastingGlucose, .ldl, .hdl, .triglycerides, .creatinine: "mg/dL"
        case .crp: "mg/L"
        case .alt, .ast: "U/L"
        }
    }

    var defaultRange: (low: Double, high: Double) {
        switch self {
        case .vitaminD: (30, 100)
        case .vitaminB12: (200, 900)
        case .ferritin: (30, 400)
        case .iron: (60, 170)
        case .magnesium: (1.7, 2.2)
        case .zinc: (70, 120)
        case .testosteroneTotal: (300, 1000)
        case .testosteroneFree: (8.7, 25.1)
        case .shbg: (10, 57)
        case .estradiol: (10, 40)
        case .cortisol: (6, 23)
        case .tsh: (0.4, 4.0)
        case .t3: (2.3, 4.2)
        case .t4: (0.8, 1.8)
        case .hba1c: (4.0, 5.6)
        case .fastingGlucose: (70, 99)
        case .ldl: (0, 100)
        case .hdl: (40, 100)
        case .triglycerides: (0, 150)
        case .crp: (0, 1.0)
        case .creatinine: (0.7, 1.3)
        case .alt: (7, 56)
        case .ast: (10, 40)
        }
    }
}
