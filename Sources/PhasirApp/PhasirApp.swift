import SwiftUI

@main
struct PhasirApp: App {
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Deine eigentliche App
                ContentView()
                    .opacity(showLaunchScreen ? 0 : 1)

                // Launch / Loading Screen oben drüber
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Dauer des Loading Screens (1,2 Sekunden + 0,4s Fade)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
}
