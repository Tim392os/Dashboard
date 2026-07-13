import Foundation

/// Données bancaires agrégées pour la carte Finances.
struct BankSummary {
    var available: Double
    var savings: Double
    var monthExpenses: Double
}

/// Source de données bancaires.
///
/// BNP Paribas (Fortis) expose des API PSD2 « Open Banking », mais elles sont
/// réservées aux prestataires agréés (licence AISP auprès de la BNB/ACPR) —
/// une app personnelle ne peut pas s'y connecter directement. Deux voies
/// réalistes, sans jamais stocker d'identifiants bancaires :
///  1. passer par un agrégateur agréé (Tink, Powens, Nordigen/GoCardless…)
///     et n'échanger que des jetons OAuth stockés dans le trousseau ;
///  2. saisie manuelle / import CSV — comportement par défaut de l'app.
protocol BankDataProvider {
    var isConfigured: Bool { get }
    func fetchSummary() async throws -> BankSummary
}

/// Squelette prêt pour un agrégateur PSD2. Devient actif dès qu'un jeton
/// est présent dans le trousseau et que les endpoints sont renseignés.
struct OpenBankingProvider: BankDataProvider {
    var isConfigured: Bool {
        Keychain.get(.bankToken) != nil
    }

    func fetchSummary() async throws -> BankSummary {
        guard Keychain.get(.bankToken) != nil else {
            throw APIClient.APIError.notConfigured
        }
        // À implémenter avec l'agrégateur choisi (comptes + soldes + transactions).
        throw APIClient.APIError.notConfigured
    }
}
