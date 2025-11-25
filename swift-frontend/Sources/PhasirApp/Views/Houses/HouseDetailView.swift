import SwiftUI

struct HouseDetailView: View {
    let house: House
    @ObservedObject var viewModel: HouseListViewModel
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                section(title: "Objektdaten") {
                    detailRow(title: "Adresse", value: house.address)
                    detailRow(title: "Baujahr", value: String(house.buildYear))
                    detailRow(title: "Heizungsart", value: house.heatingType)
                    detailRow(title: "Eigentümer", value: house.ownerName ?? "–")
                }

                section(title: "Wartungsübersicht") {
                    maintenanceRow(symbol: "flame.fill", title: "Heizung", last: house.lastHeatingService, next: house.next?.heating)
                    maintenanceRow(symbol: "roof.fill", title: "Dach", last: house.lastRoofCheck, next: house.next?.roof)
                    maintenanceRow(symbol: "window.vertical.closed", title: "Fenster", last: nil, next: house.next?.windows)
                    maintenanceRow(symbol: "alarm", title: "Rauchmelder", last: house.lastSmokeCheck, next: house.next?.smoke)
                }

                if let next = house.earliestUpcomingMaintenance {
                    section(title: "Nächste fällige Maßnahmen") {
                        detailRow(title: "Fällig ab", value: next.formatted(date: .long, time: .omitted))
                        Text("Planen Sie eine Wartung rechtzeitig, um Ausfälle zu vermeiden.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    showEdit = true
                } label: {
                    Text("Wartung aktualisieren")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.label)))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationTitle(house.name)
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                HouseFormView(mode: .edit(existing: house)) { request in
                    let update = UpdateHouseRequest(
                        ownerName: request.ownerName,
                        name: request.name,
                        address: request.address,
                        buildYear: request.buildYear,
                        heatingType: request.heatingType,
                        heatingInstallYear: request.heatingInstallYear,
                        lastHeatingService: request.lastHeatingService,
                        roofInstallYear: request.roofInstallYear,
                        lastRoofCheck: request.lastRoofCheck,
                        windowInstallYear: request.windowInstallYear,
                        lastSmokeCheck: request.lastSmokeCheck
                    )
                    return await viewModel.updateHouse(house, with: update)
                }
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(spacing: 12) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }

    private func maintenanceRow(symbol: String, title: String, last: Date?, next: Date?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(.gray)
                Text(title).font(.subheadline.weight(.semibold))
            }
            detailRow(title: "Letzte Wartung", value: formatted(date: last))
            detailRow(title: "Nächste Fälligkeit", value: formatted(date: next))
        }
    }

    private func formatted(date: Date?) -> String {
        guard let date else { return "–" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
