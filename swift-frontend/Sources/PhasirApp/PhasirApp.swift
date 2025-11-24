import SwiftUI

@main
struct PhasirApp: App {
    @StateObject private var service = HouseService(baseURL: URL(string: "http://localhost:4000")!)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(service)
        }
    }
}
