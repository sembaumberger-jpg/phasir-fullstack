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
        }
    }

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    objectSection
                    usageSection
                    energyProfileSection
                    securitySection
                    heatingSection
                    maintenanceSection
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

    private var objectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objekt")
                .font(.phasirSectionTitle)

            VStack(spacing: 10) {
                TextField("Name der Immobilie", text: $request.name)
                    .textFieldStylePhasir()
                    .textInputAutocapitalization(.words)

                TextField("Adresse", text: $request.address)
                    .textFieldStylePhasir()
                    .textInputAutocapitalization(.words)

                TextField("Eigentümer (optional)", text: $request.ownerName)
                    .textFieldStylePhasir()
                    .textInputAutocapitalization(.words)

                Stepper("Baujahr: \(request.buildYear)", value: $request.buildYear, in: 1800...2100)
                    .font(.subheadline)
            }
        }
        .phasirCard()
    }

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutzung")
                .font(.phasirSectionTitle)

            VStack(alignment: .leading, spacing: 10) {
                Picker("Nutzung", selection: Binding($request.usageType, "Eigenbedarf")) {
                    ForEach(usageTypes, id: \.self) { type in
                        Text(type).tag(Optional(type))
                    }
                }
                .pickerStyle(.segmented)

                Text("Diese Information hilft Phasir, Energie-, Sicherheits- und Finanzempfehlungen auf Eigenbedarf oder Vermietung zuzuschneiden.")
                    .font(.caption)
                    .foregroundColor(Color.phasirSecondaryText)
            }
        }
        .phasirCard()
    }

    private var energyProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wohn- & Energieprofil")
                .font(.phasirSectionTitle)

            VStack(spacing: 10) {
                TextField("Wohnfläche (m²)", text: $livingAreaText)
                    .keyboardType(.numberPad)
                    .textFieldStylePhasir()

                TextField("Anzahl Bewohner", text: $residentsCountText)
                    .keyboardType(.numberPad)
                    .textFieldStylePhasir()

                TextField("Haustyp (z.B. EFH, MFH, Wohnung)", text: Binding($request.propertyType, ""))
                    .textFieldStylePhasir()

                TextField("Dämmstandard (z.B. KfW, unsaniert, gut gedämmt)", text: Binding($request.insulationLevel, ""))
                    .textFieldStylePhasir()

                TextField("Fensterverglasung (z.B. zweifach, dreifach)", text: Binding($request.windowGlazing, ""))
                    .textFieldStylePhasir()

                Toggle("PV-/Solaranlage vorhanden", isOn: Binding($request.hasSolarPanels, false))

                TextField("Energieausweis-Klasse (z.B. A+, B, C)", text: Binding($request.energyCertificateClass, ""))
                    .textFieldStylePhasir()

                TextField("Jahresverbrauch (kWh, geschätzt)", text: $estimatedAnnualEnergyConsumptionText)
                    .keyboardType(.decimalPad)
                    .textFieldStylePhasir()

                TextField("Komfortpräferenz (z.B. eher warm, neutral)", text: Binding($request.comfortPreference, ""))
                    .textFieldStylePhasir()
            }
        }
        .phasirCard()
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sicherheitsprofil")
                .font(.phasirSectionTitle)

            VStack(spacing: 10) {
                TextField("Haustür-Sicherheit (z.B. RC2, Mehrfachverriegelung)", text: Binding($request.doorSecurityLevel, ""))
                    .textFieldStylePhasir()

                Toggle("Fenstersicherungen im Erdgeschoss", isOn: Binding($request.hasGroundFloorWindowSecurity, false))
                Toggle("Alarmanlage vorhanden", isOn: Binding($request.hasAlarmSystem, false))
                Toggle("Kameras / Videoüberwachung", isOn: Binding($request.hasCameras, false))
                Toggle("Außenbeleuchtung mit Bewegungsmelder", isOn: Binding($request.hasMotionLightsOutside, false))
                Toggle("Rauchmelder in allen relevanten Räumen", isOn: Binding($request.hasSmokeDetectorsAllRooms, false))
                Toggle("CO₂ / CO-Melder vorhanden", isOn: Binding($request.hasCO2Detector, false))

                TextField("Nachbarschafts-Risiko (z.B. niedrig, mittel, hoch)", text: Binding($request.neighbourhoodRiskLevel, ""))
                    .textFieldStylePhasir()
            }
        }
        .phasirCard()
    }

    private var heatingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heizung")
                .font(.phasirSectionTitle)

            VStack(spacing: 10) {
                Picker("Heizungstyp", selection: $request.heatingType) {
                    ForEach(heatingTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }

                Stepper("Heizung Einbaujahr: \(request.heatingInstallYear)",
                        value: $request.heatingInstallYear,
                        in: 1900...2100)

                DatePicker(
                    "Letzte Heizungswartung",
                    selection: Binding($request.lastHeatingService, Date()),
                    displayedComponents: .date
                )
            }
        }
        .phasirCard()
    }

    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dach, Fenster & Rauchmelder")
                .font(.phasirSectionTitle)

            VStack(spacing: 10) {
                Stepper("Dach Einbaujahr: \(request.roofInstallYear)",
                        value: $request.roofInstallYear,
                        in: 1900...2100)

                DatePicker(
                    "Letzte Dachprüfung",
                    selection: Binding($request.lastRoofCheck, Date()),
                    displayedComponents: .date
                )

                Stepper("Fenster Einbaujahr: \(request.windowInstallYear)",
                        value: $request.windowInstallYear,
                        in: 1900...2100)

                DatePicker(
                    "Letzte Rauchmelderprüfung",
                    selection: Binding($request.lastSmokeCheck, Date()),
                    displayedComponents: .date
                )
            }
        }
        .phasirCard()
    }

    private var financeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Finanzen (optional)")
                    .font(.phasirSectionTitle)
                Spacer()
            }

            DisclosureGroup(isExpanded: $isFinanceExpanded) {
                VStack(spacing: 12) {
                    // Kauf & Finanzierung
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kauf & Finanzierung")
                            .font(.caption)
                            .foregroundColor(Color.phasirSecondaryText)

                        TextField("Kaufpreis (€)", text: $purchasePriceText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()

                        TextField("Monatliche Kreditrate (€)", text: $loanMonthlyPaymentText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()

                        TextField("Verbleibende Darlehenssumme (€)", text: $remainingLoanAmountText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()

                        TextField("Zinssatz (%)", text: $interestRateText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()
                    }

                    Divider().padding(.vertical, 4)

                    // Miete
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mieteinnahmen (falls vermietet)")
                            .font(.caption)
                            .foregroundColor(Color.phasirSecondaryText)

                        TextField("Kaltmiete pro Monat (€)", text: $monthlyRentColdText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()

                        TextField("Warmmiete pro Monat (€)", text: $monthlyRentWarmText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()

                        TextField("Erwartete Leerstandsquote (%)", text: $expectedVacancyRateText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()
                    }

                    Divider().padding(.vertical, 4)

                    // Laufende Kosten
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Laufende Kosten")
                            .font(.caption)
                            .foregroundColor(Color.phasirSecondaryText)

                        TextField("Nebenkosten (Strom, Gas, Wasser) mtl. (€)", text: $monthlyUtilitiesText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()

                        TextField("Hausgeld / WEG mtl. (€)", text: $monthlyHoaFeesText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()

                        TextField("Versicherung pro Jahr (€)", text: $insurancePerYearText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()

                        TextField("Wartungsbudget pro Jahr (€)", text: $maintenanceBudgetPerYearText)
                            .keyboardType(.decimalPad)
                            .textFieldStylePhasir()
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
