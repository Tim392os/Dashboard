import Foundation
import SwiftData

/// Compteur de jours avant un événement. Les dates sont modifiables ;
/// les événements récurrents (anniversaire, Noël) avancent automatiquement
/// à l'occurrence suivante une fois passés.
@Model
final class Countdown {
    var name: String
    var icon: String
    var date: Date
    /// Pour les événements annuels : jour/mois à répéter.
    var repeatsYearly: Bool
    var sortOrder: Int

    init(name: String, icon: String, date: Date, repeatsYearly: Bool = false, sortOrder: Int = 0) {
        self.name = name
        self.icon = icon
        self.date = date
        self.repeatsYearly = repeatsYearly
        self.sortOrder = sortOrder
    }

    /// Date effective : la prochaine occurrence pour les événements annuels passés.
    var effectiveDate: Date {
        guard repeatsYearly, date < DateUtils.startOfToday() else { return date }
        let comps = DateUtils.calendar.dateComponents([.day, .month], from: date)
        return DateUtils.nextOccurrence(day: comps.day ?? 1, month: comps.month ?? 1)
    }

    var daysRemaining: Int {
        DateUtils.daysUntil(effectiveDate)
    }
}
