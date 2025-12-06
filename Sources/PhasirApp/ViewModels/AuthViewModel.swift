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

    /// Einfache E-Mail/Passwort-Validierung (Client-Seite),
    /// das Backend prüft den Rest.
    private func validateInputs(forRegistration: Bool) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Bitte E-Mail und Passwort eingeben."
            return false
        }

        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = "Bitte eine gültige E-Mail-Adresse eingeben."
            return false
        }

        if forRegistration {
            guard trimmedPassword.count >= 8 else {
                errorMessage = "Das Passwort muss mindestens 8 Zeichen lang sein."
                return false
            }
        }

        return true
    }

    func login() async {
        guard !isLoading else { return }
        errorMessage = nil

        guard validateInputs(forRegistration: false) else { return }

        isLoading = true
        do {
            try await sessionManager.login(email: email, password: password)
        } catch {
            if let error = error as? LocalizedError, let desc = error.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = "Login fehlgeschlagen. Bitte Zugangsdaten prüfen."
            }
        }
        isLoading = false
    }

    func register() async {
        guard !isLoading else { return }
        errorMessage = nil

        guard validateInputs(forRegistration: true) else { return }

        isLoading = true
        do {
            try await sessionManager.register(email: email, password: password)
        } catch {
            if let error = error as? LocalizedError, let desc = error.errorDescription {
                errorMessage = desc
            } else {
                errorMessage = "Registrierung fehlgeschlagen. Bitte Eingaben prüfen."
            }
        }
        isLoading = false
    }
}
