import SwiftUI

struct HouseFormView: View {
    enum Mode {
        case create
        case edit(existing: House)

        var title: String {
            switch self {
            case .create: return "Neue Immobilie"
            case .edit:   return "Immobilie bearbeiten"
            }
        }
    }

    let mode: Mode
    var onSubmit: (CreateHouseRequest) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var request = CreateHouseRequest()
    @State private var isSubmitting = false

    // UI-States für numerische Felder (damit keine "0" angezeigt wird)
    @State private var livingAreaText: String = ""
    @State private var residentsCountText: String = ""
    @State private var estimatedAnnualEnergyConsumptionText: String = ""

    @State private var purchasePriceText: String = ""
    @State private var loanMonthlyPaymentText: String = ""
    @State private var remainingLoanAmountText: String = ""
    @State private var interestRateText: String = ""

    @State private var monthlyRentColdText: String = ""
    @State private var monthlyRentWarmText: String = ""
    @State private var expectedVacancyRateText: String = ""

    @State private var monthlyUtilitiesText: String = ""
    @State private var monthlyHoaFeesText: String = ""
    @State private var insurancePerYearText: String = ""
    @State private var maintenanceBudgetPerYearText: String = ""

    @State private var isFinanceExpanded: Bool = false

    // Neue UI-States für Nebenkosten / Struktur
    @State private var unitCountText: String = ""
    @State private var operatingCostAdvanceText: String = ""
    @State private var lastOperatingCostYearText: String = ""
    @State private var isCostExpanded: Bool = false

    // Placeholder: Input style defined globally at bottom of file.

    private let heatingTypes = ["Gas", "Öl", "Wärmepumpe", "Fernwärme", "Solar", "Elektrisch"]
    private let usageTypes = [
        "Eigenbedarf",
        "Vermietet (Wohnraum)",
        "Gewerblich",
        "Kurzzeitvermietung"
    ]

    init(mode: Mode, onSubmit: @escaping (CreateHouseRequest) async -> Bool) {
        self.mode = mode
        self.onSubmit = onSubmit

        if case let .edit(existing) = mode {
            var initial = CreateHouseRequest()
            // Basis
            initial.ownerName = existing.ownerName ?? ""
            initial.name = existing.name
            initial.address = existing.address
            initial.buildYear = existing.buildYear
            initial.heatingType = existing.heatingType
            initial.heatingInstallYear = existing.heatingInstallYear
            initial.lastHeatingService = existing.lastHeatingService
            initial.roofInstallYear = existing.roofInstallYear
            initial.lastRoofCheck = existing.lastRoofCheck
            initial.windowInstallYear = existing.windowInstallYear
            initial.lastSmokeCheck = existing.lastSmokeCheck

            // Wohn- & Energieprofil
            initial.livingArea = existing.livingArea
            initial.residentsCount = existing.residentsCount
            initial.propertyType = existing.propertyType
            initial.insulationLevel = existing.insulationLevel
            initial.windowGlazing = existing.windowGlazing
            initial.hasSolarPanels = existing.hasSolarPanels
            initial.energyCertificateClass = existing.energyCertificateClass
            initial.estimatedAnnualEnergyConsumption = existing.estimatedAnnualEnergyConsumption
            initial.comfortPreference = existing.comfortPreference

            // Sicherheitsprofil
            initial.doorSecurityLevel = existing.doorSecurityLevel
            initial.hasGroundFloorWindowSecurity = existing.hasGroundFloorWindowSecurity
            initial.hasAlarmSystem = existing.hasAlarmSystem
            initial.hasCameras = existing.hasCameras
            initial.hasMotionLightsOutside = existing.hasMotionLightsOutside
            initial.hasSmokeDetectorsAllRooms = existing.hasSmokeDetectorsAllRooms
            initial.hasCO2Detector = existing.hasCO2Detector
            initial.neighbourhoodRiskLevel = existing.neighbourhoodRiskLevel

            // Nutzung & Finanzen
            initial.usageType = existing.usageType
            initial.monthlyRentCold = existing.monthlyRentCold
            initial.monthlyRentWarm = existing.monthlyRentWarm
            initial.expectedVacancyRate = existing.expectedVacancyRate
            initial.monthlyUtilities = existing.monthlyUtilities
            initial.monthlyHoaFees = existing.monthlyHoaFees
            initial.insurancePerYear = existing.insurancePerYear
            initial.maintenanceBudgetPerYear = existing.maintenanceBudgetPerYear
            initial.purchasePrice = existing.purchasePrice
            initial.equity = existing.equity
            initial.remainingLoanAmount = existing.remainingLoanAmount
            initial.interestRate = existing.interestRate
            initial.loanMonthlyPayment = existing.loanMonthlyPayment

            // Nebenkosten & Struktur (falls vorhanden)
            initial.billingModel = existing.billingModel
            initial.unitCount = existing.unitCount
            initial.hasCommercialUnit = existing.hasCommercialUnit
            initial.primaryOperatingCostKey = existing.primaryOperatingCostKey
            initial.hasCaretakerService = existing.hasCaretakerService
            initial.hasGardenService = existing.hasGardenService
            initial.hasElevator = existing.hasElevator
            initial.hasCommonElectricity = existing.hasCommonElectricity
            initial.hasGarageOrParking = existing.hasGarageOrParking
            initial.hasHeatMeterPerUnit = existing.hasHeatMeterPerUnit
            initial.hasWaterMeterPerUnit = existing.hasWaterMeterPerUnit
            initial.operatingCostAdvanceTotalPerMonth = existing.operatingCostAdvanceTotalPerMonth
            initial.lastOperatingCostYear = existing.lastOperatingCostYear
            initial.operatingCostNotes = existing.operatingCostNotes

            _request = State(initialValue: initial)

            // numerische Text-States aus bestehenden Werten befüllen
            _livingAreaText = State(initialValue: existing.livingArea.map { String($0) } ?? "")
            _residentsCountText = State(initialValue: existing.residentsCount.map { String($0) } ?? "")
            _estimatedAnnualEnergyConsumptionText = State(initialValue: existing.estimatedAnnualEnergyConsumption.map { cleanString(from: $0) } ?? "")

            _purchasePriceText = State(initialValue: existing.purchasePrice.map { cleanString(from: $0) } ?? "")
            _loanMonthlyPaymentText = State(initialValue: existing.loanMonthlyPayment.map { cleanString(from: $0) } ?? "")
            _remainingLoanAmountText = State(initialValue: existing.remainingLoanAmount.map { cleanString(from: $0) } ?? "")
            _interestRateText = State(initialValue: existing.interestRate.map { cleanString(from: $0) } ?? "")

            _monthlyRentColdText = State(initialValue: existing.monthlyRentCold.map { cleanString(from: $0) } ?? "")
            _monthlyRentWarmText = State(initialValue: existing.monthlyRentWarm.map { cleanString(from: $0) } ?? "")
            _expectedVacancyRateText = State(initialValue: existing.expectedVacancyRate.map { cleanString(from: $0) } ?? "")

            _monthlyUtilitiesText = State(initialValue: existing.monthlyUtilities.map { cleanString(from: $0) } ?? "")
            _monthlyHoaFeesText = State(initialValue: existing.monthlyHoaFees.map { cleanString(from: $0) } ?? "")
            _insurancePerYearText = State(initialValue: existing.insurancePerYear.map { cleanString(from: $0) } ?? "")
            _maintenanceBudgetPerYearText = State(initialValue: existing.maintenanceBudgetPerYear.map { cleanString(from: $0) } ?? "")

            // Nebenkosten / Struktur Text-States
            _unitCountText = State(initialValue: existing.unitCount.map { String($0) } ?? "")
            _operatingCostAdvanceText = State(initialValue: existing.operatingCostAdvanceTotalPerMonth.map { cleanString(from: $0) } ?? "")
            _lastOperatingCostYearText = State(initialValue: existing.lastOperatingCostYear.map { String($0) } ?? "")
        }
    }

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    basicInfoSection
                    energySecuritySection
                    financeSection
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen", role: .cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: submit) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Speichern")
                    }
                }
                .disabled(isSubmitting)
            }
        }
    }

    // MARK: - Sections

    // Neue Sektion: Grunddaten (Objekt, Nutzung, Wohn-/Energieprofil)
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objekt & Nutzung")
                .font(.phasirSectionTitle)

            // Objektinformationen
            VStack(spacing: 10) {

                TextField("Name der Immobilie", text: $request.name)
                    .textInputAutocapitalization(.words)
                    .phasirInputStyle()

                TextField("Adresse", text: $request.address)
                    .textInputAutocapitalization(.words)
                    .phasirInputStyle()

                TextField("Eigentümer (optional)", text: $request.ownerName)
                    .textInputAutocapitalization(.words)
                    .phasirInputStyle()

                Stepper("Baujahr: \(request.buildYear)", value: $request.buildYear, in: 1800...2100)
                    .font(.subheadline)
            }

            Divider().padding(.vertical, 8)

            // Nutzungstyp
            VStack(alignment: .leading, spacing: 8) {
                Text("Nutzung")
                    .font(.caption)
                    .foregroundColor(Color.phasirSecondaryText)

                Picker("", selection: Binding($request.usageType, "Eigenbedarf")) {
                    ForEach(usageTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(Color.phasirCard.opacity(0.06))
                .cornerRadius(8)

                Text("Diese Information hilft Phasir, Energie-, Sicherheits- und Finanzempfehlungen auf Eigenbedarf oder Vermietung zuzuschneiden.")
                    .font(.caption)
                    .foregroundColor(Color.phasirSecondaryText)
            }

            Divider().padding(.vertical, 8)

            // Wohn- & Energieprofil
            VStack(alignment: .leading, spacing: 10) {
                Text("Wohn- & Energieprofil")
                    .font(.caption)
                    .foregroundColor(Color.phasirSecondaryText)

                TextField("Wohnfläche (m²)", text: $livingAreaText)
                    .keyboardType(.numberPad)
                    .phasirInputStyle()

                TextField("Anzahl Bewohner", text: $residentsCountText)
                    .keyboardType(.numberPad)
                    .phasirInputStyle()

                TextField("Haustyp (z.B. EFH, MFH, Wohnung)", text: Binding($request.propertyType, ""))
                    .phasirInputStyle()

                TextField("Dämmstandard (z.B. KfW, unsaniert, gut gedämmt)", text: Binding($request.insulationLevel, ""))
                    .phasirInputStyle()

                TextField("Fensterverglasung (z.B. zweifach, dreifach)", text: Binding($request.windowGlazing, ""))
                    .phasirInputStyle()

                Toggle("PV-/Solaranlage vorhanden", isOn: Binding($request.hasSolarPanels, false))
                    .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))

                TextField("Energieausweis-Klasse (z.B. A+, B, C)", text: Binding($request.energyCertificateClass, ""))
                    .phasirInputStyle()

                TextField("Jahresverbrauch (kWh, geschätzt)", text: $estimatedAnnualEnergyConsumptionText)
                    .keyboardType(.decimalPad)
                    .phasirInputStyle()

                TextField("Komfortpräferenz (z.B. eher warm, neutral)", text: Binding($request.comfortPreference, ""))
                    .phasirInputStyle()
            }
        }
        .phasirCard()
    }

    // Neue Sektion: Sicherheit & Technik (Sicherheitsprofil, Heizung & Wartung)
    private var energySecuritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sicherheit & Technik")
                .font(.phasirSectionTitle)

            // Sicherheitsprofil
            VStack(alignment: .leading, spacing: 10) {
                Text("Sicherheitsprofil")
                    .font(.caption)
                    .foregroundColor(Color.phasirSecondaryText)

                TextField("Haustür-Sicherheit (z.B. RC2, Mehrfachverriegelung)", text: Binding($request.doorSecurityLevel, ""))
                    .phasirInputStyle()

                Toggle("Fenstersicherungen im Erdgeschoss", isOn: Binding($request.hasGroundFloorWindowSecurity, false))
                    .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))
                Toggle("Alarmanlage vorhanden", isOn: Binding($request.hasAlarmSystem, false))
                    .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))
                Toggle("Kameras / Videoüberwachung", isOn: Binding($request.hasCameras, false))
                    .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))
                Toggle("Außenbeleuchtung mit Bewegungsmelder", isOn: Binding($request.hasMotionLightsOutside, false))
                    .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))
                Toggle("Rauchmelder in allen relevanten Räumen", isOn: Binding($request.hasSmokeDetectorsAllRooms, false))
                    .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))
                Toggle("CO₂ / CO-Melder vorhanden", isOn: Binding($request.hasCO2Detector, false))
                    .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))

                TextField("Nachbarschafts-Risiko (z.B. niedrig, mittel, hoch)", text: Binding($request.neighbourhoodRiskLevel, ""))
                    .phasirInputStyle()
            }

            Divider().padding(.vertical, 8)

            // Heizung & Wartung
            VStack(alignment: .leading, spacing: 10) {
                Text("Heizung & Wartung")
                    .font(.caption)
                    .foregroundColor(Color.phasirSecondaryText)

                // Heizung
                Picker("Heizungstyp", selection: $request.heatingType) {
                    ForEach(heatingTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }

                Stepper("Heizung Einbaujahr: \(request.heatingInstallYear)", value: $request.heatingInstallYear, in: 1900...2100)

                DatePicker(
                    "Letzte Heizungswartung",
                    selection: Binding($request.lastHeatingService, Date()),
                    displayedComponents: .date
                )

                Divider().padding(.vertical, 8)

                // Dach, Fenster & Rauchmelder
                Text("Dach, Fenster & Rauchmelder")
                    .font(.caption)
                    .foregroundColor(Color.phasirSecondaryText)

                Stepper("Dach Einbaujahr: \(request.roofInstallYear)", value: $request.roofInstallYear, in: 1900...2100)

                DatePicker(
                    "Letzte Dachprüfung",
                    selection: Binding($request.lastRoofCheck, Date()),
                    displayedComponents: .date
                )

                Stepper("Fenster Einbaujahr: \(request.windowInstallYear)", value: $request.windowInstallYear, in: 1900...2100)

                DatePicker(
                    "Letzte Rauchmelderprüfung",
                    selection: Binding($request.lastSmokeCheck, Date()),
                    displayedComponents: .date
                )
            }
        }
        .phasirCard()
    }

    // Neue Sektion: Finanzen & Nebenkosten
    private var financeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Finanzen & Nebenkosten (optional)")
                .font(.phasirSectionTitle)

            // Finanzielle Details
            DisclosureGroup(isExpanded: $isFinanceExpanded) {
                VStack(spacing: 12) {
                    // Kauf & Finanzierung
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kauf & Finanzierung")
                            .font(.caption)
                            .foregroundColor(Color.phasirSecondaryText)

                        TextField("Kaufpreis (€)", text: $purchasePriceText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()

                        TextField("Monatliche Kreditrate (€)", text: $loanMonthlyPaymentText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()

                        TextField("Verbleibende Darlehenssumme (€)", text: $remainingLoanAmountText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()

                        TextField("Zinssatz (%)", text: $interestRateText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()
                    }

                    Divider().padding(.vertical, 4)

                    // Mieteinnahmen
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mieteinnahmen (falls vermietet)")
                            .font(.caption)
                            .foregroundColor(Color.phasirSecondaryText)

                        TextField("Kaltmiete pro Monat (€)", text: $monthlyRentColdText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()

                        TextField("Warmmiete pro Monat (€)", text: $monthlyRentWarmText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()

                        TextField("Erwartete Leerstandsquote (%)", text: $expectedVacancyRateText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()
                    }

                    Divider().padding(.vertical, 4)

                    // Laufende Kosten
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Laufende Kosten")
                            .font(.caption)
                            .foregroundColor(Color.phasirSecondaryText)

                        TextField("Nebenkosten (Strom, Gas, Wasser) mtl. (€)", text: $monthlyUtilitiesText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()

                        TextField("Hausgeld / WEG mtl. (€)", text: $monthlyHoaFeesText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()

                        TextField("Versicherung pro Jahr (€)", text: $insurancePerYearText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()

                        TextField("Wartungsbudget pro Jahr (€)", text: $maintenanceBudgetPerYearText)
                            .keyboardType(.decimalPad)
                            .phasirInputStyle()
                    }

                    Text("Du kannst diesen Bereich auch komplett leer lassen. Je mehr du angibst, desto genauer werden Cashflow-, Rendite- und Finanz-Insights.")
                        .font(.caption)
                        .foregroundColor(Color.phasirSecondaryText)
                        .padding(.top, 4)
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text(isFinanceExpanded ? "Finanzdetails ausblenden" : "Finanzdetails anzeigen")
                        .font(.subheadline)
                        .foregroundColor(Color.phasirAccent)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isFinanceExpanded ? 180 : 0))
                        .foregroundColor(Color.phasirAccent)
                        .font(.caption)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isFinanceExpanded)

            Divider().padding(.vertical, 4)

            // Nebenkosten & Struktur
            DisclosureGroup(isExpanded: $isCostExpanded) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Abrechnungsmodell")
                        .font(.caption)
                        .foregroundColor(Color.phasirSecondaryText)

                    Picker("", selection: Binding($request.billingModel, "single")) {
                        Text("Einfamilienhaus").tag("single")
                        Text("Mehrfamilienhaus").tag("multi")
                    }
                    .pickerStyle(.segmented)
                    .padding(4)
                    .background(Color.phasirCard.opacity(0.06))
                    .cornerRadius(8)

                    HStack(alignment: .center, spacing: 12) {
                        TextField("Anzahl Einheiten", text: $unitCountText)
                            .keyboardType(.numberPad)
                            .phasirInputStyle()
                        Toggle("Gewerbeeinheit", isOn: Binding($request.hasCommercialUnit, false))
                            .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))
                    }

                    Text("Umlageschlüssel")
                        .font(.caption)
                        .foregroundColor(Color.phasirSecondaryText)
                    Picker("", selection: Binding($request.primaryOperatingCostKey, "sqm")) {
                        Text("Wohnfläche").tag("sqm")
                        Text("Personen").tag("people")
                        Text("Einheiten").tag("units")
                        Text("Verbrauch").tag("consumption")
                    }
                    .pickerStyle(.segmented)
                    .padding(4)
                    .background(Color.phasirCard.opacity(0.06))
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Hausmeisterservice", isOn: Binding($request.hasCaretakerService, false))
                        Toggle("Gartenpflege", isOn: Binding($request.hasGardenService, false))
                        Toggle("Aufzug vorhanden", isOn: Binding($request.hasElevator, false))
                        Toggle("Allgemeinstrom", isOn: Binding($request.hasCommonElectricity, false))
                        Toggle("Garage / Stellplatz", isOn: Binding($request.hasGarageOrParking, false))
                        Toggle("Heizkostenzähler pro Einheit", isOn: Binding($request.hasHeatMeterPerUnit, false))
                        Toggle("Wasserkostenzähler pro Einheit", isOn: Binding($request.hasWaterMeterPerUnit, false))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.phasirAccent))

                    TextField("BK-Vorauszahlung (€ mtl.)", text: $operatingCostAdvanceText)
                        .keyboardType(.decimalPad)
                        .phasirInputStyle()

                    TextField("Letzte Nebenkostenabrechnung (Jahr)", text: $lastOperatingCostYearText)
                        .keyboardType(.numberPad)
                        .phasirInputStyle()

                    TextField("Notizen (optional)", text: Binding($request.operatingCostNotes, ""))
                        .phasirInputStyle()
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text(isCostExpanded ? "Nebenkosten ausblenden" : "Nebenkosten hinzufügen")
                        .font(.subheadline)
                        .foregroundColor(Color.phasirAccent)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isCostExpanded ? 180 : 0))
                        .foregroundColor(Color.phasirAccent)
                        .font(.caption)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isCostExpanded)
        }
        .phasirCard()
    }

    // MARK: - Submit

    private func submit() {
        // alles auf dem MainActor halten, um UI-Crashes zu vermeiden
        Task { @MainActor in
            guard !isSubmitting else { return }
            isSubmitting = true

            applyNumericFieldsToRequest()
            let success = await onSubmit(request)

            isSubmitting = false

            if success {
                dismiss()
            }
        }
    }

    /// Parst alle Textfelder in optionale Int/Double-Werte
    private func applyNumericFieldsToRequest() {
        request.livingArea = Int(livingAreaText.trimmingCharacters(in: .whitespaces))
        request.residentsCount = Int(residentsCountText.trimmingCharacters(in: .whitespaces))
        request.estimatedAnnualEnergyConsumption = parseDouble(estimatedAnnualEnergyConsumptionText)

        request.purchasePrice = parseDouble(purchasePriceText)
        request.loanMonthlyPayment = parseDouble(loanMonthlyPaymentText)
        request.remainingLoanAmount = parseDouble(remainingLoanAmountText)
        request.interestRate = parseDouble(interestRateText)

        request.monthlyRentCold = parseDouble(monthlyRentColdText)
        request.monthlyRentWarm = parseDouble(monthlyRentWarmText)
        request.expectedVacancyRate = parseDouble(expectedVacancyRateText)

        request.monthlyUtilities = parseDouble(monthlyUtilitiesText)
        request.monthlyHoaFees = parseDouble(monthlyHoaFeesText)
        request.insurancePerYear = parseDouble(insurancePerYearText)
        request.maintenanceBudgetPerYear = parseDouble(maintenanceBudgetPerYearText)

        // Nebenkosten / Struktur Felder
        // unitCount (Int?)
        let unitTrimmed = unitCountText.trimmingCharacters(in: .whitespaces)
        request.unitCount = Int(unitTrimmed)

        // operatingCostAdvanceTotalPerMonth (Double?)
        request.operatingCostAdvanceTotalPerMonth = parseDouble(operatingCostAdvanceText)

        // lastOperatingCostYear (Int?)
        let lastYearTrimmed = lastOperatingCostYearText.trimmingCharacters(in: .whitespaces)
        request.lastOperatingCostYear = Int(lastYearTrimmed)
    }

    private func parseDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

// MARK: - Hilfsfunktion für init (Double → String)

private func cleanString(from value: Double) -> String {
    // kein wissenschaftliches Format, max. 2 Nachkommastellen
    if value.rounded(.toNearestOrAwayFromZero) == value {
        return String(Int(value))
    } else {
        return String(format: "%.2f", value)
    }
}

// Binding<Date?> → Date
private extension Binding where Value == Date {
    init(_ source: Binding<Date?>, _ fallback: Date) {
        self.init(
            get: { source.wrappedValue ?? fallback },
            set: { newValue in
                source.wrappedValue = newValue
            }
        )
    }
}

// Binding<String?> → String
private extension Binding where Value == String {
    init(_ source: Binding<String?>, _ fallback: String) {
        self.init(
            get: { source.wrappedValue ?? fallback },
            set: { newValue in
                source.wrappedValue = newValue
            }
        )
    }
}

// Binding<Bool?> → Bool
private extension Binding where Value == Bool {
    init(_ source: Binding<Bool?>, _ fallback: Bool) {
        self.init(
            get: { source.wrappedValue ?? fallback },
            set: { newValue in
                source.wrappedValue = newValue
            }
        )
    }
}

// MARK: - Global extensions for Phasir input styling

/// Provides a custom input style modifier for text fields and other inputs used throughout the form.
extension View {
    func phasirInputStyle() -> some View {
        self.modifier(PhasirInputStyle())
    }
}

// MARK: - Global Phasir input style definition

/// A custom modifier that gives inputs a distinctive Phasir appearance.
/// It adds padding, a subtle background, a faint stroke and rounded corners.
fileprivate struct PhasirInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color.phasirCard.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.phasirAccent.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(10)
    }
}
