import Foundation

/// ViewModel für das Problem-Radar.
/// Lädt für den aktuell angemeldeten Nutzer alle prognostizierten Probleme und stellt sie für die UI bereit.
@MainActor
class ProblemRadarViewModel: ObservableObject {
    /// Liste aller Häuser mit ihren Prognosen
    @Published var houses: [HouseProblemRadar] = []
    /// Flag, ob die Daten aktuell geladen werden
    @Published var isLoading: Bool = false

    private let houseService: HouseService

    init(houseService: HouseService) {
        self.houseService = houseService
    }

    /// Lädt die Problemprognosen über den HouseService
    ///
    /// Die Methode `fetchProblemRadar()` im HouseService schreibt das Ergebnis
    /// in `houseService.problemRadar`. Sie liefert keinen Rückgabewert, daher
    /// setzen wir anschließend `houses` aus dieser Property.
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        await houseService.fetchProblemRadar()
        houses = houseService.problemRadar
    }
}
