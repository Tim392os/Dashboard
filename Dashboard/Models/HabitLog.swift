import Foundation
import SwiftData

/// Journal d'habitudes d'une journée. Une entrée par jour (clé = début de journée).
@Model
final class HabitLog {
    @Attribute(.unique) var day: Date
    /// Heures de sommeil — remplies depuis Apple Santé quand disponible.
    var sleepHours: Double
    /// Portions de fruits/légumes (saisie rapide).
    var fruitsVeggies: Int
    /// Temps d'écran en minutes — saisie manuelle (l'API Temps d'écran d'Apple
    /// n'expose pas les totaux aux apps tierces).
    var screenTimeMinutes: Int

    init(day: Date = DateUtils.startOfToday()) {
        self.day = day
        self.sleepHours = 0
        self.fruitsVeggies = 0
        self.screenTimeMinutes = 0
    }

    static let fruitsVeggiesTarget = 5

    /// Journée « réussie » pour la série : objectif fruits/légumes atteint.
    var isComplete: Bool {
        fruitsVeggies >= Self.fruitsVeggiesTarget
    }
}

enum HabitStreak {
    /// Série de jours consécutifs (en remontant depuis aujourd'hui ou hier)
    /// où les habitudes sont complètes.
    static func current(logs: [HabitLog]) -> Int {
        let byDay = Dictionary(uniqueKeysWithValues: logs.map { ($0.day, $0) })
        let calendar = DateUtils.calendar
        var day = DateUtils.startOfToday()
        var streak = 0

        // Aujourd'hui ne casse pas la série tant que la journée n'est pas finie.
        if let today = byDay[day], today.isComplete { streak += 1 }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return streak }
        day = yesterday

        while let log = byDay[day], log.isComplete {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// Récupère (ou crée) l'entrée du jour.
    static func todayLog(context: ModelContext) -> HabitLog {
        let today = DateUtils.startOfToday()
        let predicate = #Predicate<HabitLog> { $0.day == today }
        if let existing = try? context.fetch(FetchDescriptor(predicate: predicate)).first {
            return existing
        }
        let log = HabitLog(day: today)
        context.insert(log)
        return log
    }
}
