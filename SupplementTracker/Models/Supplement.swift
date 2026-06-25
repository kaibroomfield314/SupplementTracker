import Foundation
import SwiftData

enum SupplementCategory: String, CaseIterable, Identifiable, Codable {
    case vitamin = "Vitamin"
    case mineral = "Mineral"
    case aminoAcid = "Amino Acid"
    case proteinPowder = "Protein"
    case preWorkout = "Pre-Workout"
    case creatine = "Creatine"
    case omega = "Omega / Fats"
    case herbal = "Herbal"
    case probiotic = "Probiotic"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .vitamin: "leaf.fill"
        case .mineral: "diamond.fill"
        case .aminoAcid: "atom"
        case .proteinPowder: "fork.knife"
        case .preWorkout: "bolt.fill"
        case .creatine: "figure.strengthtraining.traditional"
        case .omega: "drop.fill"
        case .herbal: "leaf"
        case .probiotic: "circle.hexagongrid.fill"
        case .other: "pills"
        }
    }
}

@Model
final class Supplement {
    var name: String = ""
    var brand: String = ""
    var categoryRaw: String = SupplementCategory.vitamin.rawValue
    var defaultDose: Double = 0
    var unit: String = "mg"
    var notes: String = ""
    var createdAt: Date = Date()
    var isIngredient: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \SupplementIntake.supplement)
    var intakes: [SupplementIntake]? = []

    var category: SupplementCategory {
        get { SupplementCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        name: String = "",
        brand: String = "",
        category: SupplementCategory = .vitamin,
        defaultDose: Double = 0,
        unit: String = "mg",
        notes: String = ""
    ) {
        self.name = name
        self.brand = brand
        self.categoryRaw = category.rawValue
        self.defaultDose = defaultDose
        self.unit = unit
        self.notes = notes
        self.createdAt = Date()
    }
}
