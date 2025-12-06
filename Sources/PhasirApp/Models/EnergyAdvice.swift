import Foundation

struct EnergyAdvice: Codable {
    let score: String           // "A", "B", "C", "D"
    let numericScore: Int       // 0-100
    let summary: String         // kurze Zusammenfassung
    let insights: [String]      // erklärende Punkte
    let recommendedActions: [String] // konkrete Maßnahmen
    let potentialSavingsKwh: Double?
    let potentialSavingsEuro: Double?
}
