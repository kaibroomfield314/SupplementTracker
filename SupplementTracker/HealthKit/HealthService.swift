import HealthKit
import Observation

// MARK: - Data models

struct HealthSnapshot {
    let weightKg: Double?
    let weightTrend: [Double]   // up to 7 values, oldest→newest
    let yesterdayWorkout: WorkoutSummary?
    let sleepHours: Double?
    let restingHeartRate: Double?
}

struct WorkoutSummary {
    let activityType: HKWorkoutActivityType
    let durationMinutes: Double
    let activeCalories: Double?
}

// MARK: - Service

@MainActor
@Observable
final class HealthService {
    static let shared = HealthService()

    private let store = HKHealthStore()

    var snapshot: HealthSnapshot?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private static let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let mass = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(mass) }
        if let rhr = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { types.insert(rhr) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        types.insert(HKWorkoutType.workoutType())
        return types
    }()

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
            return true
        } catch {
            return false
        }
    }

    func refresh() async {
        guard isAvailable else { return }
        async let weight  = fetchLatestWeight()
        async let trend   = fetchWeightTrend()
        async let workout = fetchYesterdayWorkout()
        async let sleep   = fetchLastNightSleep()
        async let rhr     = fetchRestingHeartRate()
        snapshot = HealthSnapshot(
            weightKg: await weight,
            weightTrend: await trend,
            yesterdayWorkout: await workout,
            sleepHours: await sleep,
            restingHeartRate: await rhr
        )
    }

    // MARK: - Private queries

    private func fetchLatestWeight() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .gramUnit(with: .kilo))
                cont.resume(returning: kg)
            }
            store.execute(q)
        }
    }

    private func fetchWeightTrend() async -> [Double] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return [] }
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: .now)) ?? .now
        let pred = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                let values = (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: .gramUnit(with: .kilo)) } ?? []
                cont.resume(returning: values)
            }
            store.execute(q)
        }
    }

    private func fetchYesterdayWorkout() async -> WorkoutSummary? {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: .now)
        let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
        let pred = HKQuery.predicateForSamples(withStart: yesterdayStart, end: todayStart, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: pred, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let workout = samples?.first as? HKWorkout else {
                    cont.resume(returning: nil)
                    return
                }
                let durationMin = workout.duration / 60
                let kcal = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
                cont.resume(returning: WorkoutSummary(
                    activityType: workout.workoutActivityType,
                    durationMinutes: durationMin,
                    activeCalories: kcal
                ))
            }
            store.execute(q)
        }
    }

    private func fetchLastNightSleep() async -> Double? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let cal = Calendar.current
        let now = Date()
        // Search from yesterday 6 pm to today noon to capture a typical sleep window
        let todayNoon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let searchStart = cal.date(byAdding: .hour, value: -18, to: todayNoon) ?? now
        let pred = HKQuery.predicateForSamples(withStart: searchStart, end: todayNoon, options: .strictStartDate)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let cats = samples as? [HKCategorySample] else {
                    cont.resume(returning: nil)
                    return
                }
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let totalHours = cats
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                    / 3600
                cont.resume(returning: totalHours > 0 ? totalHours : nil)
            }
            store.execute(q)
        }
    }

    private func fetchRestingHeartRate() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let bpm = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min"))
                cont.resume(returning: bpm)
            }
            store.execute(q)
        }
    }
}

// MARK: - HKWorkoutActivityType display name

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running:                      return "Run"
        case .cycling:                      return "Ride"
        case .walking:                      return "Walk"
        case .swimming:                     return "Swim"
        case .highIntensityIntervalTraining:return "HIIT"
        case .traditionalStrengthTraining:  return "Lift"
        case .functionalStrengthTraining:   return "Functional"
        case .yoga:                         return "Yoga"
        case .hiking:                       return "Hike"
        case .rowing:                       return "Row"
        case .elliptical:                   return "Elliptical"
        case .crossTraining:                return "Cross Train"
        case .pilates:                      return "Pilates"
        case .dance:                        return "Dance"
        default:                            return "Workout"
        }
    }
}
