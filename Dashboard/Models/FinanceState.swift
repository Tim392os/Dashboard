import Foundation
import SwiftData

/// État financier affiché sur le dashboard.
/// Saisie manuelle par défaut ; peut être alimenté par un `BankDataProvider`
/// (agrégateur PSD2) une fois configuré. Aucun identifiant bancaire n'est
/// stocké ici — uniquement des montants. Les jetons d'accès vivent dans le
/// trousseau (Keychain).
@Model
final class FinanceState {
    var available: Double
    var savings: Double
    var monthExpenses: Double
    var savingsGoal: Double
    /// Total « argent économisé » affiché dans les statistiques.
    var moneySaved: Double
    var updatedAt: Date

    init() {
        self.available = 0
        self.savings = 0
        self.monthExpenses = 0
        self.savingsGoal = 1000
        self.moneySaved = 0
        self.updatedAt = .now
    }

    var savingsProgress: Double {
        savingsGoal > 0 ? min(savings / savingsGoal, 1) : 0
    }

    static func fetchOrCreate(context: ModelContext) -> FinanceState {
        if let existing = try? context.fetch(FetchDescriptor<FinanceState>()).first {
            return existing
        }
        let state = FinanceState()
        context.insert(state)
        return state
    }
}

extension Double {
    var asEuro: String {
        self.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}
