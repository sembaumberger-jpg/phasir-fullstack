import Foundation

struct NextMaintenance: Codable {
    let heating: Date
    let roof: Date
    let windows: Date
    let smoke: Date
}

struct House: Codable, Identifiable {
    let id: String
    var ownerName: String
    var name: String
    var address: String
    var buildYear: Int
    var heatingType: String
    var heatingInstallYear: Int
    var lastHeatingService: Date
    var roofInstallYear: Int
    var lastRoofCheck: Date?
    var windowInstallYear: Int
    var lastSmokeCheck: Date
    var next: NextMaintenance
}

struct CreateHousePayload: Encodable {
    var ownerName: String
    var name: String
    var address: String
    var buildYear: Int
    var heatingType: String
    var heatingInstallYear: Int
    var lastHeatingService: Date
    var roofInstallYear: Int
    var lastRoofCheck: Date?
    var windowInstallYear: Int
    var lastSmokeCheck: Date
}
