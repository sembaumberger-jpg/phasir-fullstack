import SwiftUI

/// Tab‑Ansicht für den Problem‑Solver.
///
/// Diese Ansicht bietet einen klaren Einstieg in die Problemlösung, inklusive
/// Erläuterung, einer übersichtlichen Hilfesektion und einer Liste der vorhandenen
/// Immobilien. Wenn der Nutzer keine Häuser angelegt hat, wird ein
/// sinnvoller Leere‑Zustand angezeigt.
struct ProblemSolverTabView: View {
    /// ViewModel, das die Liste der Häuser sowie weitere Daten liefert.
    @ObservedObject var viewModel: HouseListViewModel

    /// Initialisiert den Solver‑Tab mit einem gegebenen ViewModel.
    init(viewModel: HouseListViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    helperSection

                    if viewModel.houses.isEmpty {
                        emptyState
                    } else {
                        houseList
                    }

                    Spacer(minLength: 24)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Solver")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Beim ersten Öffnen die Hausdaten laden.
            await viewModel.load()
        }
    }

    // MARK: - Header
    /// Überschrift und Untertitel für den Solver‑Tab
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Problem‑Solver")
                .font(.phasirSectionTitle)

            Text("Beschreibe ein Problem in einer deiner Immobilien – Phasir hilft dir bei Einschätzung, Risiko und nächsten Schritten.")
                .font(.phasirCaption)
                .foregroundColor(.phasirSecondaryText)
        }
        .padding(.horizontal, PhasirDesign.screenPadding)
    }

    // MARK: - Helper‑Sektion
    /// Zeigt mehrere Zeilen mit Informationen, was der Solver leisten kann.
    private var helperSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Was du hier machen kannst")
                .font(.system(size: 15, weight: .semibold))

            VStack(spacing: 10) {
                helperRow(
                    icon: "drop.triangle",
                    title: "Wasserschäden & Feuchtigkeit",
                    subtitle: "Tropfende Leitungen, nasse Flecken, Schimmel – früh erkannt, bevor es teuer wird."
                )
                helperRow(
                    icon: "flame.fill",
                    title: "Heizung & Warmwasser",
                    subtitle: "Ausfälle, seltsame Geräusche oder hohe Verbräuche einschätzen lassen."
                )
                helperRow(
                    icon: "house.lodge",
                    title: "Dach, Fenster & Hülle",
                    subtitle: "Sturm, Hagel oder Zugluft – Risiken und sinnvolle Maßnahmen verstehen."
                )
            }
        }
        .padding(.horizontal, PhasirDesign.screenPadding)
    }

    /// Baut eine einzelne Hilfereihe aus Icon, Titel und Untertitel.
    private func helperRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.phasirCard)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.phasirAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.phasirSecondaryText)
            }
            Spacer()
        }
    }

    // MARK: - Leere State
    /// Zeigt einen Hinweis, wenn keine Immobilien vorhanden sind.
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundColor(.phasirAccent.opacity(0.9))
            Text("Noch keine Immobilie angelegt")
                .font(.system(size: 17, weight: .semibold))
            Text("Lege zuerst eine Immobilie im Tab 'Objekte' an, um Probleme gezielt zu analysieren.")
                .font(.system(size: 13))
                .foregroundColor(.phasirSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.horizontal, PhasirDesign.screenPadding)
    }

    // MARK: - Liste der Häuser
    /// Zeigt eine Liste von Karten für alle vorhandenen Häuser.
    private var houseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In welcher Immobilie gibt es ein Problem?")
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, PhasirDesign.screenPadding)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.houses) { house in
                    NavigationLink {
                        ProblemSolverView(house: house)
                    } label: {
                        houseCard(house)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PhasirDesign.screenPadding)
        }
    }

    /// Baut eine Karte für ein einzelnes Haus.
    private func houseCard(_ house: House) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(house.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            // Adresse, falls vorhanden und nicht leer
            let address = house.address.trimmingCharacters(in: .whitespacesAndNewlines)
            if !address.isEmpty {
                Text(address)
                    .font(.system(size: 13))
                    .foregroundColor(.phasirSecondaryText)
            }

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.phasirAccent)
                Text("Problem in dieser Immobilie analysieren")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.phasirAccent)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.phasirCard)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }
}
