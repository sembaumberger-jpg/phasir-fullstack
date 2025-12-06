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
}
