import Foundation

struct RentBenchmarkAdvice: Codable {
    struct PortfolioSummary: Codable {
        let averageRentPerSqm: Double?
        let estimatedMarketRentPerSqm: Double?
        let averageDeviationPercent: Double?
        let rating: String
        let summary: String
    }

    struct HouseEntry: Codable, Identifiable, Hashable {
        let id: String
        let name: String
        let address: String
        let livingArea: Int?
        let monthlyRentCold: Double?
        let rentPerSqm: Double?
        let estimatedMarketRentPerSqm: Double?
        let deviationPercent: Double?
        let rating: String
    }

    let portfolio: PortfolioSummary
    let houses: [HouseEntry]
    let recommendations: [String]
}
