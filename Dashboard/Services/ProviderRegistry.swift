import Foundation

/// Point unique de sélection des sources de données externes.
///
/// Chaque intégration réelle (TrainingPeaks, Cabanga, banque) devient active
/// automatiquement dès que ses identifiants sont configurés dans le trousseau ;
/// sinon l'app retombe sur des données d'exemple (mode démo) ou la saisie
/// manuelle. Ajouter une intégration = implémenter le protocole et la brancher
/// ici, sans toucher aux vues.
enum ProviderRegistry {
    static var training: TrainingDataProvider {
        let real = TrainingPeaksProvider()
        return real.isConfigured ? real : SampleTrainingProvider()
    }

    static var school: SchoolDataProvider {
        let real = CabangaProvider()
        return real.isConfigured ? real : SampleSchoolProvider()
    }

    /// Nil quand aucun agrégateur n'est configuré → la carte Finances
    /// utilise la saisie manuelle (SwiftData).
    static var bank: BankDataProvider? {
        let real = OpenBankingProvider()
        return real.isConfigured ? real : nil
    }

    static var trainingIsLive: Bool { TrainingPeaksProvider().isConfigured }
    static var schoolIsLive: Bool { CabangaProvider().isConfigured }
}
