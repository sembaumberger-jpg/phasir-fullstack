import SwiftUI

@main
struct PhasirApp: App {
    private let service = HouseService(
        apiService: ApiService(
            baseURL: URL(string: "https://congenial-spoon-jjvjg5qg7q9qc5rq9-4000.app.github.dev")!
        )
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(service)
        }
    }
}
