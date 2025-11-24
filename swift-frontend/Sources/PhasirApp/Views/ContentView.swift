import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var service: HouseService

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading && service.houses.isEmpty {
                    ProgressView("Lade Häuser…")
                } else {
                    List(service.houses) { house in
                        NavigationLink(destination: HouseDetailView(house: house, dateFormatter: dateFormatter)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(house.name)
                                    .font(.headline)
                                Text(house.address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Label("Heizung: \(house.next.heating, formatter: dateFormatter)", systemImage: "flame")
                                    Label("Dach: \(house.next.roof, formatter: dateFormatter)", systemImage: "house")
                                }
                                .font(.caption)
                            }
                        }
                    }
                    .refreshable {
                        await service.fetchHouses()
                    }
                }
            }
            .navigationTitle("Phasir Häuser")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { Task { await service.createDemoHouse() } }) {
                        Label("Demo-Haus", systemImage: "plus")
                    }
                }
            }
            .task {
                await service.fetchHouses()
            }
            .alert("Fehler", isPresented: Binding<Bool>(
                get: { service.errorMessage != nil },
                set: { _ in service.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) { service.errorMessage = nil }
            } message: {
                Text(service.errorMessage ?? "")
            }
        }
    }
}

struct HouseDetailView: View {
    let house: House
    let dateFormatter: DateFormatter

    var body: some View {
        Form {
            Section("Details") {
                Label(house.ownerName, systemImage: "person")
                Label(house.address, systemImage: "mappin.and.ellipse")
                Label("Baujahr: \(house.buildYear)", systemImage: "hammer")
                Label("Heizung: \(house.heatingType) (\(house.heatingInstallYear))", systemImage: "flame")
            }

            Section("Letzte Wartungen") {
                Label("Heizung: \(house.lastHeatingService, formatter: dateFormatter)", systemImage: "wrench.and.screwdriver")
                Label("Dach: \(house.lastRoofCheck ?? house.lastHeatingService, formatter: dateFormatter)", systemImage: "house")
                Label("Rauchmelder: \(house.lastSmokeCheck, formatter: dateFormatter)", systemImage: "alarm")
            }

            Section("Nächste Fälligkeiten") {
                Label("Heizung: \(house.next.heating, formatter: dateFormatter)", systemImage: "calendar")
                Label("Dach: \(house.next.roof, formatter: dateFormatter)", systemImage: "calendar")
                Label("Fenster: \(house.next.windows, formatter: dateFormatter)", systemImage: "calendar")
                Label("Rauchmelder: \(house.next.smoke, formatter: dateFormatter)", systemImage: "calendar")
            }
        }
        .navigationTitle(house.name)
    }
}

#Preview {
    ContentView()
        .environmentObject(HouseService(baseURL: URL(string: "http://localhost:4000")!))
}
