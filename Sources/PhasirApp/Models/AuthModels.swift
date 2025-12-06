import Foundation

/// Raw-Response vom Backend
/// { "token": "...", "userId": "...", "email": "..." }
struct AuthResponse: Codable {
    let token: String
    let userId: String
    let email: String
}

/// Session, die in der App gehalten wird
struct AuthSession: Codable {
    let token: String
    let userId: String
    let email: String
}

struct DeviceRegistration: Codable {
    let deviceToken: String
    let platform: String
}
