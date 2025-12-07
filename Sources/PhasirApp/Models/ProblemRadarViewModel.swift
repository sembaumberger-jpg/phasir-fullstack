import Foundation

@MainActor
final class ProblemRadarViewModel: ObservableObject {
    @Published var houses: [HouseProblemRadar] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let houseService: HouseService

    init(houseService: HouseService) {
        self.houseService = houseService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Der Service schreibt intern in houseService.problemRadar
        await houseService.fetchProblemRadar()

        // 👉 danach holen wir die Daten aus dem Service
        self.houses = houseService.problemRadar
    }
}
