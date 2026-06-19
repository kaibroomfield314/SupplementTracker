import Foundation
import SwiftData

@Model
final class MultivitaminIngredient {
    var name: String = ""
    var amount: Double = 0
    var unit: String = "mg"
    var sortOrder: Int = 0

    var multivitamin: Multivitamin?

    init(
        name: String = "",
        amount: Double = 0,
        unit: String = "mg",
        sortOrder: Int = 0,
        multivitamin: Multivitamin? = nil
    ) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.sortOrder = sortOrder
        self.multivitamin = multivitamin
    }
}
