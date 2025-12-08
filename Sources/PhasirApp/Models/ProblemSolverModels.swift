import Foundation
import CoreLocation

/// KI-Diagnose des Problems.
/// Enthält die wesentlichen Informationen für die Problem-Einschätzung.
struct ProblemDiagnosis: Codable {
    let category: String
    let urgency: Int
    let likelyCause: String
    let recommendedAction: String
    let houseName: String?
    let houseAddress: String?
    /// Sofortmaßnahmen, die der Eigentümer direkt ausführen kann
    let firstAidSteps: [String]?
}

/// Dienstleister / Vendor in der Nähe.
struct Vendor: Codable, Identifiable {
    let id: String
    let name: String
    let lat: Double?
    let lng: Double?
    let rating: Double?
    let phone: String?
    let website: String?
    let address: String?
    let distanceKm: Double?

    /// Optional: Hilfs-Property zur Nutzung in MapKit.
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lng = lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

/// Vorhersage möglicher zukünftiger Probleme für ein Haus
struct ProblemPrediction: Codable, Identifiable {
    let id = UUID()
    let system: String
    let summary: String
    let recommendation: String
    let severity: String
    let projectedYear: Int
}

/// Sammlung aller prognostizierten Probleme eines Hauses
/// Sammlung aller prognostizierten Probleme eines Hauses
///
/// Der Server liefert die Felder `houseId` und `houseName`, daher werden sie mit
/// CodingKeys auf die Properties `id` und `name` gemappt. Ohne diese explizite
/// Zuordnung schlägt die Decodierung fehl ("keyNotFound"), weil `id` nicht im
/// JSON vorhanden ist.
struct HouseProblemRadar: Codable, Identifiable {
    let id: String
    let name: String
    let issues: [ProblemPrediction]
    
    private enum CodingKeys: String, CodingKey {
        case id = "houseId"
        case name = "houseName"
        case issues
    }
}

/// Antwort des Problemradar-Endpunkts
struct ProblemRadarResponse: Codable {
    let houses: [HouseProblemRadar]?
    let houseId: String?
    let houseName: String?
    let issues: [ProblemPrediction]?
}

/// Wrapper für die Vendor-Response des Backends.
struct VendorResponse: Codable {
    let vendors: [Vendor]
}
