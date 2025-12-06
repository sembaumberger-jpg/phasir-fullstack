import Foundation

/// API-Client für Phasir.
/// Macht Login/Registrierung gegen das Backend (`/auth/login`, `/auth/register`)
/// und generische GET-Requests.
final class ApiClient {

    // 🆕 Singleton für einfache Nutzung im ganzen Projekt
    static let shared = ApiClient(
        baseURL: URL(string: "http://localhost:4000")!
    )

    let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    enum ApiError: LocalizedError {
        case invalidCredentials
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "E-Mail oder Passwort sind nicht korrekt."
            case .serverError(let message):
                return message
            }
        }
    }

    // MARK: - Private Helper

    private func makeURL(_ path: String) -> URL {
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return baseURL.appendingPathComponent(trimmedPath)
    }

    // MARK: - Auth

    /// Echte Login-Funktion: POST /auth/login
    /// Erwartet vom Backend: { "token": "...", "userId": "...", "email": "..." }
    func login(email: String, password: String) async throws -> AuthSession {
        var request = URLRequest(url: makeURL("/auth/login"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError.serverError("Ungültige Server-Antwort.")
        }

        guard 200..<300 ~= http.statusCode else {
            if http.statusCode == 400 || http.statusCode == 401 {
                throw ApiError.invalidCredentials
            } else {
                throw ApiError.serverError("Serverfehler (\(http.statusCode)).")
            }
        }

        let decoder = JSONDecoder()
        let authResponse = try decoder.decode(AuthResponse.self, from: data)

        return AuthSession(
            token: authResponse.token,
            userId: authResponse.userId,
            email: authResponse.email
        )
    }

    /// Registrierung: POST /auth/register
    /// Erwartet vom Backend: { "token": "...", "userId": "...", "email": "..." }
    func register(email: String, password: String) async throws -> AuthSession {
        var request = URLRequest(url: makeURL("/auth/register"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError.serverError("Ungültige Server-Antwort.")
        }

        guard 200..<300 ~= http.statusCode else {
            if http.statusCode == 400 || http.statusCode == 409 {
                // 400 = invalid input, 409 = E-Mail schon vergeben
                throw ApiError.invalidCredentials
            } else {
                throw ApiError.serverError("Serverfehler (\(http.statusCode)).")
            }
        }

        let decoder = JSONDecoder()
        let authResponse = try decoder.decode(AuthResponse.self, from: data)

        return AuthSession(
            token: authResponse.token,
            userId: authResponse.userId,
            email: authResponse.email
        )
    }

    // MARK: - Generischer GET-Request (für z.B. /news/real-estate)

    /// Führt einen GET-Request aus und decodiert das Ergebnis in den gewünschten Typ.
    /// Beispiel:
    /// let response: RealEstateNewsResponse = try await apiClient.get("/news/real-estate")
    func get<T: Decodable>(_ path: String) async throws -> T {
        let url = makeURL(path)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError.serverError("Ungültige Server-Antwort.")
        }

        guard 200..<300 ~= http.statusCode else {
            throw ApiError.serverError("Serverfehler (\(http.statusCode)).")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
