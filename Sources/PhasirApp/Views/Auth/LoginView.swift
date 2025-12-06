import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onRegisterTapped: () -> Void

    var body: some View {
        ZStack {
            // Hintergrund
            Image("HouseLogin")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            // Inhalt
            ScrollView {
                VStack(spacing: 24) {

                    // Branding
                    VStack(spacing: 6) {
                        Text("Phasir")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Dein Operating System für Immobilien.")
                            .font(.phasirCaption)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 60)

                    // Login-Card
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Willkommen zurück")
                            .font(.phasirSectionTitle)

                        Text("Logge dich ein, um dein Immobilien-Cockpit zu öffnen.")
                            .font(.phasirBody)
                            .foregroundColor(Color.phasirSecondaryText)

                        // E-Mail
                        VStack(alignment: .leading, spacing: 6) {
                            Text("E-Mail")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)

                            TextField("name@beispiel.de", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textFieldStylePhasir()
                        }

                        // Passwort
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Passwort")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)

                            SecureField("••••••••", text: $viewModel.password)
                                .textFieldStylePhasir()
                        }

                        // Fehler
                        if let error = viewModel.errorMessage, !error.isEmpty {
                            Text(error)
                                .font(.phasirCaption)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Login-Button
                        Button {
                            Task {
                                await viewModel.login()
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Einloggen")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                (viewModel.isLoading ||
                                 viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                 viewModel.password.isEmpty)
                                ? Color.phasirAccent.opacity(0.6)
                                : Color.phasirAccent
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.phasirAccent.opacity(0.35),
                                    radius: 18, x: 0, y: 8)
                        }
                        .disabled(
                            viewModel.isLoading ||
                            viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            viewModel.password.isEmpty
                        )

                        // Hinweis + Navigation zur Registrierung
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nur Nutzer mit bestehendem Phasir-Account können sich anmelden.")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)

                            Button(action: onRegisterTapped) {
                                Text("Noch kein Konto? Jetzt registrieren")
                                    .font(.phasirCaption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.phasirAccent)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: PhasirDesign.cardCornerRadius, style: .continuous)
                            .fill(Color.phasirCard)
                            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
                    )
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
