import SwiftUI

/// Interaktiver Interview-Flow zur genaueren Problembeschreibung.
/// Führt den Nutzer durch mehrere Fragen und erstellt anschließend eine umfangreichere Diagnose.
struct ProblemInterviewView: View {
    let house: House
    /// Die initiale Problembeschreibung, die vom Nutzer zuvor eingegeben wurde
    let initialDescription: String

    @State private var questions: [String] = [
        "Seit wann besteht das Problem?",
        "Tritt es dauerhaft oder nur gelegentlich auf?",
        "Hat sich das Geräusch oder Symptom verändert?",
        "Gibt es weitere relevante Details, die du mitteilen möchtest?"
    ]
    @State private var answers: [String] = []
    @State private var currentIndex: Int = 0
    @State private var answerText: String = ""
    @State private var isLoading: Bool = false
    @State private var diagnosis: ProblemDiagnosis?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    if let diagnosis = diagnosis {
                        // Ergebnis anzeigen
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: icon(for: diagnosis.category))
                                    .font(.title3)
                                    .foregroundColor(Color.phasirAccent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ergebnis der erweiterten Analyse")
                                        .font(.phasirSectionTitle)
                                    Text(label(for: diagnosis.category))
                                        .font(.phasirCaption)
                                        .foregroundColor(Color.phasirSecondaryText)
                                }
                                Spacer()
                                urgencyBadge(diagnosis.urgency)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ursache")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                                Text(diagnosis.likelyCause)
                                    .font(.phasirBody)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Divider().padding(.vertical, 4)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Empfehlung")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                                Text(diagnosis.recommendedAction)
                                    .font(.phasirBody)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if let steps = diagnosis.firstAidSteps, !steps.isEmpty {
                                Divider().padding(.vertical, 4)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Sofortmaßnahmen")
                                        .font(.phasirCaption)
                                        .foregroundColor(Color.phasirSecondaryText)
                                    ForEach(steps, id: \ .self) { step in
                                        HStack(alignment: .top, spacing: 6) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                                .padding(.top, 2)
                                            Text(step)
                                                .font(.phasirCaption)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                        }
                        .phasirCard()
                    } else {
                        // Interview-Flow
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Frage \(currentIndex + 1) von \(questions.count)")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                            Text(questions[currentIndex])
                                .font(.phasirSectionTitle)
                            TextEditor(text: $answerText)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.phasirCard)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.phasirCardBorder, lineWidth: 1)
                                )
                                .font(.phasirBody)
                            Button {
                                Task { await handleNext() }
                            } label: {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView().scaleEffect(0.9)
                                    } else {
                                        Image(systemName: currentIndex < questions.count - 1 ? "arrow.right" : "checkmark")
                                    }
                                    Text(currentIndex < questions.count - 1 ? "Weiter" : "Abschließen")
                                }
                                .font(.phasirButton)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.phasirAccent)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading || answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .phasirCard()
                    }
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.phasirCaption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Problem-Interview")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Aktionen

    /// Bearbeitet die Eingabe und wechselt zur nächsten Frage oder führt die Diagnose aus
    private func handleNext() async {
        let trimmed = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        answers.append(trimmed)
        answerText = ""
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            await performDiagnosis()
        }
    }

    /// Führt die Diagnose mit den gesammelten Antworten durch
    private func performDiagnosis() async {
        isLoading = true
        errorMessage = nil
        // Kombiniere die initiale Beschreibung mit den Antworten zu einem erweiterten Text
        let extendedDescription = ([initialDescription] + answers).joined(separator: ". ")
        do {
            let result = try await requestDiagnosis(description: extendedDescription)
            await MainActor.run {
                self.diagnosis = result
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        await MainActor.run { self.isLoading = false }
    }

    // MARK: - API-Aufruf
    /// Ruft die Diagnose vom Backend ab (kopiert aus ProblemSolverView)
    private func requestDiagnosis(description: String) async throws -> ProblemDiagnosis {
        var request = URLRequest(
            url: ApiClient.shared.baseURL.appendingPathComponent("ai/problem-diagnosis")
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["houseId": house.id, "description": description]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(ProblemDiagnosis.self, from: data)
    }

    // MARK: - Label & Icon Helpers
    private func label(for category: String) -> String {
        switch category {
        case "heating": return "Heizung"
        case "water": return "Wasser / Sanitär"
        case "plumbing": return "Leitungen / Abfluss"
        case "roof": return "Dach"
        case "electric": return "Strom / Elektrik"
        case "humidity": return "Feuchtigkeit / Schimmel"
        case "energy": return "Energie / Effizienz"
        default: return "Allgemein"
        }
    }
    private func icon(for category: String) -> String {
        switch category {
        case "heating": return "flame.fill"
        case "water": return "drop.fill"
        case "plumbing": return "wrench.adjustable.fill"
        case "roof": return "house.lodge.fill"
        case "electric": return "bolt.fill"
        case "humidity": return "aqi.medium"
        case "energy": return "leaf.fill"
        default: return "questionmark.circle.fill"
        }
    }
    private func urgencyBadge(_ urgency: Int) -> some View {
        let clamped = max(1, min(5, urgency))
        let (text, color): (String, Color) = {
            switch clamped {
            case 5: return ("Sehr hoch", .red)
            case 4: return ("Hoch", .orange)
            case 3: return ("Mittel", .yellow)
            case 2: return ("Niedrig", .green.opacity(0.7))
            default: return ("Sehr niedrig", .green)
            }
        }()
        return Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(999)
    }
}
