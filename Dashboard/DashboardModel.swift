import Foundation
import Observation

/// État des données externes du dashboard (entraînement, école, santé, banque).
/// Les données locales (tâches, notes, etc.) vivent directement dans SwiftData.
@Observable
@MainActor
final class DashboardModel {
    var training: TrainingSummary?
    var school: SchoolSummary?
    var bank: BankSummary?
    var sleepHours: Double?
    var isRefreshing = false
    var lastRefresh: Date?

    var trainingIsLive: Bool { ProviderRegistry.trainingIsLive }
    var schoolIsLive: Bool { ProviderRegistry.schoolIsLive }

    func refresh() async {
        isRefreshing = true
        defer {
            isRefreshing = false
            lastRefresh = .now
        }

        await HealthKitService.shared.requestAuthorization()

        async let trainingResult = try? ProviderRegistry.training.fetchSummary()
        async let schoolResult = try? ProviderRegistry.school.fetchSummary()
        async let sleepResult = HealthKitService.shared.lastNightSleepHours()

        training = await trainingResult
        school = await schoolResult
        sleepHours = await sleepResult

        if let bankProvider = ProviderRegistry.bank {
            bank = try? await bankProvider.fetchSummary()
        }
    }
}
