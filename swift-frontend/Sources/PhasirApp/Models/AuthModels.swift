import Foundation

struct AuthResponse: Codable {
    let token: String
    let userId: String
}

struct AuthSession: Codable {
    let token: String
    let userId: String
}

struct DeviceRegistration: Codable {
    let deviceToken: String
    let platform: String
}
