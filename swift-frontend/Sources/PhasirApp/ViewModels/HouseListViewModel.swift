import Foundation

@MainActor
final class HouseListViewModel: ObservableObject {
    @Published private(set) var houses: [House] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient: ApiClient

    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await apiClient.fetchHouses()
            houses = fetched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func addHouse(_ request: CreateHouseRequest) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let house = try await apiClient.createHouse(request)
            houses.append(house)
            houses.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func updateHouse(_ house: House, with request: UpdateHouseRequest) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let updated = try await apiClient.updateHouse(id: house.id, with: request)
            if let index = houses.firstIndex(where: { $0.id == updated.id }) {
                houses[index] = updated
            }
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }
}
