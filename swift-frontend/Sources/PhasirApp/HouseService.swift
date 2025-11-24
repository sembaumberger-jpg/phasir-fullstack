import Foundation
import SwiftUI

@MainActor
final class HouseService: ObservableObject {
    @Published private(set) var houses: [House] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService

    init(apiService: ApiService) {
        self.api = apiService
    }

    func loadHouses() async {
        await perform {
            let response: [House] = try await api.get("/houses")
            self.houses = response.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    func createHouse(_ request: CreateHouseRequest) async {
        await perform {
            let created: House = try await api.post("/houses", body: request)
            if let index = houses.firstIndex(where: { $0.id == created.id }) {
                houses[index] = created
            } else {
                houses.append(created)
            }
            houses.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    func updateHouse(id: String, with request: CreateHouseRequest) async {
        await perform {
            let updated: House = try await api.put("/houses/\(id)", body: request)
            if let index = houses.firstIndex(where: { $0.id == id }) {
                houses[index] = updated
            }
        }
    }

    private func perform(_ block: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            try await block()
        } catch {
            if let error = error as? LocalizedError, let description = error.errorDescription {
                errorMessage = description
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}
