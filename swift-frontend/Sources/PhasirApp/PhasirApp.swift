import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
    var notificationManager: NotificationManager?

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        notificationManager?.handleDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs Registrierung fehlgeschlagen: \(error.localizedDescription)")
    }
}

@main
struct PhasirApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let apiClient = ApiClient()
    @StateObject private var sessionManager: SessionManager
    @StateObject private var notificationManager: NotificationManager

    init() {
        let sessionManager = SessionManager(apiClient: apiClient)
        _sessionManager = StateObject(wrappedValue: sessionManager)

        let notificationManager = NotificationManager(apiClient: apiClient)
        _notificationManager = StateObject(wrappedValue: notificationManager)

        notificationManager.configure(sessionManager: sessionManager)
        appDelegate.notificationManager = notificationManager
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .onChange(of: sessionManager.isAuthenticated) { _ in
                    Task { await notificationManager.registerDeviceTokenIfPossible() }
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if sessionManager.isAuthenticated {
            MainTabView(sessionManager: sessionManager, notificationManager: notificationManager, apiClient: apiClient)
        } else {
            LoginView(viewModel: AuthViewModel(sessionManager: sessionManager))
        }
    }
}
