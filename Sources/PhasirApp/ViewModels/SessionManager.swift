import Foundation

@MainActor
final class SessionManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var session: AuthSession?

    private let apiClient: ApiClient
    private let houseService: HouseService

    init(apiClient: ApiClient, houseService: HouseService) {
        self.apiClient = apiClient
        self.houseService = houseService
    }

    /// Login gegen das Backend
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await apiClient.login(email: email, password: password)

            self.session = session
            houseService.updateAuth(session: session)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            self.session = nil

            if let error = error as? LocalizedError,
               let desc = error.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = error.localizedDescription
            }

            isLoading = false
            throw error
        }

        isLoading = false
    }

    /// Registrierung + direkt einloggen
    func register(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await apiClient.register(email: email, password: password)

            self.session = session
            houseService.updateAuth(session: session)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            self.session = nil

            if let error = error as? LocalizedError,
               let desc = error.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = error.localizedDescription
            }

            isLoading = false
            throw error
        }

        isLoading = false
    }

    func logout() {
        isAuthenticated = false
        errorMessage = nil
        session = nil
        houseService.updateAuth(session: nil)
    }
}
