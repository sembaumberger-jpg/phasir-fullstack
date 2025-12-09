import SwiftUI

struct MainTabView: View {
    @ObservedObject var sessionManager: SessionManager
    @StateObject private var houseListViewModel: HouseListViewModel

    // Haupt-Init: wird in der echten App von ContentView/PhasirApp verwendet
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager

        // Wir holen den gleichen HouseService,
        // den der SessionManager beim Login mit Auth-Daten füttert.
        let sharedHouseService = sessionManager.getHouseService()

        _houseListViewModel = StateObject(
            wrappedValue: HouseListViewModel(service: sharedHouseService)
        )
    }

    // Convenience-Init: nur für Previews / Canvas
    init() {
        let baseURL = URL(string: "https://phasir-fullstack-production.up.railway.app")!
        let houseService = HouseService(baseURL: baseURL)
        let apiClient = ApiClient(baseURL: baseURL)
        let sessionManager = SessionManager(apiClient: apiClient, houseService: houseService)

        self.sessionManager = sessionManager
        _houseListViewModel = StateObject(
            wrappedValue: HouseListViewModel(service: houseService)
        )
    }

    var body: some View {
        TabView {
            HomeView(viewModel: houseListViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            HouseListView(viewModel: houseListViewModel)
                .tabItem {
                    Label("Objekte", systemImage: "building.2.fill")
                }

            InsightsView(viewModel: houseListViewModel)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            ProblemSolverTabView(viewModel: houseListViewModel)
                .tabItem {
                    Label("Solver", systemImage: "wrench.and.screwdriver.fill")
                }

            ProfileView(sessionManager: sessionManager)
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
        }
    }
}
