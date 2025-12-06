import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Hintergrundbild wie beim Login/Registrieren
            Image("HouseLogin")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // dezenter dunkler Overlay für bessere Lesbarkeit
            LinearGradient(
                colors: [
                    Color.black.opacity(0.45),
                    Color.black.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                // Phasir-Schriftzug in deiner Menlo-Bold-Font
                Text("Phasir")
                    .font(.custom("Menlo-Bold", size: 34))
                    .foregroundColor(.white)

                Text("Dein Operating System für Immobilien")
                    .font(.phasirCaption)
                    .foregroundColor(Color.phasirSecondaryText.opacity(0.9))
            }
        }
    }
}
