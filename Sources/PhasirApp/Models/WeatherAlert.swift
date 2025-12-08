import Foundation

/// Modell für Wetterwarnungen, basierend auf der Bright‑Sky‑API.
/// Dieses Modell repräsentiert eine einzelne Warnmeldung und
/// mappt die wichtigsten Felder aus der Antwort des Express‑Backends.
struct WeatherAlert: Identifiable, Codable {
    /// Interne ID von Bright‑Sky
    let id: Int
    /// Überschrift auf Deutsch
    let headlineDe: String?
    /// Kategorisierung der Warnung (z. B. „met“ für meteorologisch)
    let category: String?
    /// Schweregrad der Warnung („minor“, „moderate“, „severe“, „extreme“)
    let severity: String?
    /// Detaillierte Beschreibung (Deutsch)
    let descriptionDe: String?
    /// Code für das Ereignis (DWD‑Code)
    let eventCode: Int?
    /// Ereignisbezeichnung (Deutsch)
    let eventDe: String?
    /// Beginn der Warnung
    let onset: Date?
    /// Ablauf der Warnung
    let expires: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case headlineDe = "headline_de"
        case category
        case severity
        case descriptionDe = "description_de"
        case eventCode = "event_code"
        case eventDe = "event_de"
        case onset
        case expires
    }
}
