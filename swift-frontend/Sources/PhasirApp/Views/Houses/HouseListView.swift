import SwiftUI

struct HouseListView: View {
    @StateObject var viewModel: HouseListViewModel
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    if viewModel.houses.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else {
                        ForEach(viewModel.houses) { house in
                            NavigationLink(destination: HouseDetailView(house: house, viewModel: viewModel)) {
                                HouseCardView(house: house)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Immobilien")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showCreate) {
                NavigationStack {
                    HouseFormView(mode: .create) { request in
                        await viewModel.addHouse(request)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Lade Immobilien")
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Keine Immobilien")
                .font(.headline)
            Text("Fügen Sie Ihr erstes Objekt hinzu.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }
}

struct HouseCardView: View {
    let house: House

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(house.name)
                        .font(.headline)
                    Text(house.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "house.fill")
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 16) {
                infoLabel(title: "Baujahr", value: String(house.buildYear))
                infoLabel(title: "Heizung", value: house.heatingType)
            }

            if let next = house.earliestUpcomingMaintenance {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(.orange)
                    Text("Nächste Wartung: \(next.formatted(date: .abbreviated, time: .omitted))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }

    private func infoLabel(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold))
        }
    }
}
