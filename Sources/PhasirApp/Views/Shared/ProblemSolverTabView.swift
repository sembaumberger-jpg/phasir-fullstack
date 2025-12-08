import SwiftUI

/// Dashboard‑Ansicht für den Problem‑Solver.
/// Diese View füllt den Tab mit mehreren Sektionen:
/// 1. Überschrift mit kurzer Erläuterung
/// 2. Schnellzugriff auf häufige Kategorien (Dekoration)
/// 3. Liste der Häuser des Nutzers mit Standort‑basierten Warnungen
///
/// Der `houseService` wird separat übergeben, damit Wetterwarnungen für jedes Haus
/// geladen werden können. Beim ersten Erscheinen wird versucht, die Wetterwarnungen
/// für alle Häuser zu laden.
struct ProblemSolverTabView: View {
    /// Liste aller Häuser und allgemeine Daten
    @ObservedObject var viewModel: HouseListViewModel
    /// Service zum Laden von Wetterwarnungen
    let houseService: HouseService

    /// Definiert die Kategorien für den Schnellzugriff. Diese sind vorerst dekorativ.
    private struct Category: Identifiable {
        let id: String
        let title: String
        let icon: String
        let color: Color
    }
    private let categories: [Category] = [
        .init(id: "heating", title: "Heizung", icon: "flame.fill", color: .orange),
        .init(id: "water", title: "Wasser", icon: "drop.fill", color: .blue),
        .init(id: "roof", title: "Dach", icon: "house.lodge.fill", color: .brown),
        .init(id: "electric", title: "Elektrik", icon: "bolt.fill", color: .yellow),
        .init(id: "humidity", title: "Schimmel", icon: "aqi.medium", color: .green),
        .init(id: "energy", title: "Energie", icon: "leaf.fill", color: .green)
    ]

    /// Um mehrfaches Laden zu vermeiden, merken wir uns, für welche Häuser
    /// die Wetterwarnungen bereits angefordert wurden.
    @State private var loadedHouseIds: Set<String> = []

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    categoriesSection
                    housesSection
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Solver")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Initiale Daten laden: Häuser, falls noch nicht vorhanden
            await viewModel.load()
            // Für alle Häuser die Wetterwarnungen abrufen
            for house in viewModel.houses {
                if !loadedHouseIds.contains(house.id) {
                    loadedHouseIds.insert(house.id)
                    await houseService.fetchWeatherAlerts(for: house.id)
                }
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Problem‑Solver")
                .font(.phasirSectionTitle)
            Text("Starte die Diagnostik, erhalte Soforthilfe und aktuelle Warnungen für deine Immobilien.")
                .font(.phasirCaption)
                .foregroundColor(.phasirSecondaryText)
        }
    }

    // MARK: - Kategorien
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellzugriff")
                .font(.system(size: 18, weight: .semibold))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(categories) { category in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: category.icon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(category.color)
                        }
                        Text(category.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.phasirCard)
                    )
                }
            }
        }
    }

    // MARK: - Häuserliste
    private var housesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.houses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "house")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(.phasirAccent.opacity(0.8))
                    Text("Noch keine Immobilien verfügbar")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Lege zunächst ein Objekt an, um die Diagnose und Warnungen nutzen zu können.")
                        .font(.system(size: 13))
                        .foregroundColor(.phasirSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
            } else {
                ForEach(viewModel.houses) { house in
                    NavigationLink {
                        ProblemSolverView(house: house)
                    } label: {
                        houseCard(for: house)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Einzelne Hauskarte mit Wetterwarnungen
    @ViewBuilder
    private func houseCard(for house: House) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hausname + Adresse
            VStack(alignment: .leading, spacing: 4) {
                Text(house.name)
                    .font(.system(size: 16, weight: .semibold))
                if let addr = house.address, !addr.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(addr)
                        .font(.system(size: 13))
                        .foregroundColor(.phasirSecondaryText)
                }
            }
            // Wetterwarnungen
            if let alerts = houseService.weatherAlertsByHouseId[house.id], !alerts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wetterwarnungen")
                        .font(.system(size: 13, weight: .semibold))
                    ForEach(alerts.prefix(2)) { alert in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.headlineDe ?? alert.eventDe ?? "Warnung")
                                .font(.system(size: 13, weight: .semibold))
                            if let event = alert.eventDe {
                                Text(event)
                                    .font(.system(size: 12))
                                    .foregroundColor(.phasirSecondaryText)
                            }
                            HStack(spacing: 4) {
                                Text(severityLabel(alert.severity))
                                if let expires = alert.expires {
                                    Text(expires, style: .time)
                                }
                            }
                            .font(.system(size: 11))
                            .foregroundColor(colorForSeverity(alert.severity))
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.phasirBackground)
                        )
                    }
                }
            } else {
                Text("Keine aktuellen Wetterwarnungen")
                    .font(.system(size: 12))
                    .foregroundColor(.phasirSecondaryText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.phasirCard)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
        // Wenn die Warnungen noch nicht geladen sind, lade sie onAppear
        .task {
            if !loadedHouseIds.contains(house.id) {
                loadedHouseIds.insert(house.id)
                await houseService.fetchWeatherAlerts(for: house.id)
            }
        }
    }

    // MARK: - Hilfsfunktionen für Schweregrad
    private func severityLabel(_ severity: String?) -> String {
        switch severity?.lowercased() {
        case "extreme": return "Sehr extrem"
        case "severe": return "Extrem"
        case "moderate": return "Mittel"
        case "minor": return "Leicht"
        default: return "Unbekannt"
        }
    }

    private func colorForSeverity(_ severity: String?) -> Color {
        switch severity?.lowercased() {
        case "extreme": return .red
        case "severe": return .orange
        case "moderate": return .yellow
        case "minor": return .green
        default: return .gray
        }
    }
}
