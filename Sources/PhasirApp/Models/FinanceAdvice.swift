import Foundation

struct FinanceAdvice: Codable {
    let monthlyIncome: Double
    let monthlyCosts: Double
    let netCashflow: Double
    let grossYieldPercent: Double?
    let riskLevel: String          // "Low", "Medium", "High", "Owner-Occupied"
    let summary: String
    let insights: [String]
    let recommendedActions: [String]
}
