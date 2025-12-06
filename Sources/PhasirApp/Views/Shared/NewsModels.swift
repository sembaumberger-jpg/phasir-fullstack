import Foundation

struct RealEstateNewsResponse: Decodable {
    let source: String
    let articles: [NewsArticle]
}

struct NewsArticle: Identifiable, Decodable {
    let id: String
    let title: String
    let summary: String?
    let source: String?
    let url: String?
    let imageUrl: String?
    let publishedAt: String?
}
