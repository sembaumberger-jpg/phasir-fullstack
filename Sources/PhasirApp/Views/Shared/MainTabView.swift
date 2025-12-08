import SwiftUI

struct MainTabView: View {
    @ObservedObject var sessionManager: SessionManager
    @StateObject private var houseListViewModel: HouseListViewModel
    private let houseService: HouseService

    // Haupt-Init: wird in der echten App von ContentView verwendet
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager

        let baseURL = URL(string: "https://phasir-fullstack-production.up.railway.app")!
        let houseService = HouseService(baseURL: baseURL)
        self.houseService = houseService

        _houseListViewModel = StateObject(
            wrappedValue: HouseListViewModel(service: houseService)
        )
    }

    // Convenience-Init: für Previews / Canvas: `MainTabView()`
    init() {
        let baseURL = URL(string: "https://phasir-fullstack-production.up.railway.app")!
        let houseService = HouseService(baseURL: baseURL)
        self.houseService = houseService

        let apiClient = ApiClient(baseURL: baseURL)
        let sessionManager = SessionManager(apiClient: apiClient, houseService: houseService)

        self.sessionManager = sessionManager
        _houseListViewModel = StateObject(
            wrappedValue: HouseListViewModel(service: houseService)
        )
    }

    var body: some View {
        TabView {
            // HOME
            NavigationStack {
                HomeView(
                    viewModel: houseListViewModel,
                    houseService: houseService
                )
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            // OBJEKTE
            NavigationStack {
                HouseListView(viewModel: houseListViewModel)
            }
            .tabItem {
                Label("Objekte", systemImage: "building.2.fill")
            }

            // INSIGHTS
            NavigationStack {
                InsightsView(viewModel: houseListViewModel)
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.xaxis")
            }

            // SOLVER
            NavigationStack {
                ProblemSolverTabView(viewModel: houseListViewModel)
            }
            .tabItem {
                Label("Solver", systemImage: "wand.and.stars")
            }

            // PROFIL
            NavigationStack {
                ProfileView(sessionManager: sessionManager)
            }
            .tabItem {
                Label("Profil", systemImage: "person.fill")
            }
        }
        .tint(Color.phasirAccent)
        .background(Color.phasirBackground.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}
