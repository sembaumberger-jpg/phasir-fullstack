import Foundation
import SwiftUI

@MainActor
final class SessionManager: ObservableObject {
    @AppStorage("phasir.token") private var storedToken: String = ""
    @AppStorage("phasir.userId") private var storedUserId: String = ""

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUserId: String?
    @Published private(set) var token: String?

    private let apiClient: ApiClient

    init(apiClient: ApiClient) {
        self.apiClient = apiClient
        restoreSession()
    }

    func restoreSession() {
        if !storedToken.isEmpty, !storedUserId.isEmpty {
            token = storedToken
            currentUserId = storedUserId
            isAuthenticated = true
            apiClient.updateToken(storedToken)
        }
    }

    func login(email: String, password: String) async throws {
        let session = try await apiClient.login(email: email, password: password)
        token = session.token
        currentUserId = session.userId
        isAuthenticated = true
        storedToken = session.token
        storedUserId = session.userId
        apiClient.updateToken(session.token)
    }

    func logout() {
        isAuthenticated = false
        currentUserId = nil
        token = nil
        storedToken = ""
        storedUserId = ""
        apiClient.updateToken(nil)
    }
}
