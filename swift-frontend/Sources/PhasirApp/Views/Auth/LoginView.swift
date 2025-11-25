import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "house.lodge.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.gray)
                Text("Phasir")
                    .font(.largeTitle.weight(.semibold))
                Text("Immobilien & Wartung")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("E-Mail").font(.caption).foregroundStyle(.secondary)
                    TextField("name@example.com", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Passwort").font(.caption).foregroundStyle(.secondary)
                    SecureField("••••••••", text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: login) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                        }
                        Text("Anmelden").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.label)))
                    .foregroundColor(.white)
                }
                .disabled(viewModel.isLoading)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6)))

            VStack(spacing: 8) {
                Button("Registrieren") {}
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Button("Passwort vergessen?") {}
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color(.systemGray6).ignoresSafeArea())
    }

    private func login() {
        Task { await viewModel.login() }
    }
}
