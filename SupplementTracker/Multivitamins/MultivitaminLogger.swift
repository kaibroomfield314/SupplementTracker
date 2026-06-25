import Foundation
import SwiftData

enum MultivitaminLogger {
    @discardableResult
    static func log(
        multivitamin multi: Multivitamin,
        servings: Int = 1,
        at date: Date = .now,
        in context: ModelContext
    ) throws -> Int {
        let ingredients = (multi.ingredients ?? []).sorted { $0.sortOrder < $1.sortOrder }
        guard !ingredients.isEmpty else { return 0 }
        let count = max(1, servings)

        let catalog = try context.fetch(FetchDescriptor<Supplement>())
        let multiLabel = multi.name.isEmpty ? "multivitamin" : multi.name
        let note = count == 1 ? "From \(multiLabel)" : "From \(multiLabel) (\(count)× serving)"

        var created = 0
        for ingredient in ingredients {
            let supplement = matchOrCreate(name: ingredient.name, unit: ingredient.unit, in: catalog, context: context)
            let intake = SupplementIntake(
                date: date,
                amount: ingredient.amount * Double(count),
                unit: ingredient.unit,
                notes: note,
                supplement: supplement,
                sourceMultivitamin: multi,
                multivitaminServings: count
            )
            context.insert(intake)
            created += 1
        }
        return created
    }

    private static func matchOrCreate(
        name rawName: String,
        unit: String,
        in catalog: [Supplement],
        context: ModelContext
    ) -> Supplement {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let needle = trimmed.lowercased()

        if let existing = catalog.first(where: { $0.name.lowercased() == needle && !$0.name.isEmpty }) {
            return existing
        }

        let category = inferredCategory(for: trimmed)
        let created = Supplement(
            name: trimmed,
            brand: "",
            category: category,
            defaultDose: 0,
            unit: unit,
            notes: "Auto-created from multivitamin ingredient"
        )
        created.isIngredient = true
        context.insert(created)
        return created
    }

    private static func inferredCategory(for name: String) -> SupplementCategory {
        let n = name.lowercased()
        let mineralKeywords = [
            "magnesium", "zinc", "iron", "calcium", "potassium", "selenium",
            "copper", "manganese", "chromium", "molybdenum", "iodine", "boron",
            "sodium", "phosphorus", "sulfur"
        ]
        if mineralKeywords.contains(where: { n.contains($0) }) {
            return .mineral
        }
        if n.contains("omega") || n.contains("fish oil") || n.contains("epa") || n.contains("dha") {
            return .omega
        }
        if n.contains("probiotic") || n.contains("lactobacillus") || n.contains("bifido") {
            return .probiotic
        }
        if n.contains("creatine") {
            return .creatine
        }
        if n.contains("protein") || n.contains("whey") || n.contains("casein") {
            return .proteinPowder
        }
        if n.contains("amino") || n.contains("bcaa") || n.contains("eaa") ||
           n.contains("leucine") || n.contains("glutamine") || n.contains("taurine") ||
           n.contains("arginine") || n.contains("citrulline") {
            return .aminoAcid
        }
        if n.contains("vitamin") || n.hasPrefix("b-") || n.hasPrefix("b ") ||
           n.contains("ascorbic") || n.contains("cholecalciferol") || n.contains("biotin") ||
           n.contains("folate") || n.contains("niacin") || n.contains("riboflavin") ||
           n.contains("thiamin") {
            return .vitamin
        }
        return .other
    }
}
