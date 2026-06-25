import Foundation
import SwiftData

struct DashboardMetrics {
    let todayUniqueCount: Int
    let typicalCount: Int
    let topStreak: StreakInfo?
    let last7Days: [DayCount]
    let last30Days: [DayCount]
    let weekDeltaPercent: Double?
    let recentMarkers: [MarkerSnapshot]
    let todayIntakes: [SupplementIntake]
    let yesterdayIntakes: [SupplementIntake]
    let activeDaysThisMonth: Set<Date>
    let categoryBreakdown: CategoryBreakdown

    var completionProgress: Double {
        guard typicalCount > 0 else { return 0 }
        return min(1.0, Double(todayUniqueCount) / Double(typicalCount))
    }
}

struct CategoryBreakdown: Equatable {
    let vitaminsTakenToday: Int
    let vitaminsTarget: Int
    let mineralsTakenToday: Int
    let mineralsTarget: Int
    let otherTakenToday: Int
    let otherTarget: Int
}

extension DashboardMetrics {

    static func compute(
        supplements: [Supplement],
        intakes: [SupplementIntake],
        readings: [BloodMarkerReading],
        now: Date = .now
    ) -> DashboardMetrics {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)

        let todayIntakes = intakes
            .filter { cal.isDate($0.date, inSameDayAs: now) }
            .sorted { $0.date > $1.date }
        let todayUnique = Set(todayIntakes.compactMap { $0.supplement?.persistentModelID })

        let cutoff14 = cal.date(byAdding: .day, value: -14, to: today) ?? today
        var typicalIds = Set<PersistentModelIDLike>()
        for sup in supplements {
            let days = Set(
                intakes
                    .filter { $0.supplement === sup && $0.date >= cutoff14 }
                    .map { cal.startOfDay(for: $0.date) }
            )
            if days.count >= 3 {
                typicalIds.insert(sup.persistentModelID)
            }
        }
        if typicalIds.isEmpty {
            for id in todayUnique { typicalIds.insert(id) }
        }

        var bestStreak: StreakInfo?
        for sup in supplements {
            let dates = intakes
                .filter { $0.supplement === sup && $0.sourceMultivitamin == nil }
                .map { cal.startOfDay(for: $0.date) }
            let streakDays = StreakMath.currentStreak(intakeDays: dates, today: today)
            if streakDays > 0 {
                if bestStreak == nil || streakDays > bestStreak!.days {
                    bestStreak = StreakInfo(supplementName: sup.name, days: streakDays)
                }
            }
        }

        var last7: [DayCount] = []
        for offset in (0..<7).reversed() {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let next = cal.date(byAdding: .day, value: 1, to: day) ?? day
            let count = intakes.filter { $0.date >= day && $0.date < next }.count
            last7.append(DayCount(date: day, count: count))
        }

        var last30: [DayCount] = []
        for offset in (0..<30).reversed() {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let next = cal.date(byAdding: .day, value: 1, to: day) ?? day
            let count = intakes.filter { $0.date >= day && $0.date < next }.count
            last30.append(DayCount(date: day, count: count))
        }
        let thisWeekTotal = last7.reduce(0) { $0 + $1.count }
        let prevWeekStart = cal.date(byAdding: .day, value: -14, to: today) ?? today
        let prevWeekEnd = cal.date(byAdding: .day, value: -7, to: today) ?? today
        let prevWeekTotal = intakes.filter { $0.date >= prevWeekStart && $0.date < prevWeekEnd }.count
        let weekDelta: Double?
        if prevWeekTotal > 0 {
            weekDelta = (Double(thisWeekTotal) - Double(prevWeekTotal)) / Double(prevWeekTotal)
        } else {
            weekDelta = nil
        }

        let groupedByName = Dictionary(grouping: readings, by: \.name)
        var snapshots: [MarkerSnapshot] = []
        for (name, group) in groupedByName {
            let sorted = group.sorted { $0.date > $1.date }
            guard let latest = sorted.first else { continue }
            let previous = sorted.dropFirst().first
            snapshots.append(MarkerSnapshot(
                name: name,
                value: latest.value,
                unit: latest.unit,
                previousValue: previous?.value,
                status: latest.status,
                date: latest.date
            ))
        }
        snapshots.sort { $0.date > $1.date }
        let recent = Array(snapshots.prefix(4))

        // Yesterday intakes (for repeat action)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        let yesterdayEnd = today
        let yesterdayIntakes = intakes
            .filter { $0.date >= yesterday && $0.date < yesterdayEnd }
            .sorted { $0.date > $1.date }

        // Active days this month (for mini calendar)
        let monthComp = cal.dateComponents([.year, .month], from: today)
        let monthStart = cal.date(from: monthComp) ?? today
        let monthIntakes = intakes.filter { $0.date >= monthStart }
        let activeDays = Set(monthIntakes.map { cal.startOfDay(for: $0.date) })

        // Category breakdown for triple rings
        let typicalSups = supplements.filter { typicalIds.contains($0.persistentModelID) }
        func target(in cat: SupplementCategory) -> Int {
            switch cat {
            case .vitamin: typicalSups.filter { $0.category == .vitamin }.count
            case .mineral: typicalSups.filter { $0.category == .mineral }.count
            default: typicalSups.filter { !$0.category.isVitaminOrMineral }.count
            }
        }
        let todayUniqueSet = Set(todayIntakes.compactMap { $0.supplement })
        let vitaminsTaken = todayUniqueSet.filter { $0.category == .vitamin }.count
        let mineralsTaken = todayUniqueSet.filter { $0.category == .mineral }.count
        let otherTaken = todayUniqueSet.filter { !$0.category.isVitaminOrMineral }.count

        let breakdown = CategoryBreakdown(
            vitaminsTakenToday: vitaminsTaken,
            vitaminsTarget: max(target(in: .vitamin), vitaminsTaken),
            mineralsTakenToday: mineralsTaken,
            mineralsTarget: max(target(in: .mineral), mineralsTaken),
            otherTakenToday: otherTaken,
            otherTarget: max(target(in: .other), otherTaken)
        )

        return DashboardMetrics(
            todayUniqueCount: todayUnique.count,
            typicalCount: max(typicalIds.count, todayUnique.count),
            topStreak: bestStreak,
            last7Days: last7,
            last30Days: last30,
            weekDeltaPercent: weekDelta,
            recentMarkers: recent,
            todayIntakes: todayIntakes,
            yesterdayIntakes: yesterdayIntakes,
            activeDaysThisMonth: activeDays,
            categoryBreakdown: breakdown
        )
    }
}

extension SupplementCategory {
    var isVitaminOrMineral: Bool {
        self == .vitamin || self == .mineral
    }
}

struct StreakInfo: Equatable {
    let supplementName: String
    let days: Int
}

struct DayCount: Identifiable, Equatable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct MarkerSnapshot: Identifiable, Equatable {
    let name: String
    let value: Double
    let unit: String
    let previousValue: Double?
    let status: BloodMarkerReading.Status
    let date: Date
    var id: String { name }

    var deltaPercent: Double? {
        guard let previousValue, previousValue != 0 else { return nil }
        return (value - previousValue) / previousValue
    }
}

typealias PersistentModelIDLike = AnyHashable

enum StreakMath {
    static func currentStreak(intakeDays dates: [Date], today: Date) -> Int {
        let cal = Calendar.current
        let uniqueDays = Set(dates.map { cal.startOfDay(for: $0) })
        guard !uniqueDays.isEmpty else { return 0 }

        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        var checkDay: Date
        if uniqueDays.contains(today) {
            checkDay = today
        } else if uniqueDays.contains(yesterday) {
            checkDay = yesterday
        } else {
            return 0
        }

        var streak = 0
        while uniqueDays.contains(checkDay) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prev
        }
        return streak
    }
}
