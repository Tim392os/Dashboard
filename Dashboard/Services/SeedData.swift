import Foundation
import SwiftData

/// Contenu initial au premier lancement : objectifs et compteurs par défaut.
/// Tout est modifiable ensuite dans l'app.
enum SeedData {
    private static let seedKey = "seed.v1.done"

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seedKey) else { return }
        defaults.set(true, forKey: seedKey)

        let calendar = DateUtils.calendar
        let today = DateUtils.startOfToday()

        // Objectifs semaine / mois / année.
        let endOfWeek = calendar.date(byAdding: .day, value: 7 - (calendar.component(.weekday, from: today) + 5) % 7, to: today)!
        let endOfMonth = calendar.dateInterval(of: .month, for: today)?.end ?? today
        let endOfYear = calendar.dateInterval(of: .year, for: today)?.end ?? today

        context.insert(Goal(period: .week, text: "Définir mon objectif de la semaine", progress: 0, deadline: endOfWeek))
        context.insert(Goal(period: .month, text: "Définir mon objectif du mois", progress: 0, deadline: endOfMonth))
        context.insert(Goal(period: .year, text: "Définir mon objectif de l'année", progress: 0, deadline: endOfYear))

        // Compteurs par défaut — dates modifiables dans l'app.
        let year = calendar.component(.year, from: today)
        let summerBreak = calendar.date(from: DateComponents(year: year, month: 7, day: 1)).flatMap {
            $0 < today ? calendar.date(from: DateComponents(year: year + 1, month: 7, day: 1)) : $0
        } ?? today
        let christmas = DateUtils.nextOccurrence(day: 25, month: 12)

        context.insert(Countdown(name: "Vacances", icon: "sun.max.fill", date: summerBreak, sortOrder: 0))
        context.insert(Countdown(name: "Mon anniversaire", icon: "gift.fill",
                                 date: calendar.date(byAdding: .month, value: 3, to: today)!,
                                 repeatsYearly: true, sortOrder: 1))
        context.insert(Countdown(name: "Noël", icon: "snowflake", date: christmas, repeatsYearly: true, sortOrder: 2))
        context.insert(Countdown(name: "Voyage", icon: "airplane",
                                 date: calendar.date(byAdding: .month, value: 2, to: today)!, sortOrder: 3))

        _ = FinanceState.fetchOrCreate(context: context)
        try? context.save()
    }
}
