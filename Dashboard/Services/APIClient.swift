import Foundation

/// Client HTTP minimal partagé par les intégrations (TrainingPeaks, Cabanga, banque).
struct APIClient {
    var baseURL: URL
    var bearerToken: String?

    enum APIError: LocalizedError {
        case invalidResponse
        case http(Int)
        case notConfigured

        var errorDescription: String? {
            switch self {
            case .invalidResponse: "Réponse invalide du serveur."
            case .http(let code): "Erreur HTTP \(code)."
            case .notConfigured: "Intégration non configurée."
            }
        }
    }

    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path),
                                       resolvingAgainstBaseURL: false)
        if !query.isEmpty { components?.queryItems = query }
        guard let url = components?.url else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode) }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}
