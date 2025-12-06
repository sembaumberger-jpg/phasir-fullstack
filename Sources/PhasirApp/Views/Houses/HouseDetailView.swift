import SwiftUI

struct HouseDetailView: View {
    @ObservedObject var viewModel: HouseListViewModel
    let house: House

    // MARK: - Local State

    @State private var isLoadingEnergyAdvice = false
    @State private var isShowingEdit = false

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    heroHeader
                    detailContent
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.vertical, 16)
            }

            // Navigation zur Bearbeitungs-Form
            NavigationLink(isActive: $isShowingEdit) {
                HouseFormView(
                    mode: .edit(existing: house),
                    onSubmit: { request in
                        await viewModel.updateHouse(houseId: house.id, request: request)
                    }
                )
            } label: {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle(house.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Image("HouseHero")
                .resizable()
                .scaledToFill()
                .frame(height: 230)
                .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .frame(maxWidth: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(house.name)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(house.address)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    Label("\(house.buildYear)", systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))

                    if let area = house.livingArea {
                        Label("\(area) m²", systemImage: "square.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    if let usage = house.usageType {
                        Text(usage)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.20))
                            )
                    }
                }

                if let next = house.earliestUpcomingMaintenance {
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                        Text("Nächste Wartung: \(next.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    // MARK: - Detail Content (verbundenes Layout)

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            overviewSection

            Divider()
                .padding(.horizontal, 4)
                .padding(.vertical, 12)

            maintenanceSection

            Divider()
                .padding(.horizontal, 4)
                .padding(.vertical, 12)

            energyAssistantSection

            Divider()
                .padding(.horizontal, 4)
                .padding(.vertical, 12)

            metaInfoSection
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.phasirCard)
                .shadow(color: .black.opacity(0.04), radius: 18, x: 0, y: 10)
        )
    }

    // MARK: - Überblick

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Überblick")
                        .font(.phasirSectionTitle)

                    Text("Kernfakten deiner Immobilie in einem Blick.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                }

                Spacer()

                if let usage = house.usageType {
                    Text(usage)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.phasirAccent.opacity(0.08))
                        )
                        .foregroundColor(Color.phasirAccent)
                }
            }

            HStack(spacing: 12) {
                overviewStatBlock(
                    title: "Baujahr",
                    value: "\(house.buildYear)"
                )

                if let area = house.livingArea {
                    overviewStatBlock(
                        title: "Wohnfläche",
                        value: "\(area) m²"
                    )
                }

                if let residents = house.residentsCount {
                    overviewStatBlock(
                        title: "Bewohner",
                        value: "\(residents)"
                    )
                }
            }

            if let type = house.propertyType {
                Divider().padding(.vertical, 4)

                HStack {
                    Text("Objekttyp")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    Spacer()

                    Text(type)
                        .font(.phasirBody)
                }
            }
        }
    }

    private func overviewStatBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Text(title)
                .font(.phasirCaption)
                .foregroundColor(Color.phasirSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Wartungsstatus (inkl. nächster Komponente)

    private var maintenanceSection: some View {
        let componentInfo = nextMaintenanceComponent()
        let nextDate = componentInfo?.date
        let status = maintenanceStatus(for: nextDate)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Wartungsstatus")
                    .font(.phasirSectionTitle)

                Spacer()

                Text(status.text)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.10))
                    .foregroundColor(status.color)
                    .cornerRadius(999)
            }

            if let info = componentInfo {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nächste fällige Maßnahme")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shortDate(info.date))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))

                            if let days = daysUntil(date: info.date) {
                                Text(daysText(days))
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(info.name)
                                .font(.phasirBody)
                            Text("Bauteil")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }
                    }
                }
            } else {
                Text("Für dieses Objekt sind aktuell keine konkreten Wartungstermine hinterlegt.")
                    .font(.phasirBody)
                    .foregroundColor(Color.phasirSecondaryText)
            }
        }
    }

    /// ermittelt, welche Wartung (Heizung/Dach/Fenster/Rauchmelder) als nächstes fällig ist
    private func nextMaintenanceComponent() -> (name: String, date: Date)? {
        guard let next = house.next else { return nil }

        var candidates: [(String, Date)] = []

        if let d = next.heating {
            candidates.append(("Heizung", d))
        }
        if let d = next.roof {
            candidates.append(("Dach", d))
        }
        if let d = next.windows {
            candidates.append(("Fenster", d))
        }
        if let d = next.smoke {
            candidates.append(("Rauchmelder", d))
        }

        guard let best = candidates.min(by: { $0.1 < $1.1 }) else { return nil }
        return best
    }

    private func daysUntil(date: Date) -> Int? {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: date)
        let diff = Calendar.current.dateComponents([.day], from: start, to: end).day
        return diff
    }

    private func daysText(_ days: Int) -> String {
        if days < 0 {
            return "Überfällig seit \(-days) Tagen"
        } else if days == 0 {
            return "Heute fällig"
        } else if days == 1 {
            return "In 1 Tag fällig"
        } else {
            return "In \(days) Tagen fällig"
        }
    }

    private func maintenanceStatus(for date: Date?) -> (text: String, color: Color) {
        guard let date = date, let days = daysUntil(date: date) else {
            return ("Unbekannt", .gray)
        }

        if days < 0 {
            return ("Überfällig", .red)
        } else if days <= 60 {
            return ("Bald fällig", .orange)
        } else {
            return ("Entspannt", .green)
        }
    }

    // MARK: - Energie-Assistent (KI)

    private var energyAssistantSection: some View {
        let advice = viewModel.energyAdvice(for: house.id)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Energie-Assistent")
                        .font(.phasirSectionTitle)

                    Text("Die KI wertet Baujahr, Dämmung und Nutzung aus und schätzt dein Einsparpotenzial.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                }

                Spacer()

                if let advice = advice {
                    Text("Score \(advice.score)")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(energyColor(for: advice.score).opacity(0.12))
                        .foregroundColor(energyColor(for: advice.score))
                        .cornerRadius(999)
                }
            }

            if let advice = advice {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Effizienz-Einschätzung")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    energyScoreBar(numericScore: advice.numericScore)

                    Text(advice.summary)
                        .font(.phasirBody)
                        .foregroundColor(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let kwh = advice.potentialSavingsKwh,
                   let euro = advice.potentialSavingsEuro {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ca. \(kwh) kWh / Jahr")
                                .font(.phasirBody)
                            Text("theoretisches Einsparpotenzial")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(euro) € / Jahr")
                                .font(.phasirBody.weight(.semibold))
                            Text("bei 0,30 € pro kWh")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }
                    }
                    .padding(.top, 4)
                }

                if !advice.insights.isEmpty {
                    Divider().padding(.vertical, 4)

                    Text("Wichtigste Beobachtungen")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(advice.insights.prefix(3), id: \.self) { text in
                            HStack(alignment: .top, spacing: 6) {
                                Circle()
                                    .fill(Color.phasirAccent)
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 6)
                                Text(text)
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                    }
                }

                if !advice.recommendedActions.isEmpty {
                    Divider().padding(.vertical, 4)

                    Text("Empfohlene Maßnahmen")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(advice.recommendedActions.prefix(3), id: \.self) { text in
                            HStack(alignment: .top, spacing: 6) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.phasirAccent.opacity(0.7))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                Text(text)
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Noch keine Analyse durchgeführt.")
                        .font(.phasirBody)
                        .foregroundColor(Color.primary)

                    Text("Lass Phasir eine erste Einschätzung für dieses Objekt berechnen – unverbindlich und jederzeit aktualisierbar.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                }
            }

            Button {
                Task {
                    isLoadingEnergyAdvice = true
                    await viewModel.loadEnergyAdvice(for: house.id)
                    isLoadingEnergyAdvice = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoadingEnergyAdvice {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "bolt.fill")
                    }

                    Text(advice == nil ? "Jetzt Immobilie analysieren lassen" : "Analyse aktualisieren")
                }
                .font(.phasirButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.phasirAccent)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private func energyScoreBar(numericScore: Int) -> some View {
        let clamped = max(0, min(100, numericScore))
        let fraction = CGFloat(clamped) / 100.0

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 999)
                .fill(Color.phasirCardBorder.opacity(0.4))
                .frame(height: 10)

            RoundedRectangle(cornerRadius: 999)
                .fill(energyColor(forScore: clamped))
                .frame(width: fraction * UIScreen.main.bounds.width * 0.6, height: 10)
        }
    }

    private func energyColor(for score: String) -> Color {
        switch score.uppercased() {
        case "A": return .green
        case "B": return .green.opacity(0.8)
        case "C": return .orange
        default:  return .red
        }
    }

    private func energyColor(forScore score: Int) -> Color {
        switch score {
            case 80...100: return .green
            case 60..<80:  return .green.opacity(0.8)
            case 40..<60:  return .orange
            default:       return .red
        }
    }

    // MARK: - Objektprofil + „Datenstand“ + Bearbeiten

    private var metaInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Objektprofil")
                        .font(.phasirSectionTitle)

                    Text("Alle gespeicherten Daten zu diesem Objekt auf einen Blick.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                }

                Spacer()

                if let last = lastUpdatedDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Datenstand")
                            .font(.caption2)
                            .foregroundColor(Color.phasirSecondaryText)
                        Text(shortDate(last))
                            .font(.caption2.bold())
                            .foregroundColor(Color.phasirSecondaryText)
                    }
                }
            }

            // BASIS
            Group {
                sectionHeader("Basisdaten")

                infoRow(label: "Adresse", value: house.address)
                infoRow(label: "Baujahr", value: "\(house.buildYear)")
                infoRow(label: "Heizungstyp", value: house.heatingType)
                infoRow(label: "Heizung installiert", value: "\(house.heatingInstallYear)")

                if let d = house.lastHeatingService {
                    infoRow(label: "Letzter Heizungsservice", value: shortDate(d))
                }

                infoRow(label: "Dach installiert", value: "\(house.roofInstallYear)")

                if let d = house.lastRoofCheck {
                    infoRow(label: "Letzte Dachprüfung", value: shortDate(d))
                }

                infoRow(label: "Fenster installiert", value: "\(house.windowInstallYear)")

                if let d = house.lastSmokeCheck {
                    infoRow(label: "Letzter Rauchmelder-Check", value: shortDate(d))
                }

                if let nextInfo = nextMaintenanceComponent() {
                    infoRow(
                        label: "Nächste Wartung",
                        value: "\(shortDate(nextInfo.date)) · \(nextInfo.name)"
                    )
                }
            }

            Divider().padding(.vertical, 4)

            // ENERGIE / WOHNPROFIL
            Group {
                sectionHeader("Energie & Wohnprofil")

                if let area = house.livingArea {
                    infoRow(label: "Wohnfläche", value: "\(area) m²")
                }
                if let res = house.residentsCount {
                    infoRow(label: "Bewohner", value: "\(res)")
                }
                if let type = house.propertyType {
                    infoRow(label: "Objekttyp", value: type)
                }
                if let insulation = house.insulationLevel {
                    infoRow(label: "Dämmstandard", value: insulation)
                }
                if let glazing = house.windowGlazing {
                    infoRow(label: "Fenster", value: glazing)
                }
                if let hasSolar = yesNoText(house.hasSolarPanels) {
                    infoRow(label: "PV-/Solaranlage", value: hasSolar)
                }
                if let cert = house.energyCertificateClass {
                    infoRow(label: "Energieausweis", value: cert)
                }
                if let consumption = house.estimatedAnnualEnergyConsumption {
                    infoRow(label: "Jahresverbrauch (geschätzt)", value: String(format: "%.0f kWh", consumption))
                }
                if let comfort = house.comfortPreference {
                    infoRow(label: "Komfortpräferenz", value: comfort)
                }
            }

            Divider().padding(.vertical, 4)

            // SICHERHEITS-PROFIL
            Group {
                sectionHeader("Sicherheitsprofil")

                if let level = house.doorSecurityLevel {
                    infoRow(label: "Türsicherheit", value: level)
                }
                if let val = yesNoText(house.hasGroundFloorWindowSecurity) {
                    infoRow(label: "Fensterschutz EG", value: val)
                }
                if let val = yesNoText(house.hasAlarmSystem) {
                    infoRow(label: "Alarmanlage", value: val)
                }
                if let val = yesNoText(house.hasCameras) {
                    infoRow(label: "Kameras", value: val)
                }
                if let val = yesNoText(house.hasMotionLightsOutside) {
                    infoRow(label: "Bewegungsmelder außen", value: val)
                }
                if let val = yesNoText(house.hasSmokeDetectorsAllRooms) {
                    infoRow(label: "Rauchmelder in allen Räumen", value: val)
                }
                if let val = yesNoText(house.hasCO2Detector) {
                    infoRow(label: "CO₂-Melder", value: val)
                }
                if let risk = house.neighbourhoodRiskLevel {
                    infoRow(label: "Lage-/Risikoeinschätzung", value: risk)
                }
            }

            Divider().padding(.vertical, 4)

            // NUTZUNG & FINANZEN
            Group {
                sectionHeader("Nutzung & Finanzen")

                if let usage = house.usageType {
                    infoRow(label: "Nutzung", value: usage)
                }
                if let cold = formattedCurrency(house.monthlyRentCold) {
                    infoRow(label: "Kaltmiete", value: cold + " / Monat")
                }
                if let warm = formattedCurrency(house.monthlyRentWarm) {
                    infoRow(label: "Warmmiete", value: warm + " / Monat")
                }
                if let vac = formattedPercent(house.expectedVacancyRate) {
                    infoRow(label: "Leerstandsannahme", value: vac)
                }
                if let util = formattedCurrency(house.monthlyUtilities) {
                    infoRow(label: "Monatliche Nebenkosten", value: util)
                }
                if let hoa = formattedCurrency(house.monthlyHoaFees) {
                    infoRow(label: "Hausgeld / WEG", value: hoa)
                }
                if let ins = formattedCurrency(house.insurancePerYear) {
                    infoRow(label: "Versicherung", value: ins + " / Jahr")
                }
                if let maint = formattedCurrency(house.maintenanceBudgetPerYear) {
                    infoRow(label: "Wartungsbudget", value: maint + " / Jahr")
                }
                if let price = formattedCurrency(house.purchasePrice) {
                    infoRow(label: "Kaufpreis", value: price)
                }
                if let eq = formattedCurrency(house.equity) {
                    infoRow(label: "Eigenkapital", value: eq)
                }
                if let loan = formattedCurrency(house.remainingLoanAmount) {
                    infoRow(label: "Restdarlehen", value: loan)
                }
                if let rate = house.interestRate {
                    infoRow(label: "Zinssatz", value: String(format: "%.2f %%", rate))
                }
                if let loanRate = formattedCurrency(house.loanMonthlyPayment) {
                    infoRow(label: "Darlehensrate", value: loanRate + " / Monat")
                }
            }

            Button {
                isShowingEdit = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Bearbeiten")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.phasirAccent.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private var lastUpdatedDate: Date? {
        // grobe Heuristik: letzte bekannte Wartung als „Datenstand“
        let dates: [Date?] = [
            house.lastHeatingService,
            house.lastRoofCheck,
            house.lastSmokeCheck
        ]
        return dates.compactMap { $0 }.max()
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.phasirCaption.weight(.semibold))
            .foregroundColor(Color.phasirSecondaryText)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.phasirCaption)
            Spacer()
            Text(value)
                .font(.phasirCaption)
                .foregroundColor(Color.phasirSecondaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func yesNoText(_ value: Bool?) -> String? {
        guard let v = value else { return nil }
        return v ? "Ja" : "Nein"
    }

    private func formattedCurrency(_ value: Double?) -> String? {
        guard let v = value else { return nil }
        return String(format: "%.0f €", v)
    }

    private func formattedPercent(_ value: Double?) -> String? {
        guard let v = value else { return nil }
        return String(format: "%.1f %%", v)
    }
}

// MARK: - (optional) InfoBadge (falls irgendwann wieder genutzt)

private struct InfoBadge: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(Color.phasirSecondaryText)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption2)
                    .foregroundColor(Color.phasirSecondaryText)
            }
        }
    }
}
