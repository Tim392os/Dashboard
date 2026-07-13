import Foundation

// MARK: - Modèles

struct Homework: Identifiable, Hashable {
    var id = UUID()
    var subject: String
    var title: String
    var dueDate: Date
}

struct Exam: Identifiable, Hashable {
    var id = UUID()
    var subject: String
    var title: String
    var date: Date
}

struct SchoolSummary {
    var homework: [Homework]
    var exams: [Exam]
    /// Moyenne générale sur 100 (ou sur 20 selon l'école — affichée telle quelle).
    var average: Double?
    var averageScale: Double
    var studyMinutesToday: Int
}

// MARK: - Protocole

/// Source de données scolaires. Cabanga (plateforme scolaire belge) n'expose
/// pas d'API publique documentée à ce jour : `CabangaProvider` est prêt à
/// recevoir l'intégration (jeton dans le trousseau + endpoints à renseigner)
/// dès qu'un accès officiel existe. En attendant, l'app utilise des données
/// d'exemple / une saisie manuelle sans rien changer d'autre.
protocol SchoolDataProvider {
    var isConfigured: Bool { get }
    func fetchSummary() async throws -> SchoolSummary
}

// MARK: - Cabanga (squelette d'intégration)

struct CabangaProvider: SchoolDataProvider {
    /// À renseigner quand un accès API officiel est disponible.
    static let baseURL = URL(string: "https://app.cabanga.be/api")!

    var isConfigured: Bool {
        Keychain.get(.cabangaToken) != nil
    }

    func fetchSummary() async throws -> SchoolSummary {
        guard Keychain.get(.cabangaToken) != nil else {
            throw APIClient.APIError.notConfigured
        }
        // Endpoints à implémenter dès qu'une API officielle (ou un export
        // autorisé par l'école) est disponible. Ne jamais scraper avec les
        // identifiants de l'élève : uniquement une méthode approuvée.
        throw APIClient.APIError.notConfigured
    }
}

// MARK: - Données d'exemple

struct SampleSchoolProvider: SchoolDataProvider {
    var isConfigured: Bool { true }

    func fetchSummary() async throws -> SchoolSummary {
        let calendar = DateUtils.calendar
        let today = DateUtils.startOfToday()
        return SchoolSummary(
            homework: [
                Homework(subject: "Math", title: "Exercices dérivées p. 142", dueDate: calendar.date(byAdding: .day, value: 1, to: today)!),
                Homework(subject: "Anglais", title: "Essay — My ambitions", dueDate: calendar.date(byAdding: .day, value: 2, to: today)!),
                Homework(subject: "Physique", title: "Rapport de labo", dueDate: calendar.date(byAdding: .day, value: 4, to: today)!),
            ],
            exams: [
                Exam(subject: "Histoire", title: "Contrôle ch. 5–6", date: calendar.date(byAdding: .day, value: 3, to: today)!),
                Exam(subject: "Math", title: "Interro dérivées", date: calendar.date(byAdding: .day, value: 6, to: today)!),
            ],
            average: 82,
            averageScale: 100,
            studyMinutesToday: 45
        )
    }
}
