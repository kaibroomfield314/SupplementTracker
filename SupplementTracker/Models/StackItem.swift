import Foundation
import SwiftData

@Model
final class StackItem {
    var amount: Double = 0
    var unit: String = "mg"
    var sortOrder: Int = 0

    var supplement: Supplement?
    var stack: SupplementStack?

    init(
        amount: Double = 0,
        unit: String = "mg",
        sortOrder: Int = 0,
        supplement: Supplement? = nil,
        stack: SupplementStack? = nil
    ) {
        self.amount = amount
        self.unit = unit
        self.sortOrder = sortOrder
        self.supplement = supplement
        self.stack = stack
    }
}
