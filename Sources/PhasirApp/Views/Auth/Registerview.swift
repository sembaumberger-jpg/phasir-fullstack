import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onLoginTapped: () -> Void

    var body: some View {
        ZStack {
            Image("HouseLogin")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Phasir")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("In wenigen Schritten zu deinem Immobilien-Cockpit.")
                            .font(.phasirCaption)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 60)

                    VStack(alignment: .leading, spacing: 18) {
                        Text("Konto erstellen")
                            .font(.phasirSectionTitle)

                        Text("Registriere dich mit deiner E-Mail-Adresse, um Phasir zu nutzen.")
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
                            Text("Passwort (min. 8 Zeichen)")
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

                        // Register-Button
                        Button {
                            Task {
                                await viewModel.register()
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Konto erstellen")
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

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mit der Registrierung akzeptierst du die Nutzungsbedingungen von Phasir.")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)

                            Button(action: onLoginTapped) {
                                Text("Schon ein Konto? Zum Login")
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
