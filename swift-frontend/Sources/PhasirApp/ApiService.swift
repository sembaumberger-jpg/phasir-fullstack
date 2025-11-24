import Foundation

final class ApiService {
    private let baseURL: URL
    private let session: URLSession

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeISO8601(_:))
        return decoder
    }()

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom(Self.encodeISO8601(_:))
        return encoder
    }()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(path: path, method: "GET", body: Optional<CreateHouseRequest>.none as CreateHouseRequest?)
    }

    func post<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        try await request(path: path, method: "POST", body: body)
    }

    func put<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        try await request(path: path, method: "PUT", body: body)
    }

    private func request<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiServiceError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ApiServiceError.serverError(status: httpResponse.statusCode, message: serverMessage)
        }

        return try decoder.decode(T.self, from: data)
    }
}

extension ApiService {
    enum ApiServiceError: LocalizedError {
        case invalidResponse
        case serverError(status: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Ungültige Server-Antwort."
            case let .serverError(status, message):
                return "Serverfehler (\(status)): \(message)"
            }
        }
    }
}

private extension ApiService {
    static func isoFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    static func decodeISO8601(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        let formatter = isoFormatter()
        if let date = formatter.date(from: value) {
            return date
        }

        if let fallback = ISO8601DateFormatter().date(from: value) {
            return fallback
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Ungültiges Datumsformat: \(value)"
        )
    }

    static func encodeISO8601(_ date: Date, encoder: Encoder) throws {
        let value = isoFormatter().string(from: date)
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
