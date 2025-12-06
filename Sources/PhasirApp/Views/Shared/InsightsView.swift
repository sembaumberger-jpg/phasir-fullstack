import SwiftUI

struct InsightsView: View {
    @ObservedObject var viewModel: HouseListViewModel
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            if viewModel.houses.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCard
                        mainInsightsBlock
                    }
                    .padding(.horizontal, PhasirDesign.screenPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 14)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.82),
                        value: hasAppeared
                    )
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel.houses.isEmpty {
                await viewModel.load()
            }
            await viewModel.loadRentBenchmark()
        }
        .onAppear {
            hasAppeared = true
        }
    }

    // MARK: - Convenience

    private var houses: [House] {
        viewModel.houses
    }

    /// nur vermietete / gewerbliche Objekte
    private var rentalHouses: [House] {
        houses.filter { house in
            guard let usage = house.usageType?.lowercased() else { return false }
            return usage.contains("vermietet")
                || usage.contains("gewerb")
                || usage.contains("kurzzeit")
        }
    }

    private func monthlyIncome(for house: House) -> Double {
        let warm = house.monthlyRentWarm ?? 0
        let cold = house.monthlyRentCold ?? 0
        return warm > 0 ? warm : cold
    }

    private func monthlyCosts(for house: House) -> Double {
        let credit = house.loanMonthlyPayment ?? 0
        let utilities = house.monthlyUtilities ?? 0
        let hoa = house.monthlyHoaFees ?? 0
        let insurance = (house.insurancePerYear ?? 0) / 12.0
        let maintenance = (house.maintenanceBudgetPerYear ?? 0) / 12.0
        return credit + utilities + hoa + insurance + maintenance
    }

    private func monthlyCashflow(for house: House) -> Double {
        monthlyIncome(for: house) - monthlyCosts(for: house)
    }

    private var totalMonthlyIncome: Double {
        rentalHouses.reduce(0) { $0 + monthlyIncome(for: $1) }
    }

    private var totalMonthlyCosts: Double {
        rentalHouses.reduce(0) { $0 + monthlyCosts(for: $1) }
    }

    private var totalMonthlyCashflow: Double {
        totalMonthlyIncome - totalMonthlyCosts
    }

    private var positiveCashflowCount: Int {
        rentalHouses.filter { monthlyCashflow(for: $0) >= 0 }.count
    }

    private var negativeCashflowCount: Int {
        rentalHouses.filter { monthlyCashflow(for: $0) < 0 }.count
    }

    private var averageGrossYield: Double? {
        let yields = rentalHouses.compactMap { house -> Double? in
            guard
                let rentCold = house.monthlyRentCold,
                rentCold > 0,
                let price = house.purchasePrice,
                price > 0
            else { return nil }

            let annualRent = rentCold * 12.0
            return (annualRent / price) * 100.0
        }

        guard !yields.isEmpty else { return nil }
        let sum = yields.reduce(0, +)
        return sum / Double(yields.count)
    }

    // Donut-Chart-Daten: Einnahmen vs. Kosten
    private var cashflowSlices: [CashSlice] {
        let income = max(totalMonthlyIncome, 0)
        let costs = max(totalMonthlyCosts, 0)
        let total = income + costs
        if total <= 0 { return [] }

        return [
            CashSlice(label: "Einnahmen", value: income, color: Color.phasirAccent),
            CashSlice(label: "Kosten", value: costs, color: Color.gray.opacity(0.45))
        ]
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.phasirAccent.opacity(0.8))

            Text("Noch keine Daten")
                .font(.system(size: 18, weight: .semibold))

            Text("Lege zuerst eine Immobilie an, um Portfolio-Insights zu sehen.")
                .font(.system(size: 14))
                .foregroundColor(Color.phasirSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.phasirAccent, Color.phasirAccent.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "waveform.path.ecg.rectangle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Phasir Insights")
                        .font(.system(size: 17, weight: .semibold))

                    Text("Verdichteter Überblick über Zustand, Cashflow & Risiko deines Portfolios.")
                        .font(.system(size: 13))
                        .foregroundColor(Color.phasirSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    StatusChip(icon: "bolt.badge.a", title: "KI-Auswertung")
                    StatusChip(icon: "eurosign.circle", title: "Cashflow")
                    StatusChip(icon: "checkmark.shield", title: "Risiko")
                    StatusChip(icon: "wrench.and.screwdriver", title: "Wartungen")
                }
                .padding(.top, 2)
            }
        }
        .phasirCard()
    }

    // MARK: - Hauptblock (ein Card, mit Trennlinien)

    private var mainInsightsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio-Überblick")
                .font(.system(size: 18, weight: .semibold))

            Text("Die wichtigsten Kennzahlen deines Immobilien-Portfolios in einem ruhigen, klaren Layout.")
                .font(.system(size: 13))
                .foregroundColor(Color.phasirSecondaryText)

            VStack(spacing: 0) {
                // 1) Bestands- & Wartungsübersicht
                portfolioSection

                dividerLine

                // 2) Cashflow & Rendite (inkl. Donut-Chart)
                financeSection

                dividerLine

                // 3) Markt & Mieten
                marketSection

                dividerLine

                // 4) Risiko & Wartungen
                riskAndMaintenanceSection
            }
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.phasirCard)
                    .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 10)
            )
        }
    }

    private var dividerLine: some View {
        Divider()
            .padding(.leading, 16)
            .padding(.trailing, 16)
    }

    // MARK: - Unter-Sektionen im Block

    // 1) Portfolio / Bestand

    private var portfolioSection: some View {
        let houseCount = houses.count
        let avgEnergy = averageEnergyScore
        let avgSecurity = averageSecurityScore
        let upcoming90 = upcomingMaintenanceCount(inDays: 90)
        let upcoming365 = upcomingMaintenanceCount(inDays: 365)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Bestand & Zustand")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(houseCount) Objekt\(houseCount == 1 ? "" : "e")")
                    .font(.system(size: 12))
                    .foregroundColor(Color.phasirSecondaryText)
            }

            HStack(spacing: 12) {
                StatPill(
                    title: "Wartungen (90 Tage)",
                    value: "\(upcoming90)",
                    subtitle: "Kurzfristig fällig",
                    tint: Color.phasirCard.opacity(0.9),
                    accent: .primary
                )

                StatPill(
                    title: "Wartungen (12 Monate)",
                    value: "\(upcoming365)",
                    subtitle: "Planungshorizont",
                    tint: Color.phasirCard.opacity(0.9),
                    accent: .primary
                )
            }

            HStack(spacing: 12) {
                StatPill(
                    title: "Ø Energie-Score",
                    value: avgEnergy.map { String(format: "%.0f", $0) } ?? "–",
                    subtitle: avgEnergyLabel?.text ?? "Noch zu wenig Daten",
                    tint: Color.phasirCard.opacity(0.9),
                    accent: .primary
                )

                StatPill(
                    title: "Ø Sicherheits-Score",
                    value: avgSecurity.map { String(format: "%.0f", $0) } ?? "–",
                    subtitle: avgSecurityLabel?.text ?? "Noch zu wenig Daten",
                    tint: Color.phasirCard.opacity(0.9),
                    accent: .primary
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    // 2) Finance (mit Donut)

    private var financeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cashflow & Rendite")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if !rentalHouses.isEmpty {
                    Text("\(rentalHouses.count) Ertrags-Objekt\(rentalHouses.count == 1 ? "" : "e")")
                        .font(.system(size: 12))
                        .foregroundColor(Color.phasirSecondaryText)
                }
            }

            if rentalHouses.isEmpty {
                Text("Hinterlege Miete, Finanzierung und Kosten bei mindestens einem Objekt, um Cashflow zu berechnen.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.phasirSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(spacing: 12) {
                    StatPill(
                        title: "Einnahmen",
                        value: formatCurrency(totalMonthlyIncome),
                        subtitle: "pro Monat",
                        tint: Color.phasirCard.opacity(0.9),
                        accent: .primary
                    )

                    StatPill(
                        title: "Kosten",
                        value: formatCurrency(totalMonthlyCosts),
                        subtitle: "pro Monat",
                        tint: Color.phasirCard.opacity(0.9),
                        accent: .primary
                    )
                }

                // Donut-Chart: Einnahmen vs. Kosten
                if !cashflowSlices.isEmpty {
                    HStack(spacing: 16) {
                        DonutChartView(slices: cashflowSlices)
                            .frame(width: 110, height: 110)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(cashflowSlices) { slice in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(slice.color)
                                        .frame(width: 10, height: 10)

                                    Text(slice.label)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.phasirSecondaryText)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.top, 4)
                }

                let cfColor: Color = totalMonthlyCashflow >= 0 ? .green : .red

                VStack(alignment: .leading, spacing: 4) {
                    Text("Netto-Cashflow (vor Steuern)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.phasirSecondaryText)

                    Text(formatCurrency(totalMonthlyCashflow))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(cfColor)   // einzige farbige Zahl

                    Text(
                        totalMonthlyCashflow >= 0
                        ? "Dein Portfolio arbeitet aktuell positiv."
                        : "Dein Portfolio verbrennt aktuell monatlich Liquidität."
                    )
                    .font(.system(size: 12))
                    .foregroundColor(Color.phasirSecondaryText)
                }
                .padding(.top, 4)

                if let avgYield = averageGrossYield {
                    Text(String(format: "Ø Bruttorendite: %.1f %%", avgYield))
                        .font(.system(size: 12))
                        .foregroundColor(Color.phasirSecondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // 3) Markt & Mieten

    private func colorForRating(_ rating: String) -> Color {
        // nur noch für minimale Akzente, aber nicht als Fläche
        switch rating.lowercased() {
        case "unter markt": return .green
        case "über markt":  return .red
        case "im rahmen":   return .orange
        default:            return Color.phasirAccent
        }
    }

    private var marketSection: some View {
        let advice = viewModel.rentBenchmarkAdvice()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mietniveau & Markt")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if viewModel.isLoadingRentBenchmark {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button {
                        Task { await viewModel.loadRentBenchmark() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.phasirAccent)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.isLoadingRentBenchmark {
                Text("Marktdaten werden aktualisiert …")
                    .font(.system(size: 12))
                    .foregroundColor(Color.phasirSecondaryText)
            } else if let advice = advice {
                let p = advice.portfolio

                HStack(spacing: 12) {
                    StatPill(
                        title: "Portfolio-Rating",
                        value: p.rating,
                        subtitle: nil,
                        tint: Color.phasirCard.opacity(0.9),
                        accent: .primary
                    )

                    StatPill(
                        title: "Ø Miete/m²",
                        value: formatCurrencyPerSqm(p.averageRentPerSqm),
                        subtitle: "Portfolio",
                        tint: Color.phasirCard.opacity(0.9),
                        accent: .primary
                    )

                    StatPill(
                        title: "Ø Markt",
                        value: formatCurrencyPerSqm(p.estimatedMarketRentPerSqm),
                        subtitle: nil,
                        tint: Color.phasirCard.opacity(0.9),
                        accent: .primary
                    )
                }

                if let dev = p.averageDeviationPercent {
                    Text(
                        dev >= 0
                        ? "Im Schnitt liegst du rund \(formatPercent(dev)) über dem geschätzten Marktniveau."
                        : "Im Schnitt liegst du rund \(formatPercent(dev)) unter dem geschätzten Marktniveau."
                    )
                    .font(.system(size: 12))
                    .foregroundColor(Color.phasirSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(p.summary)
                        .font(.system(size: 12))
                        .foregroundColor(Color.phasirSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Hinterlege Wohnfläche und Kaltmiete bei mindestens einem Objekt, um dein Mietniveau mit dem Markt zu vergleichen.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.phasirSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // 4) Risiko & Wartung

    private var riskAndMaintenanceSection: some View {
        let grades = energyAndSecurityGrades
        let topMaint = upcomingMaintenanceItems(limit: 3)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Risiko & Wartungen")
                .font(.system(size: 14, weight: .semibold))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Energie")
                        .font(.system(size: 12))
                        .foregroundColor(Color.phasirSecondaryText)

                    HStack(spacing: 6) {
                        RiskBadge(label: "A/B", count: grades.energy.good)
                        RiskBadge(label: "C", count: grades.energy.medium)
                        RiskBadge(label: "D", count: grades.energy.bad, isCritical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sicherheit")
                        .font(.system(size: 12))
                        .foregroundColor(Color.phasirSecondaryText)

                    HStack(spacing: 6) {
                        RiskBadge(label: "A/B", count: grades.security.good)
                        RiskBadge(label: "C", count: grades.security.medium)
                        RiskBadge(label: "D", count: grades.security.bad, isCritical: true)
                    }
                }
            }

            if topMaint.isEmpty {
                Text("Aktuell sind keine dringenden Wartungen sichtbar – behalte trotzdem Intervalle und Herstellervorgaben im Blick.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.phasirSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(topMaint.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .strokeBorder(Color.phasirAccent.opacity(0.35), lineWidth: 1)
                                .background(
                                    Circle()
                                        .fill(Color.phasirCard.opacity(0.9))
                                )
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "wrench.and.screwdriver")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color.phasirAccent)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.houseName)
                                    .font(.system(size: 12, weight: .semibold))

                                Text("\(item.component) – \(formatted(item.date))")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.phasirSecondaryText)

                                Text(item.status.text)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .padding(.bottom, 12)
    }

    // MARK: - Scores & Wartung

    private func energyScore(for house: House) -> Int {
        var score = 50

        switch house.windowGlazing?.lowercased() {
        case "dreifach":
            score += 15
        case "zweifach":
            score += 5
        case "einfach":
            score -= 10
        default:
            break
        }

        if let insulation = house.insulationLevel?.lowercased() {
            if insulation.contains("kfw") || insulation.contains("gut") {
                score += 15
            } else if insulation.contains("unsaniert") {
                score -= 15
            }
        }

        if house.hasSolarPanels == true {
            score += 10
        }

        if house.buildYear < 1980 {
            score -= 10
        } else if house.buildYear > 2005 {
            score += 5
        }

        return max(0, min(100, score))
    }

    private func securityScore(for house: House) -> Int {
        var score = 40

        if let door = house.doorSecurityLevel?.lowercased() {
            if door.contains("sicherheit") || door.contains("mehrpunkt") {
                score += 15
            }
        }

        if house.hasGroundFloorWindowSecurity == true { score += 10 }
        if house.hasAlarmSystem == true { score += 15 }
        if house.hasCameras == true { score += 10 }
        if house.hasMotionLightsOutside == true { score += 5 }
        if house.hasSmokeDetectorsAllRooms == true { score += 5 }
        if house.hasCO2Detector == true { score += 5 }

        if let risk = house.neighbourhoodRiskLevel?.lowercased() {
            if risk.contains("hoch") {
                score -= 10
            } else if risk.contains("niedrig") {
                score += 5
            }
        }

        return max(0, min(100, score))
    }

    private var averageEnergyScore: Double? {
        let scores = houses.map(energyScore(for:))
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    private var averageSecurityScore: Double? {
        let scores = houses.map(securityScore(for:))
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    private var avgEnergyLabel: ScoreLabel? {
        guard let avg = averageEnergyScore else { return nil }
        return labelForScore(avg)
    }

    private var avgSecurityLabel: ScoreLabel? {
        guard let avg = averageSecurityScore else { return nil }
        return labelForScore(avg)
    }

    private func labelForScore(_ score: Double) -> ScoreLabel {
        switch score {
        case 80...100:
            return ScoreLabel(text: "Sehr gut", color: .green, hint: nil)
        case 60..<80:
            return ScoreLabel(text: "Gut", color: .green, hint: nil)
        case 40..<60:
            return ScoreLabel(text: "Mittel", color: .orange, hint: nil)
        default:
            return ScoreLabel(text: "Kritisch", color: .red, hint: nil)
        }
    }

    private func upcomingMaintenanceCount(inDays days: Int) -> Int {
        let today = Date()
        let target = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        return houses.flatMap { house -> [Date] in
            [
                house.next?.heating,
                house.next?.roof,
                house.next?.windows,
                house.next?.smoke
            ].compactMap { $0 }
        }
        .filter { $0 >= today && $0 <= target }
        .count
    }

    private func upcomingMaintenanceItems(limit: Int) -> [(houseName: String, component: String, date: Date, status: (text: String, color: Color))] {
        var items: [(String, String, Date)] = []

        for house in houses {
            if let d = house.next?.heating {
                items.append((house.name, "Heizung", d))
            }
            if let d = house.next?.roof {
                items.append((house.name, "Dach", d))
            }
            if let d = house.next?.windows {
                items.append((house.name, "Fenster", d))
            }
            if let d = house.next?.smoke {
                items.append((house.name, "Rauchmelder", d))
            }
        }

        let sorted = items.sorted { $0.2 < $1.2 }
        return Array(sorted.prefix(limit)).map { (houseName, component, date) in
            (houseName, component, date, maintenanceStatus(for: date))
        }
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func daysUntil(_ date: Date?) -> Int? {
        guard let date = date else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    private func maintenanceStatus(for date: Date?) -> (text: String, color: Color) {
        guard let days = daysUntil(date) else {
            return ("Unbekannt", .gray)
        }

        if days < 0 {
            return ("Überfällig", .red)
        } else if days <= 60 {
            return ("Bald fällig", .orange)
        } else {
            return ("Okay", .green)
        }
    }

    private var energyAndSecurityGrades: (energy: GradeCounts, security: GradeCounts) {
        var energy = GradeCounts()
        var security = GradeCounts()

        for house in houses {
            let e = energyScore(for: house)
            let s = securityScore(for: house)

            switch e {
            case 80...100: energy.good += 1
            case 60..<80:  energy.medium += 1
            default:       energy.bad += 1
            }

            switch s {
            case 80...100: security.good += 1
            case 60..<80:  security.medium += 1
            default:       security.bad += 1
            }
        }

        return (energy, security)
    }

    // MARK: - Types

    private struct ScoreLabel {
        let text: String
        let color: Color
        let hint: String?
    }

    private struct GradeCounts {
        var good: Int = 0
        var medium: Int = 0
        var bad: Int = 0
    }

    // MARK: - Formatting

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "– €"
    }

    private func formatCurrencyPerSqm(_ value: Double?) -> String {
        guard let v = value else { return "–" }
        return String(format: "%.2f €", v)
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.1f %%", value)
    }
}

// MARK: - Unter-Components

private struct StatusChip: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))

            Text(title)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color.phasirCard.opacity(0.9))
                .overlay(
                    Capsule()
                        .stroke(Color.phasirAccent.opacity(0.25), lineWidth: 1)
                )
        )
        .foregroundColor(Color.phasirSecondaryText)
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let subtitle: String?
    let tint: Color
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color.phasirSecondaryText)

            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(accent)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color.phasirSecondaryText)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tint)
        )
    }
}

private struct RiskBadge: View {
    let label: String
    let count: Int
    var isCritical: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
            Text("\(count)")
                .font(.system(size: 11))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 999)
                .fill(Color.phasirCard.opacity(0.9))
        )
        .foregroundColor(Color.phasirSecondaryText)
    }
}

// MARK: - Donut-Chart

private struct CashSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

private struct DonutChartView: View {
    let slices: [CashSlice]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let lineWidth: CGFloat = size * 0.22
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let total = max(slices.map(\.value).reduce(0, +), 0.0001)

            Canvas { context, _ in
                var startAngle = Angle(degrees: -90)

                for slice in slices {
                    let angle = Angle(degrees: (slice.value / total) * 360)

                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: radius - lineWidth / 2,
                        startAngle: startAngle,
                        endAngle: startAngle + angle,
                        clockwise: false
                    )

                    context.stroke(
                        path,
                        with: .color(slice.color),
                        lineWidth: lineWidth
                    )

                    startAngle += angle
                }
            }
        }
    }
}
