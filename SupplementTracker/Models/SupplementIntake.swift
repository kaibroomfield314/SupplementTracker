import Foundation
import SwiftData

@Model
final class SupplementIntake {
    var date: Date = Date()
    var amount: Double = 0
    var unit: String = "mg"
    var notes: String = ""
    var multivitaminServings: Int = 1

    var supplement: Supplement?
    var sourceMultivitamin: Multivitamin?

    init(
        date: Date = Date(),
        amount: Double = 0,
        unit: String = "mg",
        notes: String = "",
        supplement: Supplement? = nil,
        sourceMultivitamin: Multivitamin? = nil,
        multivitaminServings: Int = 1
    ) {
        self.date = date
        self.amount = amount
        self.unit = unit
        self.notes = notes
        self.supplement = supplement
        self.sourceMultivitamin = sourceMultivitamin
        self.multivitaminServings = multivitaminServings
    }
}
