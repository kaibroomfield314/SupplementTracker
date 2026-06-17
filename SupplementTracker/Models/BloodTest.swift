import Foundation
import SwiftData

@Model
final class BloodTest {
    var date: Date = Date()
    var lab: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \BloodMarkerReading.test)
    var readings: [BloodMarkerReading]? = []

    init(date: Date = Date(), lab: String = "", notes: String = "") {
        self.date = date
        self.lab = lab
        self.notes = notes
        self.createdAt = Date()
    }
}
