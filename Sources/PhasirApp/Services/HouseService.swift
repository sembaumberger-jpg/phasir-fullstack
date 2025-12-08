import Foundation
import Combine

@MainActor
final class HouseService: ObservableObject {
    @Published private(set) var houses: [House] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // 🔋 Energie-KI
    @Published private(set) var energyAdviceByHouseId: [String: EnergyAdvice] = [:]

    // 💶 Finanz-KI
    @Published private(set) var financeAdviceByHouseId: [String: FinanceAdvice] = [:]
    
    // 🛠 Reparatur-KI
    @Published private(set) var repairAdviceByHouseId: [String: RepairAdvice] = [:]

    // 📊 Mietspiegel / Markt-Benchmark
    @Published private(set) var rentBenchmarkAdvice: RentBenchmarkAdvice?
    
    // 🧭 Problem-Radar (prognostizierte Probleme je Haus)
    @Published private(set) var problemRadar: [HouseProblemRadar] = []

    // 🌀 Wetterwarnungen, gruppiert nach Haus-ID
    // Enthält die aktuellen Wetterwarnungen, sofern vom Backend abgerufen.
    @Published private(set) var weatherAlertsByHouseId: [String: [WeatherAlert]] = [:]

    let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // 🔐 Auth / Owner-Kontext
    private(set) var authToken: String?
    private(set) var currentUserId: String?

    init(baseURL: URL) {
        self.baseURL = baseURL

        // Custom Date-Decoder, der ISO8601 mit und ohne Millisekunden versteht
        let decoder = JSONDecoder()

        let isoWithMs = ISO8601DateFormatter()
        isoWithMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoNoMs = ISO8601DateFormatter()
        isoNoMs.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = isoWithMs.date(from: dateString) {
                return date
            }
            if let date = isoNoMs.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO8601 date, got \(dateString)"
            )
        }

        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        // Die standardmäßige Date-Decoding-Strategie deckt sowohl ISO8601 mit Millisekunden
        // als auch ohne Millisekunden ab und versucht zusätzlich ein Format ohne Zeitzone.
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            // Zuerst ISO8601 mit Millisekunden
            if let date = isoWithMs.date(from: dateString) {
                return date
            }
            // Dann ISO8601 ohne Millisekunden
            if let date = isoNoMs.date(from: dateString) {
                return date
            }
            // Fallback: ISO8601 ohne Zeitzoneninformationen (z. B. aus Wetterwarnungen)
            let isoNoZone = ISO8601DateFormatter()
            isoNoZone.formatOptions = [.withInternetDateTime]
            if let date = isoNoZone.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO8601 date, got \(dateString)"
            )
        }
    }

    // MARK: - Wetterwarnungen laden

    /// Lädt die Wetterwarnungen für ein bestimmtes Haus.
    ///
    /// Dieser Endpunkt erwartet, dass das Backend die Koordinaten der Immobilie kennt und
    /// die Bright‑Sky‑API für Wetterwarnungen abruft. Die Antwort sollte dem
    /// `WeatherAlert`‑Modell entsprechen. Nach erfolgreichem Laden wird das
    /// Ergebnis in `weatherAlertsByHouseId` gespeichert.
    func fetchWeatherAlerts(for houseId: String) async {
        guard !houseId.isEmpty else { return }

        let endpoint = baseURL
            .appendingPathComponent("weather-alerts")
            .appendingPathComponent(houseId)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        applyAuthHeaders(to: &request)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            struct AlertsWrapper: Codable {
                let alerts: [WeatherAlert]
            }
            let wrapper = try decoder.decode(AlertsWrapper.self, from: data)
            // Thread‑safe Update on MainActor
            await MainActor.run {
                weatherAlertsByHouseId[houseId] = wrapper.alerts
            }
        } catch {
            print("❌ Fehler in fetchWeatherAlerts:", error)
            await MainActor.run {
                weatherAlertsByHouseId[houseId] = []
            }
        }
    }

    // MARK: - Auth-Kontext aktualisieren

    func updateAuth(session: AuthSession?) {
        self.authToken = session?.token
        self.currentUserId = session?.userId
    }

    private func applyAuthHeaders(to request: inout URLRequest) {
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    // MARK: - Häuser laden

    func fetchHouses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // URL mit optionalem ?ownerId=...
            var components = URLComponents(url: baseURL.appendingPathComponent("houses"), resolvingAgainstBaseURL: false)!
            if let ownerId = currentUserId {
                components.queryItems = [URLQueryItem(name: "ownerId", value: ownerId)]
            }
            guard let url = components.url else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            applyAuthHeaders(to: &request)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("🌐 /houses status code:", http.statusCode)
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response von /houses:")
                print(jsonString)
            }

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let decoded = try decoder.decode([House].self, from: data)
            houses = decoded
            errorMessage = nil
        } catch {
            print("❌ Decoding-/Netzwerkfehler in fetchHouses:", error)
            if let decodingError = error as? DecodingError {
                print("🔍 Detail:", decodingError)
            }
            errorMessage = "Konnte Häuser nicht laden: \(error.localizedDescription)"
        }
    }

    // MARK: - Haus erstellen

    func createHouse(_ payload: CreateHouseRequest) async {
        isLoading = true
        defer { isLoading = false }

        do {
            var body = payload
            // 👇 OwnerId automatisch aus Session setzen, falls noch leer
            if body.ownerId == nil {
                body.ownerId = currentUserId
            }

            var request = URLRequest(url: baseURL.appendingPathComponent("houses"))
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            applyAuthHeaders(to: &request)
            request.httpBody = try encoder.encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("🌐 POST /houses status code:", http.statusCode)
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response von POST /houses:")
                print(jsonString)
            }

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let created = try decoder.decode(House.self, from: data)
            houses.append(created)
            errorMessage = nil
        } catch {
            print("❌ Fehler in createHouse:", error)
            if let decodingError = error as? DecodingError {
                print("🔍 Detail:", decodingError)
            }
            errorMessage = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    // MARK: - Haus aktualisieren

    func updateHouse(houseId: String, request: CreateHouseRequest) async {
        isLoading = true
        defer { isLoading = false }

        do {
            var body = request
            if body.ownerId == nil {
                body.ownerId = currentUserId
            }

            let url = baseURL
                .appendingPathComponent("houses")
                .appendingPathComponent(houseId)

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            applyAuthHeaders(to: &urlRequest)
            urlRequest.httpBody = try encoder.encode(body)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let http = response as? HTTPURLResponse {
                print("🌐 PUT /houses/\(houseId) status code:", http.statusCode)
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response PUT /houses/\(houseId):")
                print(jsonString)
            }

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let updated = try decoder.decode(House.self, from: data)
            print("✅ Decoded updated house with id:", updated.id)

            // Erst versuchen, über die ID aus dem Backend zu matchen
            if let index = houses.firstIndex(where: { $0.id == updated.id }) {
                houses[index] = updated
                print("🔁 Haus in Liste per updated.id ersetzt")
            }
            // Fallback: über die houseId aus dem Funktionsparameter
            else if let indexByParam = houses.firstIndex(where: { $0.id == houseId }) {
                houses[indexByParam] = updated
                print("🔁 Haus in Liste per houseId-Parameter ersetzt")
            }
            // Falls aus irgendeinem Grund nicht gefunden → anhängen
            else {
                houses.append(updated)
                print("➕ Updated-Haus nicht gefunden, neu hinzugefügt")
            }

            errorMessage = nil
        } catch {
            print("❌ Fehler in updateHouse:", error)
            if let decodingError = error as? DecodingError {
                print("🔍 Detail:", decodingError)
            }
            errorMessage = "Aktualisieren fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    // MARK: - Energie-Advice laden

    func fetchEnergyAdvice(for houseId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let url = baseURL.appendingPathComponent("ai/energy-advice")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            applyAuthHeaders(to: &request)

            let body: [String: String] = ["houseId": houseId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("🌐 POST /ai/energy-advice status code:", http.statusCode)
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response von /ai/energy-advice:")
                print(jsonString)
            }

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let advice = try decoder.decode(EnergyAdvice.self, from: data)
            energyAdviceByHouseId[houseId] = advice
            errorMessage = nil
        } catch {
            print("❌ Fehler in fetchEnergyAdvice:", error)
            if let decodingError = error as? DecodingError {
                print("🔍 Detail:", decodingError)
            }
            errorMessage = "Konnte Energieberatung nicht laden: \(error.localizedDescription)"
        }
    }

    // MARK: - Finanz-Advice laden

    func fetchFinanceAdvice(for houseId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let url = baseURL.appendingPathComponent("ai/finance-advice")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            applyAuthHeaders(to: &request)

            let body: [String: String] = ["houseId": houseId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("🌐 POST /ai/finance-advice status code:", http.statusCode)
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response von /ai/finance-advice:")
                print(jsonString)
            }

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let advice = try decoder.decode(FinanceAdvice.self, from: data)
            financeAdviceByHouseId[houseId] = advice
            errorMessage = nil
        } catch {
            print("❌ Fehler in fetchFinanceAdvice:", error)
            if let decodingError = error as? DecodingError {
                print("🔍 Detail:", decodingError)
            }
            errorMessage = "Konnte Finanzberatung nicht laden: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Mietspiegel / Markt-Benchmark laden

    func fetchRentBenchmark() async {
        guard let ownerId = currentUserId else {
            print("❌ Kein currentUserId gesetzt – kann Rent-Benchmark nicht laden.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let url = baseURL.appendingPathComponent("ai/rent-benchmark")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            applyAuthHeaders(to: &request)

            let body: [String: String] = ["ownerId": ownerId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("🌐 POST /ai/rent-benchmark status code:", http.statusCode)
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response von /ai/rent-benchmark:")
                print(jsonString)
            }

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let advice = try decoder.decode(RentBenchmarkAdvice.self, from: data)
            rentBenchmarkAdvice = advice
            errorMessage = nil
        } catch {
            print("❌ Fehler in fetchRentBenchmark:", error)
            if let decodingError = error as? DecodingError {
                print("🔍 Detail:", decodingError)
            }
            errorMessage = "Konnte Marktanalyse nicht laden: \(error.localizedDescription)"
        }
    }

    // MARK: - Reparatur-Advice laden

    func fetchRepairAdvice(for houseId: String,
                           description: String,
                           systemType: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let url = baseURL.appendingPathComponent("ai/repair-support")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            applyAuthHeaders(to: &request)

            var body: [String: Any] = [
                "houseId": houseId,
                "description": description
            ]
            if let systemType = systemType, !systemType.isEmpty {
                body["systemType"] = systemType
            }

            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("🌐 POST /ai/repair-support status code:", http.statusCode)
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response von /ai/repair-support:")
                print(jsonString)
            }

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let advice = try decoder.decode(RepairAdvice.self, from: data)
            repairAdviceByHouseId[houseId] = advice
            errorMessage = nil
        } catch {
            print("❌ Fehler in fetchRepairAdvice:", error)
            if let decodingError = error as? DecodingError {
                print("🔍 Detail:", decodingError)
            }
            errorMessage = "Konnte Reparatur-Einschätzung nicht laden: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Problem-Radar laden

    func fetchProblemRadar() async {
        guard let ownerId = currentUserId else {
            print("❌ Kein currentUserId gesetzt – kann Problem-Radar nicht laden.")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            var components = URLComponents(
                url: baseURL.appendingPathComponent("ai/problem-radar"),
                resolvingAgainstBaseURL: false
            )!
            components.queryItems = [URLQueryItem(name: "ownerId", value: ownerId)]
            guard let url = components.url else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            applyAuthHeaders(to: &request)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse {
                print("🌐 GET /ai/problem-radar status code:", http.statusCode)
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response von /ai/problem-radar:")
                print(jsonString)
            }
            
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            
            let radarResponse = try decoder.decode(ProblemRadarResponse.self, from: data)
            problemRadar = radarResponse.houses ?? []
            errorMessage = nil
        } catch {
            print("❌ Fehler in fetchProblemRadar:", error)
            if let decodingError = error as? DecodingError {
                print("🔍 Detail:", decodingError)
            }
            errorMessage = "Konnte Problem-Radar nicht laden: \(error.localizedDescription)"
        }
    }

    // MARK: - Demo-Haus

    func createDemoHouse() async {
        let now = Date()
        var payload = CreateHouseRequest()
        payload.ownerName = "Demo Nutzer"
        payload.ownerId = currentUserId
        payload.name = "Neues Haus"
        payload.address = "Beispielstraße 1"
        payload.buildYear = 2020
        payload.heatingType = "Wärmepumpe"
        payload.heatingInstallYear = 2021
        payload.lastHeatingService = now
        payload.roofInstallYear = 2020
        payload.lastRoofCheck = now
        payload.windowInstallYear = 2020
        payload.lastSmokeCheck = now

        await createHouse(payload)
    }
}
