import SwiftUI

struct HouseListView: View {
    @ObservedObject var viewModel: HouseListViewModel

    @State private var showCreateSheet: Bool = false
    @State private var selectedHouse: House?
    @State private var showOnboarding: Bool = false

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.houses.isEmpty {
                        emptyStateCard

                        Button(action: { showCreateSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.phasirAccent)

                                Text("Erste Immobilie anlegen")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.phasirAccent)

                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.phasirCard)
                                    .shadow(color: .black.opacity(0.03),
                                            radius: 4, x: 0, y: 2)
                            )
                        }
                    } else {
                        ForEach(viewModel.houses) { house in
                            modernHouseCard(house)
                                .onTapGesture { selectedHouse = house }
                        }

                        Button(action: { showCreateSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.phasirAccent)

                                Text("Neue Immobilie hinzufügen")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.phasirAccent)

                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.phasirCard)
                                    .shadow(color: .black.opacity(0.03),
                                            radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                HouseFormView(mode: .create) { req in
                    let ok = await viewModel.createHouse(request: req)
                    if ok { showCreateSheet = false }
                    return ok
                }
            }
        }
        .sheet(item: $selectedHouse) { house in
            NavigationStack {
                HouseDetailView(viewModel: viewModel, house: house)
            }
        }
        .task {
            await viewModel.load()
            if viewModel.houses.isEmpty {
                showOnboarding = true
            }
        }
        .onChange(of: viewModel.houses.count) { newValue in
            if newValue > 0 {
                showOnboarding = false
            }
        }
        .overlay {
            if showOnboarding {
                onboardingOverlay
            }
        }
    }

    // MARK: - Karten

    private func modernHouseCard(_ house: House) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            Image("House")
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(house.name)
                    .font(.system(size: 18, weight: .semibold))

                Text(house.address)
                    .font(.system(size: 14))
                    .foregroundColor(.phasirSecondaryText)

                HStack(spacing: 10) {
                    Label("BJ \(house.buildYear)", systemImage: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.phasirSecondaryText)

                    if let area = house.livingArea {
                        Label("\(area) m²", systemImage: "square.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.phasirSecondaryText)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.phasirCard)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 42))
                .foregroundColor(.phasirAccent)

            Text("Noch keine Immobilien")
                .font(.system(size: 18, weight: .semibold))

            Text("Füge deine erste Immobilie hinzu und starte dein Portfolio.")
                .font(.system(size: 13))
                .foregroundColor(.phasirSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.phasirCard)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Onboarding-Overlay

    private var onboardingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Willkommen bei Phasir")
                    .font(.system(size: 20, weight: .semibold))

                Text("Lege deine erste Immobilie an, um dein persönliches Immobilien-Cockpit zu starten. Danach siehst du in Insights und Home Cashflow, Wartungen und smarte Aktionen.")
                    .font(.system(size: 13))
                    .foregroundColor(.phasirSecondaryText)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    stepRow(number: "1", text: "Adresse & Basisdaten eintragen")
                    stepRow(number: "2", text: "Heizung, Dach, Fenster & Rauchmelder ergänzen")
                    stepRow(number: "3", text: "Miete, Finanzierung & Kosten hinterlegen (optional)")
                }

                Button {
                    showCreateSheet = true
                } label: {
                    Text("Erste Immobilie anlegen")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.phasirAccent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    showOnboarding = false
                } label: {
                    Text("Später")
                        .font(.system(size: 13))
                        .foregroundColor(.phasirSecondaryText)
                }
                .padding(.top, 2)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.phasirCard)
                    .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
        }
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.phasirAccent.opacity(0.12))
                    .frame(width: 22, height: 22)
                Text(number)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.phasirAccent)
            }

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.phasirSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}
