import SwiftUI

struct MainTabView: View {
    @ObservedObject var sessionManager: SessionManager
    @StateObject private var houseListViewModel: HouseListViewModel

    init(sessionManager: SessionManager, houseService: HouseService) {
        self.sessionManager = sessionManager
        _houseListViewModel = StateObject(
            wrappedValue: HouseListViewModel(service: houseService)
        )
    }

    var body: some View {
        TabView {
            // HOME: Aktionen + News
            NavigationStack {
                HomeView(viewModel: houseListViewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            // OBJEKTE: nur Immobilien-Liste
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
