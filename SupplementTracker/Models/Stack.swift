import Foundation
import SwiftData

@Model
final class SupplementStack {
    var name: String = ""
    var emoji: String = "💊"
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \StackItem.stack)
    var items: [StackItem]? = []

    init(name: String = "", emoji: String = "💊", notes: String = "") {
        self.name = name
        self.emoji = emoji
        self.notes = notes
        self.createdAt = Date()
    }

    var itemCount: Int { (items ?? []).count }
}
