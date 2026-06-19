import Foundation
import SwiftData

enum LogEntry: Identifiable {
    case multivitamin(MultivitaminLogGroup)
    case individual(SupplementIntake)

    var id: String {
        switch self {
        case .multivitamin(let g): "multi-\(g.id)"
        case .individual(let i): "intake-\(i.persistentModelID.hashValue)"
        }
    }

    var date: Date {
        switch self {
        case .multivitamin(let g): g.date
        case .individual(let i): i.date
        }
    }
}

struct MultivitaminLogGroup: Identifiable, Hashable {
    let id = UUID()
    let multivitamin: Multivitamin
    let date: Date
    let servings: Int
    let intakes: [SupplementIntake]

    var ingredientCount: Int { intakes.count }

    static func == (lhs: MultivitaminLogGroup, rhs: MultivitaminLogGroup) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct LogDaySection: Identifiable {
    let id: Date
    let title: String
    let entries: [LogEntry]
}

enum LogGrouping {
    /// Build day-sectioned log entries, with multivitamin intakes grouped by (multi, exact date).
    static func sections(from intakes: [SupplementIntake], now: Date = .now) -> [LogDaySection] {
        let cal = Calendar.current

        var entries: [LogEntry] = []
        var groupedKeys = Set<ObjectIdentifier>()

        // First pass: collect multivitamin batches (same multi + same instant)
        var batchMap: [BatchKey: [SupplementIntake]] = [:]
        for intake in intakes {
            if let multi = intake.sourceMultivitamin {
                let key = BatchKey(multiID: ObjectIdentifier(multi), date: intake.date)
                batchMap[key, default: []].append(intake)
            }
        }
        for (key, batch) in batchMap {
            guard let any = batch.first, let multi = any.sourceMultivitamin else { continue }
            let group = MultivitaminLogGroup(
                multivitamin: multi,
                date: key.date,
                servings: any.multivitaminServings,
                intakes: batch
            )
            entries.append(.multivitamin(group))
            for intake in batch {
                groupedKeys.insert(ObjectIdentifier(intake))
            }
        }

        // Second pass: standalone intakes
        for intake in intakes where !groupedKeys.contains(ObjectIdentifier(intake)) {
            entries.append(.individual(intake))
        }

        entries.sort { $0.date > $1.date }

        // Section by day
        var sections: [Date: [LogEntry]] = [:]
        for entry in entries {
            let dayStart = cal.startOfDay(for: entry.date)
            sections[dayStart, default: []].append(entry)
        }

        let today = cal.startOfDay(for: now)
        return sections.keys.sorted(by: >).map { day in
            LogDaySection(id: day, title: title(for: day, today: today), entries: sections[day] ?? [])
        }
    }

    private static func title(for day: Date, today: Date) -> String {
        let cal = Calendar.current
        if cal.isDate(day, inSameDayAs: today) { return "Today" }
        if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
           cal.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        let diff = cal.dateComponents([.day], from: day, to: today).day ?? 0
        if diff < 7 {
            return day.formatted(.dateTime.weekday(.wide))
        }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private struct BatchKey: Hashable {
        let multiID: ObjectIdentifier
        let date: Date
    }
}
