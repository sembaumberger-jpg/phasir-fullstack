import Foundation

struct NextMaintenance: Codable {
    let heating: Date?
    let roof: Date?
    let windows: Date?
    let smoke: Date?
}

struct House: Codable, Identifiable {
    let id: String
    let ownerId: String?
    var ownerName: String?
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

    var earliestUpcomingMaintenance: Date? {
        let dates = [next?.heating, next?.roof, next?.windows, next?.smoke].compactMap { $0 }
        return dates.min()
    }
}

struct CreateHouseRequest: Codable {
    var ownerName: String = ""
    var name: String = ""
    var address: String = ""
    var buildYear: Int = Calendar.current.component(.year, from: Date())
    var heatingType: String = "Gas"
    var heatingInstallYear: Int = Calendar.current.component(.year, from: Date())
    var lastHeatingService: Date? = nil
    var roofInstallYear: Int = Calendar.current.component(.year, from: Date())
    var lastRoofCheck: Date? = nil
    var windowInstallYear: Int = Calendar.current.component(.year, from: Date())
    var lastSmokeCheck: Date? = nil
}

struct UpdateHouseRequest: Codable {
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
}
