import Foundation
import CoreLocation

/// KI-Diagnose des Problems.
/// Enthält die wesentlichen Informationen für die Problem-Einschätzung.
public struct ProblemDiagnosis: Codable {
    public let category: String
    public let urgency: Int
    public let likelyCause: String
    public let recommendedAction: String
    public let houseName: String?
    public let houseAddress: String?
}

/// Dienstleister / Vendor in der Nähe.
public struct Vendor: Codable, Identifiable {
    public let id: String
    public let name: String
    public let lat: Double?
    public let lng: Double?
    public let rating: Double?
    public let phone: String?
    public let website: String?
    public let address: String?
    public let distanceKm: Double?

    /// Optional: Hilfs-Property zur Nutzung in MapKit.
    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lng = lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

/// Wrapper für die Vendor-Response des Backends.
public struct VendorResponse: Codable {
    public let vendors: [Vendor]
}
