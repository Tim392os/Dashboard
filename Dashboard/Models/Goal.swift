import Foundation
import SwiftData

enum GoalPeriod: String, Codable, CaseIterable {
    case week, month, year

    var label: String {
        switch self {
        case .week: "Objectif de la semaine"
        case .month: "Objectif du mois"
        case .year: "Objectif de l'année"
        }
    }

    var icon: String {
        switch self {
        case .week: "calendar.badge.clock"
        case .month: "calendar"
        case .year: "sparkles"
        }
    }
}

@Model
final class Goal {
    /// Stocké en brut pour rester compatible SwiftData.
    var periodRaw: String
    var text: String
    /// Progression 0…1.
    var progress: Double
    var deadline: Date

    var period: GoalPeriod {
        get { GoalPeriod(rawValue: periodRaw) ?? .week }
        set { periodRaw = newValue.rawValue }
    }

    init(period: GoalPeriod, text: String, progress: Double, deadline: Date) {
        self.periodRaw = period.rawValue
        self.text = text
        self.progress = progress
        self.deadline = deadline
    }
}
