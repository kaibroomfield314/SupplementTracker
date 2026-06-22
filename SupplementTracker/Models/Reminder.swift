import Foundation
import SwiftData

enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var twoLetter: String {
        switch self {
        case .sunday:    "Su"
        case .monday:    "Mo"
        case .tuesday:   "Tu"
        case .wednesday: "We"
        case .thursday:  "Th"
        case .friday:    "Fr"
        case .saturday:  "Sa"
        }
    }
}

@Model
final class StackReminder {
    @Attribute(.unique) var reminderId: UUID = UUID()
    var weekdayNumbers: [Int] = [2, 3, 4, 5, 6]
    var hour: Int = 8
    var minute: Int = 0
    var isEnabled: Bool = true

    var stack: SupplementStack?

    init(
        stack: SupplementStack,
        weekdays: Set<Weekday> = Set(Weekday.allCases),
        hour: Int = 8,
        minute: Int = 0
    ) {
        self.stack = stack
        self.weekdayNumbers = weekdays.map(\.rawValue).sorted()
        self.hour = hour
        self.minute = minute
    }

    var weekdays: Set<Weekday> {
        get { Set(weekdayNumbers.compactMap(Weekday.init)) }
        set { weekdayNumbers = newValue.map(\.rawValue).sorted() }
    }
}
