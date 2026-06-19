import Foundation
import SwiftData

@Model
final class Multivitamin {
    var name: String = ""
    var brand: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \MultivitaminIngredient.multivitamin)
    var ingredients: [MultivitaminIngredient]? = []

    init(
        name: String = "",
        brand: String = "",
        notes: String = ""
    ) {
        self.name = name
        self.brand = brand
        self.notes = notes
        self.createdAt = Date()
    }

    var ingredientCount: Int {
        (ingredients ?? []).count
    }
}
