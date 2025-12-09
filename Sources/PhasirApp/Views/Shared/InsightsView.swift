import SwiftUI
import Charts

/// TradingView-artige Insights für Phasir
/// Dunkles, verbundenes Layout + Investment-KI für Wertsteigerung & Energiekosten.
struct InsightsView: View {
    @ObservedObject var viewModel: HouseListViewModel

    // MARK: - Lokale Modelle

    /// Vorhersage eines Wertes pro Jahr (Baseline vs. mit Invest)
    struct ValuePrediction: Identifiable {
        let id = UUID()
        let year: Int
        let baseline: Double
        let improved: Double
    }

    /// Antwortstruktur des /ai/investment-advice Endpoints
    struct InvestmentAdviceResponse: Decodable {
        struct Suggestion: Identifiable, Decodable {
            let id = UUID()
            let name: String
            let description: String
            let type: String?
            let cost: Double?
            let estimatedValueIncrease: Double?
            let estimatedAnnualSavings: Double?
            let paybackYears: Double?
            let roi10Y: Double?

            private enum CodingKeys: String, CodingKey {
                case name, description, type, cost, estimatedValueIncrease, estimatedAnnualSavings, paybackYears, roi10Y
            }
        }

        let houseId: String?
        let summary: String?
        let suggestions: [Suggestion]

        private enum CodingKeys: String, CodingKey {
            case houseId, summary, suggestions
        }
    }

    /// Auswahl: Gesamt-Portfolio oder einzelnes Haus
    @State private var selectedIndex: Int = 0 // 0 = Portfolio, sonst 1...n = Hausindex + 1

    // Wert-Projektion
    @State private var predictions: [ValuePrediction] = []
    @State private var baselineValue10Y: Double = 0
    @State private var improvedValue10Y: Double = 0
    @State private var deltaValue10Y: Double = 0

    // Investment-KI
    @State private var investmentAdviceByHouseId: [String: InvestmentAdviceResponse] = [:]
    @State private var isLoadingInvestmentForHouseId: String?
    @State private var investmentError: String?

    // Lifecycle
    @State private var hasAppeared: Bool = false

    // MARK: - Farben nur für Insights (TradingView-Style)

    private enum InsightsColors {
        static let background = Color(red: 0.03, green: 0.04, blue: 0.08)       // Tab-Hintergrund
        static let card       = Color(red: 0.10, green: 0.12, blue: 0.20)       // große Karte
        static let section    = Color(red: 0.14, green: 0.16, blue: 0.24)       // kleine Section-Boxen
        static let border     = Color.white.opacity(0.08)
        static let subtleText = Color.white.opacity(0.65)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            InsightsColors.background.ignoresSafeArea()

            if houses.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        selectionChips
                        mainCard
                    }
                    .padding(.horizontal, PhasirDesign.screenPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 16)
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: hasAppeared)
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .task {
            // Houses & Benchmarks laden
            if viewModel.houses.isEmpty {
                await viewModel.load()
            }
            await viewModel.loadRentBenchmark()

            // Erste Auswahl initial berechnen
            await recalcForCurrentSelection()
            hasAppeared = true
        }
        .onChange(of: selectedIndex) { _ in
            Task {
                await recalcForCurrentSelection()
            }
        }
    }

    // MARK: - Convenience

    private var houses: [House] {
        viewModel.houses
    }

    /// Aktuell gewähltes Haus (für die KI); bei Portfolio Auswahl -> erstes Haus
    private var currentHouse: House? {
        guard !houses.isEmpty else { return nil }
        if selectedIndex <= 0 { return houses.first }
        let idx = selectedIndex - 1
        guard houses.indices.contains(idx) else { return houses.first }
        return houses[idx]
    }

    /// Titel (Portfolio oder Hausname)
    private var selectionTitle: String {
        if selectedIndex == 0 {
            return "Portfolio gesamt"
        } else if let house = currentHouse {
            return house.name
        } else {
            return "Auswahl"
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.phasirAccent, Color.phasirAccent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Phasir Insights")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("Wertentwicklung, Energie-Upgrade und Investment-Tipps wie in einer Trading-App.")
                    .font(.system(size: 13))
                    .foregroundColor(InsightsColors.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - Auswahl Portfolio / Häuser

    private var selectionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(
                    title: "Portfolio",
                    isSelected: selectedIndex == 0
                ) {
                    selectedIndex = 0
                }

                ForEach(Array(houses.enumerated()), id: \.1.id) { index, house in
                    chip(
                        title: house.name,
                        isSelected: selectedIndex == index + 1
                    ) {
                        selectedIndex = index + 1
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? Color.phasirAccent
                        : InsightsColors.section
                    )
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : InsightsColors.border, lineWidth: 1)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hauptkarte (TradingView-Style)

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Kopfzeile der Karte
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Prognostizierte Wertentwicklung der nächsten 10 Jahre.")
                        .font(.system(size: 12))
                        .foregroundColor(InsightsColors.subtleText)
                }
                Spacer()

                if let house = currentHouse {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Objekt-Wert")
                            .font(.system(size: 11))
                            .foregroundColor(InsightsColors.subtleText)
                        Text(formatCurrency(purchasePrice(for: house)))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }

            // Chart
            valueChart

            // KPI-Reihe unter dem Chart
            kpiRow

            // Investment-KI-Sektion
            investmentSection
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(InsightsColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(InsightsColors.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 18)
        )
    }

    // MARK: - Chart

    private var valueChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Wert-Projektion (10 Jahre)", systemImage: "sparkline")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Spacer()

                HStack(spacing: 12) {
                    legendDot(color: Color.white.opacity(0.8), label: "Baseline")
                    legendDot(color: Color.phasirAccent, label: "Mit Sanierung")
                }
            }

            if predictions.isEmpty {
                Text("Zu wenig Daten, um eine Projektion zu berechnen. Hinterlege Kaufpreise bei deinen Objekten.")
                    .font(.system(size: 12))
                    .foregroundColor(InsightsColors.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } else {
                Chart(predictions) { pred in
                    LineMark(
                        x: .value("Jahr", pred.year),
                        y: .value("Baseline", pred.baseline)
                    )
                    .foregroundStyle(Color.white.opacity(0.6))

                    LineMark(
                        x: .value("Jahr", pred.year),
                        y: .value("Verbessert", pred.improved)
                    )
                    .foregroundStyle(Color.phasirAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine()
                            .foregroundStyle(InsightsColors.border)
                        AxisValueLabel {
                            if let year = value.as(Int.self) {
                                Text("+\(year)J")
                                    .font(.system(size: 11))
                            }
                        }
                        .foregroundStyle(InsightsColors.subtleText)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(InsightsColors.border.opacity(0.8))
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(shortCurrency(number))
                                    .font(.system(size: 11))
                            }
                        }
                        .foregroundStyle(InsightsColors.subtleText)
                    }
                }
                .frame(height: 220)
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(InsightsColors.subtleText)
        }
    }

    // MARK: - KPI-Reihe

    private var kpiRow: some View {
        HStack(spacing: 14) {
            kpiBox(
                title: "Aktueller Wert",
                value: baselineValue10Y == 0 && improvedValue10Y == 0
                    ? "–"
                    : (predictions.first.map { formatCurrency($0.baseline) } ?? "–")
            )

            kpiBox(
                title: "Wert in 10 Jahren",
                value: baselineValue10Y == 0 ? "–" : formatCurrency(baselineValue10Y),
                subtitle: "ohne Invest"
            )

            let delta = deltaValue10Y
            let sign = delta >= 0 ? "+" : "–"
            let absDelta = abs(delta)

            kpiBox(
                title: "Mit Sanierung",
                value: improvedValue10Y == 0 ? "–" : formatCurrency(improvedValue10Y),
                subtitle: deltaValue10Y == 0 ? nil : "\(sign)\(formatCurrency(absDelta)) vs. Baseline",
                highlight: delta > 0
            )
        }
        .padding(.top, 4)
    }

    private func kpiBox(
        title: String,
        value: String,
        subtitle: String? = nil,
        highlight: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(InsightsColors.subtleText)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(highlight ? Color.phasirAccent : .white)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(InsightsColors.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(InsightsColors.section)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(InsightsColors.border, lineWidth: 1)
                )
        )
    }

    // MARK: - Investment-KI Sektion

    private var investmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 15, weight: .semibold))
                Text("Investment-KI")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()

                if let house = currentHouse,
                   isLoadingInvestmentForHouseId == house.id {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .foregroundColor(.white)

            if let house = currentHouse,
               let advice = investmentAdviceByHouseId[house.id] {
                if let summary = advice.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundColor(InsightsColors.subtleText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if advice.suggestions.isEmpty {
                    Text("Für dieses Objekt konnten keine sinnvollen Maßnahmen identifiziert werden.")
                        .font(.system(size: 12))
                        .foregroundColor(InsightsColors.subtleText)
                } else {
                    VStack(spacing: 10) {
                        ForEach(advice.suggestions) { suggestion in
                            suggestionRow(suggestion)
                        }
                    }
                    .padding(.top, 4)
                }
            } else if let error = investmentError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.8))
            } else {
                Text("Wähle ein Objekt, damit Phasir dir konkrete Maßnahmen mit Wert- und Energie-Effekt vorschlägt.")
                    .font(.system(size: 12))
                    .foregroundColor(InsightsColors.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(InsightsColors.section)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(InsightsColors.border, lineWidth: 1)
                )
        )
    }

    private func suggestionRow(_ s: InvestmentAdviceResponse.Suggestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(s.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                if let type = s.type, !type.isEmpty {
                    Text(type.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(
                            Capsule()
                                .fill(Color.phasirAccent.opacity(0.16))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.phasirAccent.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundColor(Color.phasirAccent)
                }

                Spacer()
            }

            if !s.description.isEmpty {
                Text(s.description)
                    .font(.system(size: 11))
                    .foregroundColor(InsightsColors.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 14) {
                if let cost = s.cost {
                    miniMetric(title: "Invest", value: formatCurrency(cost))
                }
                if let inc = s.estimatedValueIncrease {
                    miniMetric(title: "Wert-Boost", value: formatCurrency(inc))
                }
                if let savings = s.estimatedAnnualSavings {
                    miniMetric(title: "Ersparnis/Jahr", value: formatCurrency(savings))
                }
            }

            HStack(spacing: 14) {
                if let payback = s.paybackYears, payback.isFinite {
                    miniMetric(title: "Amortisation", value: String(format: "%.1f J.", payback))
                }
                if let roi = s.roi10Y {
                    let percent = roi * 100
                    let signColor: Color = percent >= 0 ? Color.phasirAccent : .red.opacity(0.8)
                    miniMetric(title: "ROI (10J)", value: String(format: "%.0f %%", percent), color: signColor)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(InsightsColors.background.opacity(0.7))
        )
    }

    private func miniMetric(title: String, value: String, color: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(InsightsColors.subtleText)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.phasirAccent.opacity(0.9))

            Text("Noch keine Daten")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("Lege zuerst mindestens eine Immobilie an, um Portfolio-Insights, Wertentwicklung und Investment-Tipps zu sehen.")
                .font(.system(size: 13))
                .foregroundColor(InsightsColors.subtleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Logik: Werte & KI Laden

    /// Rechnet Chart + lädt KI für die aktuelle Auswahl
    private func recalcForCurrentSelection() async {
        computePredictions()

        guard let house = currentHouse else { return }
        await loadInvestmentAdviceIfNeeded(for: house)
    }

    private func computePredictions() {
        predictions.removeAll()
        baselineValue10Y = 0
        improvedValue10Y = 0
        deltaValue10Y = 0

        let baseValue: Double

        if selectedIndex == 0 {
            // Portfolio: Summe aller Kaufpreise
            baseValue = houses.reduce(0) { $0 + (purchasePrice(for: $1)) }
        } else if let house = currentHouse {
            baseValue = purchasePrice(for: house)
        } else {
            baseValue = 0
        }

        guard baseValue > 0 else { return }

        // Baseline: 2 % p.a. Wertsteigerung
        let baselineGrowth: Double = 0.02

        // Investment-Boost aus bester KI-Empfehlung (falls vorhanden)
        let boost: Double
        if let house = currentHouse,
           let advice = investmentAdviceByHouseId[house.id] {
            let best = advice.suggestions.compactMap { $0.estimatedValueIncrease }.max() ?? 0
            boost = best
        } else {
            boost = 0
        }

        var result: [ValuePrediction] = []

        for year in 0...10 {
            let baseline = baseValue * pow(1.0 + baselineGrowth, Double(year))

            // Boost linear bis Jahr 10 einlaufen lassen, damit die Kurve „realistisch“ wirkt
            let factor = Double(year) / 10.0
            let improved = baseline + boost * factor

            result.append(ValuePrediction(year: year, baseline: baseline, improved: improved))
        }

        predictions = result
        baselineValue10Y = result.last?.baseline ?? 0
        improvedValue10Y = result.last?.improved ?? 0
        deltaValue10Y = improvedValue10Y - baselineValue10Y
    }

    private func purchasePrice(for house: House) -> Double {
        house.purchasePrice ?? 0
    }

    /// Holt Investment-Advice vom Backend, aber nur einmal pro Haus (Caching)
    private func loadInvestmentAdviceIfNeeded(for house: House) async {
        if investmentAdviceByHouseId[house.id] != nil {
            return
        }

        isLoadingInvestmentForHouseId = house.id
        investmentError = nil

        defer {
            if isLoadingInvestmentForHouseId == house.id {
                isLoadingInvestmentForHouseId = nil
            }
        }

        do {
            guard let url = URL(string: "https://phasir-fullstack-production.up.railway.app/ai/investment-advice") else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = ["houseId": house.id]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                throw NSError(domain: "InvestmentAdvice", code: http.statusCode, userInfo: nil)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let advice = try decoder.decode(InvestmentAdviceResponse.self, from: data)

            investmentAdviceByHouseId[house.id] = advice

            // nach neuem Advice nochmal Kurve neu rechnen (Boost)
            computePredictions()
        } catch {
            print("❌ Investment-KI Request fehlgeschlagen:", error)
            investmentError = "Investment-KI konnte nicht geladen werden."
        }
    }

    // MARK: - Format Helper

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "€\(Int(value))"
    }

    /// Kürzere Darstellung im Chart (z. B. 250.000 € → 250k)
    private func shortCurrency(_ value: Double) -> String {
        let absVal = abs(value)

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0

        if absVal >= 1_000_000 {
            let millions = value / 1_000_000
            let formatted = String(format: "%.1f", millions)
            return "\(formatted) Mio."
        } else if absVal >= 1_000 {
            let thousands = value / 1_000
            let formatted = String(format: "%.0f", thousands)
            return "\(formatted)k"
        } else {
            return formatter.string(from: NSNumber(value: value)) ?? "€\(Int(value))"
        }
    }
}
