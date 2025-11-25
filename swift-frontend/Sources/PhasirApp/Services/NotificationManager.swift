import Foundation
import UIKit
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published var permissionGranted: Bool = false
    private let apiClient: ApiClient
    private var pendingDeviceToken: String?
    private weak var sessionManager: SessionManager?

    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }

    func configure(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func handleDeviceToken(_ data: Data) {
        let tokenString = data.map { String(format: "%02.2hhx", $0) }.joined()
        pendingDeviceToken = tokenString
        Task { await registerDeviceTokenIfPossible() }
    }

    func registerDeviceTokenIfPossible() async {
        guard let token = pendingDeviceToken, let sessionManager, sessionManager.isAuthenticated else { return }
        do {
            try await apiClient.registerDeviceToken(token)
            pendingDeviceToken = nil
        } catch {
            // Keep token cached; will retry next time.
        }
    }

    func scheduleLocalNotification(title: String, body: String, triggerDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
