import Foundation

final class ApiClient {
    static let sharedBaseURL = URL(string: "https://congenial-spoon-jjvjg5qg7q9qc5rq9-4000.app.github.dev")!

    private let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var token: String?

    init(baseURL: URL = ApiClient.sharedBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func updateToken(_ token: String?) {
        self.token = token
    }

    func login(email: String, password: String) async throws -> AuthSession {
        let payload = ["email": email, "password": password]
        let response: AuthResponse = try await request(path: "/auth/login", method: "POST", body: payload, authorized: false)
        return AuthSession(token: response.token, userId: response.userId)
    }

    func fetchHouses() async throws -> [House] {
        try await request(path: "/houses", method: "GET", body: Optional<String>.none, authorized: true)
    }

    func createHouse(_ input: CreateHouseRequest) async throws -> House {
        try await request(path: "/houses", method: "POST", body: input, authorized: true)
    }

    func updateHouse(id: String, with input: UpdateHouseRequest) async throws -> House {
        try await request(path: "/houses/\(id)", method: "PUT", body: input, authorized: true)
    }

    func registerDeviceToken(_ token: String) async throws {
        let registration = DeviceRegistration(deviceToken: token, platform: "ios")
        let _: EmptyResponse = try await request(path: "/devices", method: "POST", body: registration, authorized: true)
    }
}

private extension ApiClient {
    struct EmptyResponse: Codable {}

    func request<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        authorized: Bool
    ) async throws -> T {
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appendingPathComponent(cleanPath)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authorized, let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { request.httpBody = try encoder.encode(body) }

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unbekannter Fehler"
            throw ApiError.serverError(status: httpResponse.statusCode, message: serverMessage)
        }

        if T.self == EmptyResponse.self, data.isEmpty {
            return EmptyResponse() as! T
        }

        return try decoder.decode(T.self, from: data)
    }

    enum ApiError: LocalizedError {
        case invalidResponse
        case serverError(status: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Ungültige Serverantwort"
            case let .serverError(status, message):
                return "Fehler (\(status)): \(message)"
            }
        }
    }
}
