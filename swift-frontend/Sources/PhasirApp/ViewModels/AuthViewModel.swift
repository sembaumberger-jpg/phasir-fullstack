import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let sessionManager: SessionManager

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            try await sessionManager.login(email: email, password: password)
        } catch {
            if let error = error as? LocalizedError, let desc = error.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}
