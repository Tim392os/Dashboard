import Foundation

// MARK: - Modèles

struct Race: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var date: Date

    var daysRemaining: Int { DateUtils.daysUntil(date) }
}

struct PlannedWorkout: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var date: Date
    var durationMinutes: Int
    var tss: Double?
}

struct TrainingLoad: Hashable {
    /// Charge chronique / aiguë ou résumé hebdo, selon la source.
    var last7DaysHours: Double
    var last7DaysTSS: Double
    var fitnessCTL: Double?
    var fatigueATL: Double?
}

struct TrainingSummary {
    var nextRace: Race?
    var upcomingWorkouts: [PlannedWorkout]
    var recentLoad: TrainingLoad?
    /// Heures d'entraînement cumulées cette année, par mois (1…12).
    var yearHoursByMonth: [Int: Double]

    var yearTotalHours: Double { yearHoursByMonth.values.reduce(0, +) }
}

// MARK: - Protocole

/// Source de données d'entraînement. `TrainingPeaksProvider` est l'implémentation
/// visée ; tant que l'accès API n'est pas configuré, l'app bascule sur des
/// données d'exemple sans que le reste de l'app change.
protocol TrainingDataProvider {
    var isConfigured: Bool { get }
    func fetchSummary() async throws -> TrainingSummary
}

// MARK: - TrainingPeaks

/// Intégration TrainingPeaks (API officielle, OAuth2).
///
/// L'API TrainingPeaks (api.trainingpeaks.com) est réservée aux partenaires :
/// il faut demander un client_id/secret via api.trainingpeaks.com (compte
/// développeur approuvé), puis effectuer le flux OAuth2 et stocker les jetons
/// dans le trousseau. Une fois le jeton présent, ce provider devient actif
/// automatiquement (voir `ProviderRegistry`).
struct TrainingPeaksProvider: TrainingDataProvider {
    static let baseURL = URL(string: "https://api.trainingpeaks.com/v1")!

    var isConfigured: Bool {
        Keychain.get(.trainingPeaksToken) != nil
    }

    func fetchSummary() async throws -> TrainingSummary {
        guard let token = Keychain.get(.trainingPeaksToken) else {
            throw APIClient.APIError.notConfigured
        }
        let client = APIClient(baseURL: Self.baseURL, bearerToken: token)

        // Événements (courses) et entraînements planifiés à venir.
        let today = DateUtils.startOfToday()
        let formatter = ISO8601DateFormatter()
        let in90Days = today.addingTimeInterval(90 * 86_400)
        let query = [
            URLQueryItem(name: "startDate", value: formatter.string(from: today)),
            URLQueryItem(name: "endDate", value: formatter.string(from: in90Days)),
        ]

        let events: [TPEvent] = try await client.get("athlete/events", query: query)
        let workouts: [TPWorkout] = try await client.get("workouts/planned", query: query)

        let races = events
            .filter { $0.eventType?.lowercased().contains("race") ?? true }
            .map { Race(name: $0.name, date: $0.date) }
            .sorted { $0.date < $1.date }

        let planned = workouts
            .map {
                PlannedWorkout(title: $0.title ?? "Entraînement",
                               date: $0.workoutDay,
                               durationMinutes: Int(($0.totalTimePlanned ?? 0) * 60),
                               tss: $0.tssPlanned)
            }
            .sorted { $0.date < $1.date }

        return TrainingSummary(
            nextRace: races.first,
            upcomingWorkouts: Array(planned.prefix(4)),
            recentLoad: nil, // à compléter selon les scopes accordés (metrics)
            yearHoursByMonth: [:]
        )
    }

    private struct TPEvent: Decodable {
        var name: String
        var date: Date
        var eventType: String?
    }

    private struct TPWorkout: Decodable {
        var title: String?
        var workoutDay: Date
        var totalTimePlanned: Double?
        var tssPlanned: Double?
    }
}

// MARK: - Données d'exemple (mode démo, tant que l'API n'est pas connectée)

struct SampleTrainingProvider: TrainingDataProvider {
    var isConfigured: Bool { true }

    func fetchSummary() async throws -> TrainingSummary {
        let calendar = DateUtils.calendar
        let today = DateUtils.startOfToday()

        var hours: [Int: Double] = [:]
        let currentMonth = calendar.component(.month, from: today)
        let sample: [Double] = [32, 38, 41, 45, 39, 47, 22]
        for month in 1...currentMonth {
            hours[month] = sample[(month - 1) % sample.count]
        }

        return TrainingSummary(
            nextRace: Race(name: "GP de la Wallonie Juniors",
                           date: calendar.date(byAdding: .day, value: 19, to: today)!),
            upcomingWorkouts: [
                PlannedWorkout(title: "Endurance Z2", date: calendar.date(byAdding: .day, value: 1, to: today)!, durationMinutes: 120, tss: 95),
                PlannedWorkout(title: "Intervalles 4×8'", date: calendar.date(byAdding: .day, value: 2, to: today)!, durationMinutes: 90, tss: 110),
                PlannedWorkout(title: "Récupération", date: calendar.date(byAdding: .day, value: 3, to: today)!, durationMinutes: 60, tss: 40),
            ],
            recentLoad: TrainingLoad(last7DaysHours: 11.5, last7DaysTSS: 620, fitnessCTL: 78, fatigueATL: 92),
            yearHoursByMonth: hours
        )
    }
}
