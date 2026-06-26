import Combine
import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    @Published private(set) var isAuthorized = false
    @Published private(set) var averageHeartRate: Double?
    @Published private(set) var sleepHours: Double?
    @Published private(set) var stepsToday: Double?
    @Published var lastError: String?

    private let store = HKHealthStore()

    private init() {}

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastError = "O HealthKit não está disponível neste aparelho."
            return
        }

        let readTypes: Set<HKObjectType> = Set([
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.workoutType()
        ].compactMap { $0 })

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            lastError = nil
            await refreshDashboardMetrics()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshDashboardMetrics() async {
        async let heart = latestAverageHeartRate()
        async let sleep = lastNightSleepHours()
        async let steps = todaySteps()
        averageHeartRate = await heart
        sleepHours = await sleep
        stepsToday = await steps
    }

    func verifyMilestoneWorkout() async -> Bool {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date.distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let workouts = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 20,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }

        for workout in workouts where workout.duration >= 30 * 60 {
            if let peak = await maximumHeartRate(from: workout.startDate, to: workout.endDate), peak >= 120 {
                return true
            }
        }
        return false
    }

    private func latestAverageHeartRate() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date.distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                let value = result?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func maximumHeartRate(from start: Date, to end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteMax) { _, result, _ in
                let value = result?.maximumQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func todaySteps() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: .count()))
            }
            store.execute(query)
        }
    }

    private func lastNightSleepHours() async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let start = Calendar.current.date(byAdding: .hour, value: -36, to: Date()) ?? Date.distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let sleepSamples = (samples as? [HKCategorySample]) ?? []
                let total = sleepSamples.reduce(0.0) { result, sample in
                    if sample.value == HKCategoryValueSleepAnalysis.awake.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                        return result
                    }
                    return result + sample.endDate.timeIntervalSince(sample.startDate)
                }
                continuation.resume(returning: total > 0 ? total / 3600 : nil)
            }
            store.execute(query)
        }
    }
}
