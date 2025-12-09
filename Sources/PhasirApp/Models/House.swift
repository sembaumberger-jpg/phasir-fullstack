import Foundation

// MARK: - Nächste Wartungen

struct NextMaintenance: Codable, Hashable {
    let heating: Date?
    let roof: Date?
    let windows: Date?
    let smoke: Date?
}

// MARK: - House Modell (inkl. Energie, Sicherheit, Finanzen)

struct House: Codable, Identifiable, Hashable {
    let id: String
    let ownerId: String?
    var ownerName: String?

    // Basis
    var name: String
    var address: String
    var buildYear: Int
    var heatingType: String
    var heatingInstallYear: Int
    var lastHeatingService: Date?
    var roofInstallYear: Int
    var lastRoofCheck: Date?
    var windowInstallYear: Int
    var lastSmokeCheck: Date?
    var next: NextMaintenance?

    // Energie / Wohnprofil
    var livingArea: Int?
    var residentsCount: Int?
    var propertyType: String?
    var insulationLevel: String?
    var windowGlazing: String?
    var hasSolarPanels: Bool?
    var energyCertificateClass: String?
    var estimatedAnnualEnergyConsumption: Double?
    var comfortPreference: String?

    // Sicherheitsprofil
    var doorSecurityLevel: String?
    var hasGroundFloorWindowSecurity: Bool?
    var hasAlarmSystem: Bool?
    var hasCameras: Bool?
    var hasMotionLightsOutside: Bool?
    var hasSmokeDetectorsAllRooms: Bool?
    var hasCO2Detector: Bool?
    var neighbourhoodRiskLevel: String?

    // Nutzung & Finanzen
    /// "Eigenbedarf", "Vermietet (Wohnraum)", "Gewerblich", "Kurzzeitvermietung"
    var usageType: String?

    var monthlyRentCold: Double?
    var monthlyRentWarm: Double?
    var expectedVacancyRate: Double?        // in %, z.B. 5 = 5%

    var monthlyUtilities: Double?           // Nebenkosten (Strom/Gas/Wasser etc.)
    var monthlyHoaFees: Double?             // Hausgeld / WEG-Beiträge
    var insurancePerYear: Double?
    var maintenanceBudgetPerYear: Double?

    var purchasePrice: Double?
    var equity: Double?
    var remainingLoanAmount: Double?
    var interestRate: Double?              // in %, z.B. 3.5
    var loanMonthlyPayment: Double?

    // --- Nebenkosten & Struktur ---
    /// Gibt das Abrechnungsmodell an: "single" (Einfamilienhaus) oder "multi" (Mehrfamilienhaus)
    var billingModel: String?
    /// Anzahl der einzelnen Wohneinheiten im Haus
    var unitCount: Int?
    /// Gibt an, ob es eine gewerbliche Einheit gibt
    var hasCommercialUnit: Bool?
    /// Schlüssel zur Verteilung der Betriebskosten (z.B. "sqm", "people", "units", "consumption")
    var primaryOperatingCostKey: String?
    /// Gibt an, ob ein Hausmeisterdienst vorhanden ist
    var hasCaretakerService: Bool?
    /// Gibt an, ob Gartenpflege als Dienstleistung vorhanden ist
    var hasGardenService: Bool?
    /// Gibt an, ob das Haus über einen Aufzug verfügt
    var hasElevator: Bool?
    /// Gibt an, ob es einen Allgemeinstrom für Gemeinschaftsflächen gibt
    var hasCommonElectricity: Bool?
    /// Gibt an, ob eine Garage oder Stellplatz vorhanden ist
    var hasGarageOrParking: Bool?
    /// Gibt an, ob pro Einheit ein separater Heizkostenzähler vorhanden ist
    var hasHeatMeterPerUnit: Bool?
    /// Gibt an, ob pro Einheit ein separater Wasserkostenzähler vorhanden ist
    var hasWaterMeterPerUnit: Bool?
    /// Summe aller monatlichen Vorauszahlungen für Betriebskosten (in Euro)
    var operatingCostAdvanceTotalPerMonth: Double?
    /// Jahr der letzten Nebenkostenabrechnung
    var lastOperatingCostYear: Int?
    /// Freitextfeld für Anmerkungen zu Betriebskosten oder Besonderheiten
    var operatingCostNotes: String?

    // Hilfs-Property: nächste fällige Wartung
    var earliestUpcomingMaintenance: Date? {
        let dates = [next?.heating, next?.roof, next?.windows, next?.smoke].compactMap { $0 }
        return dates.min()
    }
}

// MARK: - Create / Update Requests

struct CreateHouseRequest: Codable {
    // Basis
    var ownerName: String = ""
    var name: String = ""
    var address: String = ""
    var ownerId: String? = nil
    var buildYear: Int = Calendar.current.component(.year, from: Date())
    var heatingType: String = "Gas"
    var heatingInstallYear: Int = Calendar.current.component(.year, from: Date())

    // Wichtige Defaults, weil das Backend diese Felder voraussetzt:
    var lastHeatingService: Date? = Date()
    var roofInstallYear: Int = Calendar.current.component(.year, from: Date())
    var lastRoofCheck: Date? = nil
    var windowInstallYear: Int = Calendar.current.component(.year, from: Date())
    var lastSmokeCheck: Date? = Date()

    // Energie / Wohnprofil (optional)
    var livingArea: Int? = nil
    var residentsCount: Int? = nil
    var propertyType: String? = nil
    var insulationLevel: String? = nil
    var windowGlazing: String? = nil
    var hasSolarPanels: Bool? = nil
    var energyCertificateClass: String? = nil
    var estimatedAnnualEnergyConsumption: Double? = nil
    var comfortPreference: String? = nil

    // Sicherheitsprofil (optional)
    var doorSecurityLevel: String? = nil
    var hasGroundFloorWindowSecurity: Bool? = nil
    var hasAlarmSystem: Bool? = nil
    var hasCameras: Bool? = nil
    var hasMotionLightsOutside: Bool? = nil
    var hasSmokeDetectorsAllRooms: Bool? = nil
    var hasCO2Detector: Bool? = nil
    var neighbourhoodRiskLevel: String? = nil

    // Nutzung & Finanzen (optional)
    var usageType: String? = "Eigenbedarf"

    var monthlyRentCold: Double? = nil
    var monthlyRentWarm: Double? = nil
    var expectedVacancyRate: Double? = nil

    var monthlyUtilities: Double? = nil
    var monthlyHoaFees: Double? = nil
    var insurancePerYear: Double? = nil
    var maintenanceBudgetPerYear: Double? = nil

    var purchasePrice: Double? = nil
    var equity: Double? = nil
    var remainingLoanAmount: Double? = nil
    var interestRate: Double? = nil
    var loanMonthlyPayment: Double? = nil

    // --- Nebenkosten & Struktur (optional) ---
    /// Abrechnungsmodell: "single" (Einfamilienhaus) oder "multi" (Mehrfamilienhaus)
    var billingModel: String? = nil
    /// Anzahl der einzelnen Wohneinheiten im Haus
    var unitCount: Int? = nil
    /// Ob es eine gewerbliche Einheit gibt
    var hasCommercialUnit: Bool? = nil
    /// Schlüssel zur Verteilung der Betriebskosten ("sqm" | "people" | "units" | "consumption")
    var primaryOperatingCostKey: String? = nil
    /// Hausmeisterdienst vorhanden
    var hasCaretakerService: Bool? = nil
    /// Gartenpflege vorhanden
    var hasGardenService: Bool? = nil
    /// Aufzug vorhanden
    var hasElevator: Bool? = nil
    /// Allgemeinstrom für Gemeinschaftsflächen vorhanden
    var hasCommonElectricity: Bool? = nil
    /// Garage / Stellplatz vorhanden
    var hasGarageOrParking: Bool? = nil
    /// Heizkostenzähler pro Einheit vorhanden
    var hasHeatMeterPerUnit: Bool? = nil
    /// Wasserkostenzähler pro Einheit vorhanden
    var hasWaterMeterPerUnit: Bool? = nil
    /// Summe der monatlichen Betriebskostenvorauszahlungen (in Euro)
    var operatingCostAdvanceTotalPerMonth: Double? = nil
    /// Jahr der letzten Nebenkostenabrechnung
    var lastOperatingCostYear: Int? = nil
    /// Freitextfeld für Betriebskostenanmerkungen
    var operatingCostNotes: String? = nil
}

struct UpdateHouseRequest: Codable {
    // Basis
    var ownerName: String?
    var name: String?
    var address: String?
    var buildYear: Int?
    var heatingType: String?
    var heatingInstallYear: Int?
    var lastHeatingService: Date?
    var roofInstallYear: Int?
    var lastRoofCheck: Date?
    var windowInstallYear: Int?
    var lastSmokeCheck: Date?

    // Energie / Wohnprofil
    var livingArea: Int?
    var residentsCount: Int?
    var propertyType: String?
    var insulationLevel: String?
    var windowGlazing: String?
    var hasSolarPanels: Bool?
    var energyCertificateClass: String?
    var estimatedAnnualEnergyConsumption: Double?
    var comfortPreference: String?

    // Sicherheitsprofil
    var doorSecurityLevel: String?
    var hasGroundFloorWindowSecurity: Bool?
    var hasAlarmSystem: Bool?
    var hasCameras: Bool?
    var hasMotionLightsOutside: Bool?
    var hasSmokeDetectorsAllRooms: Bool?
    var hasCO2Detector: Bool?
    var neighbourhoodRiskLevel: String?

    // Nutzung & Finanzen
    var usageType: String?

    var monthlyRentCold: Double?
    var monthlyRentWarm: Double?
    var expectedVacancyRate: Double?

    var monthlyUtilities: Double?
    var monthlyHoaFees: Double?
    var insurancePerYear: Double?
    var maintenanceBudgetPerYear: Double?

    var purchasePrice: Double?
    var equity: Double?
    var remainingLoanAmount: Double?
    var interestRate: Double?
    var loanMonthlyPayment: Double?

    // --- Nebenkosten & Struktur ---
    var billingModel: String?
    var unitCount: Int?
    var hasCommercialUnit: Bool?
    var primaryOperatingCostKey: String?
    var hasCaretakerService: Bool?
    var hasGardenService: Bool?
    var hasElevator: Bool?
    var hasCommonElectricity: Bool?
    var hasGarageOrParking: Bool?
    var hasHeatMeterPerUnit: Bool?
    var hasWaterMeterPerUnit: Bool?
    var operatingCostAdvanceTotalPerMonth: Double?
    var lastOperatingCostYear: Int?
    var operatingCostNotes: String?
}
