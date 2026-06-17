import Foundation
import SwiftData

@Model
final class SupplementIntake {
    var date: Date = Date()
    var amount: Double = 0
    var unit: String = "mg"
    var notes: String = ""

    var supplement: Supplement?

    init(
        date: Date = Date(),
        amount: Double = 0,
        unit: String = "mg",
        notes: String = "",
        supplement: Supplement? = nil
    ) {
        self.date = date
        self.amount = amount
        self.unit = unit
        self.notes = notes
        self.supplement = supplement
    }
}
