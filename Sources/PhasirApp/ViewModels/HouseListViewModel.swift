import Foundation

@MainActor
final class HouseListViewModel: ObservableObject {
    // MARK: - Published State

    @Published var houses: [House] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Mietspiegel / Markt-Benchmark
    @Published var isLoadingRentBenchmark: Bool = false

    // Immobilien-News für den News-Feed
    @Published var newsArticles: [NewsArticle] = []

    // MARK: - Dependencies

    private let service: HouseService
    private let apiClient: ApiClient   // direkter Zugriff auf Backend-API

    init(service: HouseService, apiClient: ApiClient = .shared) {
        self.service = service
        self.apiClient = apiClient
    }

    // MARK: - Häuser laden / schreiben

    /// Lädt Häuser über den Service und spiegelt den Zustand in das ViewModel.
    func load() async {
        isLoading = true
        defer { isLoading = false }

        await service.fetchHouses()
        houses = service.houses
        errorMessage = service.errorMessage
    }

    /// Legt ein neues Haus über das Backend an.
    func createHouse(request: CreateHouseRequest) async -> Bool {
        await service.createHouse(request)
        houses = service.houses
        errorMessage = service.errorMessage
        return service.errorMessage == nil
    }

    /// Aktualisiert ein bestehendes Haus.
    func updateHouse(houseId: String, request: CreateHouseRequest) async -> Bool {
        await service.updateHouse(houseId: houseId, request: request)
        houses = service.houses
        errorMessage = service.errorMessage
        return service.errorMessage == nil
    }

    /// Legt ein Demo-Haus an (für leere States / Tests).
    func createDemoHouse() async {
        await service.createDemoHouse()
        houses = service.houses
        errorMessage = service.errorMessage
    }

    // MARK: - Energie-Assistent (pro Objekt, ruft /ai/energy-advice auf)

    /// Liefert den bereits geladenen EnergyAdvice für ein Haus (falls vorhanden).
    func energyAdvice(for houseId: String) -> EnergyAdvice? {
        service.energyAdviceByHouseId[houseId]
    }

    /// Lädt EnergyAdvice für ein Haus vom Backend.
    func loadEnergyAdvice(for houseId: String) async {
        await service.fetchEnergyAdvice(for: houseId)
        errorMessage = service.errorMessage

        // energyAdviceByHouseId liegt im Service → manuell UI-Update anstoßen
        objectWillChange.send()
    }

    // MARK: - Finanz-Assistent (Objekt-Ebene)

    /// Liefert den bereits geladenen FinanceAdvice für ein Haus (falls vorhanden).
    func financeAdvice(for houseId: String) -> FinanceAdvice? {
        service.financeAdviceByHouseId[houseId]
    }

    /// Lädt FinanceAdvice für ein Haus vom Backend (oder heuristisch).
    func loadFinanceAdvice(for houseId: String) async {
        await service.fetchFinanceAdvice(for: houseId)
        errorMessage = service.errorMessage

        // Finance-Daten liegen im Service → UI-Update anstoßen
        objectWillChange.send()
    }

    // MARK: - Markt-Benchmark / Mietspiegel (Portfolio-Ebene)

    func rentBenchmarkAdvice() -> RentBenchmarkAdvice? {
        service.rentBenchmarkAdvice
    }

    func loadRentBenchmark() async {
        guard !isLoadingRentBenchmark else { return }
        isLoadingRentBenchmark = true
        defer { isLoadingRentBenchmark = false }

        await service.fetchRentBenchmark()
        errorMessage = service.errorMessage

        // Benchmark-Daten liegen im Service → UI-Update anstoßen
        objectWillChange.send()
    }

    // MARK: - Reparatur-Assistent

    /// Liefert den bereits geladenen RepairAdvice für ein Haus (falls vorhanden).
    func repairAdvice(for houseId: String) -> RepairAdvice? {
        service.repairAdviceByHouseId[houseId]
    }

    /// Lädt RepairAdvice für ein Haus vom Backend.
    func loadRepairAdvice(
        for houseId: String,
        description: String,
        systemType: String?
    ) async {
        await service.fetchRepairAdvice(
            for: houseId,
            description: description,
            systemType: systemType
        )
        errorMessage = service.errorMessage

        // Repair-Daten liegen im Service → UI-Update
        objectWillChange.send()
    }

    // MARK: - Immobilien-News (externe Real-Estate-News für den Feed)

    /// Lädt Immobilien-News vom Backend (/news/real-estate) und speichert sie im ViewModel.
    func loadNews() async {
        do {
            let response: RealEstateNewsResponse = try await apiClient.get("/news/real-estate")
            newsArticles = response.articles
        } catch {
            print("❌ Failed to load real estate news:", error)
            errorMessage = "Immobilien-News konnten nicht geladen werden."
        }
    }
}
