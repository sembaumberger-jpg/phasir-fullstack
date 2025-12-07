import SwiftUI

/// Anzeige der prognostizierten Probleme für alle Häuser eines Nutzers.
/// Diese View zeigt pro Haus eine Liste potenzieller Wartungs- und Reparaturrisiken an.
struct ProblemRadarView: View {
    @StateObject var viewModel: ProblemRadarViewModel

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                ForEach(viewModel.houses) { radar in
                    Section(header: Text(radar.name).font(.phasirSectionTitle)) {
                        if radar.issues.isEmpty {
                            Text("Keine Risiken erkannt")
                                .font(.phasirCaption)
                                .foregroundColor(.gray)
                        } else {
                            ForEach(radar.issues) { issue in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(issue.summary)
                                        .font(.phasirBody.weight(.semibold))
                                    Text(issue.recommendation)
                                        .font(.phasirCaption)
                                        .foregroundColor(Color.phasirSecondaryText)
                                    HStack {
                                        Text(issue.system.capitalized)
                                        Spacer()
                                        Text(issue.severity.capitalized)
                                    }
                                    .font(.phasirCaption)
                                    .foregroundColor(color(for: issue.severity))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Problem Radar")
        .onAppear {
            Task { await viewModel.load() }
        }
    }

    /// Farbe je nach Schweregrad
    private func color(for severity: String) -> Color {
        switch severity.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }
}
