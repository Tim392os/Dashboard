import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Lecture des heures de sommeil via Apple Santé (HealthKit).
/// Sur simulateur sans données, retourne nil et la carte affiche un état vide.
final class HealthKitService {
    static let shared = HealthKitService()

    #if canImport(HealthKit)
    private let store = HKHealthStore()
    #endif

    var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    func requestAuthorization() async {
        #if canImport(HealthKit)
        guard isAvailable else { return }
        let sleepType = HKCategoryType(.sleepAnalysis)
        try? await store.requestAuthorization(toShare: [], read: [sleepType])
        #endif
    }

    /// Heures dormies la nuit dernière (fenêtre 18 h la veille → 12 h aujourd'hui).
    func lastNightSleepHours() async -> Double? {
        #if canImport(HealthKit)
        guard isAvailable else { return nil }

        let calendar = DateUtils.calendar
        let todayNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        let yesterdayEvening = calendar.date(byAdding: .hour, value: -18, to: todayNoon)!

        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: yesterdayEvening,
                                                    end: todayNoon,
                                                    options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let asleepValues = Set(HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue))
                let seconds = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: seconds > 0 ? seconds / 3600 : nil)
            }
            store.execute(query)
        }
        #else
        return nil
        #endif
    }
}
