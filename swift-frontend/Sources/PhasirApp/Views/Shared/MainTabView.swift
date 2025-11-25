import SwiftUI

struct MainTabView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var notificationManager: NotificationManager
    @StateObject private var houseListViewModel: HouseListViewModel

    init(sessionManager: SessionManager, notificationManager: NotificationManager, apiClient: ApiClient) {
        self._houseListViewModel = StateObject(wrappedValue: HouseListViewModel(apiClient: apiClient))
        self.sessionManager = sessionManager
        self.notificationManager = notificationManager
    }

    var body: some View {
        TabView {
            HouseListView(viewModel: houseListViewModel)
                .tabItem {
                    Label("Immobilien", systemImage: "house.fill")
                }

            MaintenancePlaceholderView()
                .tabItem {
                    Label("Wartung", systemImage: "bell.badge")
                }

            SettingsView(sessionManager: sessionManager)
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
        .onAppear {
            notificationManager.requestAuthorization()
            Task { await notificationManager.registerDeviceTokenIfPossible() }
        }
    }
}

struct MaintenancePlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("Erinnerungen")
                .font(.title3.weight(.semibold))
            Text("Push-Benachrichtigungen informieren Sie rechtzeitig über anstehende Wartungen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

struct SettingsView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            Form {
                Section("Konto") {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        VStack(alignment: .leading) {
                            Text(sessionManager.currentUserId ?? "Unbekannter Nutzer")
                                .font(.subheadline)
                            Text("Angemeldet")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button(role: .destructive) { sessionManager.logout() } label: {
                        Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}
