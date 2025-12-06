import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager: SessionManager
    @StateObject private var houseService: HouseService
    @StateObject private var authViewModel: AuthViewModel

    @State private var isShowingRegister: Bool = false

    init() {
        let baseURL = URL(string: "http://localhost:4000")!

        let houseService = HouseService(baseURL: baseURL)
        let apiClient = ApiClient(baseURL: baseURL)   // oder ApiClient.shared, beides ok
        let sessionManager = SessionManager(apiClient: apiClient, houseService: houseService)
        let authViewModel = AuthViewModel(sessionManager: sessionManager)

        _houseService = StateObject(wrappedValue: houseService)
        _sessionManager = StateObject(wrappedValue: sessionManager)
        _authViewModel = StateObject(wrappedValue: authViewModel)
    }

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            Group {
                if sessionManager.isAuthenticated {
                    MainTabView(sessionManager: sessionManager, houseService: houseService)
                } else {
                    if isShowingRegister {
                        RegisterView(
                            viewModel: authViewModel,
                            onLoginTapped: {
                                withAnimation {
                                    isShowingRegister = false
                                    authViewModel.errorMessage = nil
                                }
                            }
                        )
                    } else {
                        LoginView(
                            viewModel: authViewModel,
                            onRegisterTapped: {
                                withAnimation {
                                    isShowingRegister = true
                                    authViewModel.errorMessage = nil
                                }
                            }
                        )
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
