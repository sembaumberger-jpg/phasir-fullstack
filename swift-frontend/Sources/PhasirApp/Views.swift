import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var houseService: HouseService
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            HouseListView()
                .navigationTitle("Häuser")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("Haus anlegen", systemImage: "plus")
                        }
                    }
                }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateHouseView(isPresented: $showCreateSheet)
                .environmentObject(houseService)
        }
    }
}

struct HouseListView: View {
    @EnvironmentObject private var houseService: HouseService

    var body: some View {
        Group {
            if houseService.houses.isEmpty && !houseService.isLoading {
                VStack(spacing: 12) {
                    Text("Keine Häuser gefunden")
                        .font(.headline)
                    if let error = houseService.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if let error = houseService.errorMessage {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                        }
                    }

                    ForEach(houseService.houses) { house in
                        NavigationLink(destination: HouseDetailView(house: house)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(house.name)
                                    .font(.headline)
                                Text(house.address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .overlay(alignment: .center) {
                    if houseService.isLoading {
                        ProgressView("Lade Häuser...")
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .task {
            await houseService.loadHouses()
        }
        .refreshable {
            await houseService.loadHouses()
        }
    }
}

struct HouseDetailView: View {
    let house: House

    var body: some View {
        Form {
            Section("Allgemein") {
                LabeledContent("Eigentümer", value: house.ownerName ?? "–")
                LabeledContent("Adresse", value: house.address)
                LabeledContent("Baujahr", value: String(house.buildYear))
            }

            Section("Heizung") {
                LabeledContent("Typ", value: house.heatingType)
                LabeledContent("Einbau", value: String(house.heatingInstallYear))
                dateRow(title: "Letzte Wartung", date: house.lastHeatingService)
                if let next = house.next?.heating {
                    dateRow(title: "Nächste Wartung", date: next)
                }
            }

            Section("Dach & Fenster") {
                LabeledContent("Dacheinbau", value: String(house.roofInstallYear))
                dateRow(title: "Letzte Dachprüfung", date: house.lastRoofCheck)
                if let next = house.next?.roof {
                    dateRow(title: "Nächste Dachprüfung", date: next)
                }

                LabeledContent("Fenster Einbau", value: String(house.windowInstallYear))
                if let next = house.next?.windows {
                    dateRow(title: "Nächster Fenstertausch", date: next)
                }
            }

            Section("Rauchmelder") {
                dateRow(title: "Letzte Prüfung", date: house.lastSmokeCheck)
                if let next = house.next?.smoke {
                    dateRow(title: "Nächste Prüfung", date: next)
                }
            }
        }
        .navigationTitle(house.name)
    }

    @ViewBuilder
    private func dateRow(title: String, date: Date?) -> some View {
        if let date {
            LabeledContent(title, value: date.formatted(date: .numeric, time: .omitted))
        } else {
            LabeledContent(title, value: "–")
        }
    }
}

struct CreateHouseView: View {
    @EnvironmentObject private var houseService: HouseService
    @Binding var isPresented: Bool
    @State private var request = CreateHouseRequest()
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Allgemein") {
                    TextField("Name", text: $request.name)
                    TextField("Eigentümer", text: $request.ownerName)
                    TextField("Adresse", text: $request.address)
                    Stepper("Baujahr: \(request.buildYear)", value: $request.buildYear, in: 1800...2100)
                }

                Section("Heizung") {
                    TextField("Typ", text: $request.heatingType)
                    Stepper("Einbaujahr: \(request.heatingInstallYear)", value: $request.heatingInstallYear, in: 1900...2100)
                    DatePicker("Letzte Wartung", selection: $request.lastHeatingService, displayedComponents: .date)
                }

                Section("Dach & Fenster") {
                    Stepper("Dacheinbau: \(request.roofInstallYear)", value: $request.roofInstallYear, in: 1900...2100)
                    DatePicker("Letzte Dachprüfung", selection: Binding($request.lastRoofCheck, Date()))
                    Stepper("Fenster Einbau: \(request.windowInstallYear)", value: $request.windowInstallYear, in: 1900...2100)
                }

                Section("Rauchmelder") {
                    DatePicker("Letzte Prüfung", selection: $request.lastSmokeCheck, displayedComponents: .date)
                }

                if let error = houseService.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Neues Haus")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submit) {
                        if houseService.isLoading {
                            ProgressView()
                        } else {
                            Text("Speichern")
                        }
                    }
                    .disabled(houseService.isLoading)
                }
            }
            .alert("Fehler", isPresented: $showError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(houseService.errorMessage ?? "Unbekannter Fehler")
            })
        }
    }

    private func submit() {
        Task {
            await houseService.createHouse(request)
            if houseService.errorMessage == nil {
                isPresented = false
            } else {
                showError = true
            }
        }
    }
}

private extension Binding where Value == Date? {
    init(_ source: Binding<Date?>, _ fallback: Date) {
        self.init(get: {
            source.wrappedValue ?? fallback
        }, set: { newValue in
            source.wrappedValue = newValue
        })
    }
}
