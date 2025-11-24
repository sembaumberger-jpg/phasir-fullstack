import Foundation
import Combine

@MainActor
final class HouseService: ObservableObject {
    @Published private(set) var houses: [House] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL) {
        self.baseURL = baseURL
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func fetchHouses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var request = URLRequest(url: baseURL.appending(path: "/houses"))
            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            houses = try decoder.decode([House].self, from: data)
            errorMessage = nil
        } catch {
            errorMessage = "Konnte Häuser nicht laden: \(error.localizedDescription)"
        }
    }

    func createHouse(_ payload: CreateHousePayload) async {
        isLoading = true
        defer { isLoading = false }

        do {
            var request = URLRequest(url: baseURL.appending(path: "/houses"))
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let created = try decoder.decode(House.self, from: data)
            houses.append(created)
            errorMessage = nil
        } catch {
            errorMessage = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    func createDemoHouse() async {
        let now = Date()
        let payload = CreateHousePayload(
            ownerName: "Demo Nutzer",
            name: "Neues Haus",
            address: "Beispielstraße 1",
            buildYear: 2020,
            heatingType: "Wärmepumpe",
            heatingInstallYear: 2021,
            lastHeatingService: now,
            roofInstallYear: 2020,
            lastRoofCheck: now,
            windowInstallYear: 2020,
            lastSmokeCheck: now
        )

        await createHouse(payload)
    }
}
