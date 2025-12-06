import Foundation

struct RepairAdvice: Codable {
    /// z.B. "heating", "electric", "water", "general"
    let systemType: String
    /// "low", "medium", "high" – wird in der UI als Badge angezeigt
    let riskLevel: String
    /// kurze Zusammenfassung der Lage
    let summary: String
    /// Dinge, die der Nutzer prüfen / beobachten kann
    let checks: [String]
    /// Konkrete Handlungsempfehlungen
    let recommendedActions: [String]
    /// Sicherheits-Hinweise (z.B. "Strom abstellen", "Fachbetrieb rufen")
    let safetyHints: [String]
}
