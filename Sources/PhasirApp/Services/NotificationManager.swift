import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: ObservableObject {
    private let apiClient: ApiClient
    private weak var sessionManager: SessionManager?

    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }

    func configure(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        requestAuthorization()
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Fehler bei Notification-Berechtigung: \(error)")
                } else {
                    print("Notification permission granted: \(granted)")
                }
            }
    }

    func handleDeviceToken(_ deviceToken: Data) {
        // Momentan schicken wir den Token noch nicht ans Backend,
        // sondern loggen ihn nur.
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Device Token: \(tokenString)")
        // Später: hier ApiClient aufrufen und Token an Server senden.
    }

    func registerDeviceTokenIfPossible() async {
        guard sessionManager?.isAuthenticated == true else { return }

        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
