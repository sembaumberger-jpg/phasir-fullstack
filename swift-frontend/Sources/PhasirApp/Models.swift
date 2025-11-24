import Foundation

struct House: Identifiable, Codable, Hashable {
    let id: String
    let ownerName: String?
    let name: String
    let address: String
    let buildYear: Int
    let heatingType: String
    let heatingInstallYear: Int
    let lastHeatingService: Date?
    let roofInstallYear: Int
    let lastRoofCheck: Date?
    let windowInstallYear: Int
    let lastSmokeCheck: Date?
    let next: NextServiceDates?
}

struct NextServiceDates: Codable, Hashable {
    let heating: Date
    let roof: Date
    let windows: Date
    let smoke: Date
}

struct CreateHouseRequest: Encodable {
    var ownerName: String = ""
    var name: String = ""
    var address: String = ""
    var buildYear: Int = Calendar.current.component(.year, from: Date())
    var heatingType: String = ""
    var heatingInstallYear: Int = Calendar.current.component(.year, from: Date())
    var lastHeatingService: Date = Date()
    var roofInstallYear: Int = Calendar.current.component(.year, from: Date())
    var lastRoofCheck: Date? = nil
    var windowInstallYear: Int = Calendar.current.component(.year, from: Date())
    var lastSmokeCheck: Date = Date()
}
