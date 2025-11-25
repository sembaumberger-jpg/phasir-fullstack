import SwiftUI

struct HouseFormView: View {
    enum Mode {
        case create
        case edit(existing: House)

        var title: String {
            switch self {
            case .create: return "Neue Immobilie"
            case .edit: return "Immobilie bearbeiten"
            }
        }
    }

    let mode: Mode
    var onSubmit: (CreateHouseRequest) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var request = CreateHouseRequest()
    @State private var isSubmitting = false

    private let heatingTypes = ["Gas", "Öl", "Wärmepumpe", "Fernwärme", "Solar", "Elektrisch"]

    init(mode: Mode, onSubmit: @escaping (CreateHouseRequest) async -> Bool) {
        self.mode = mode
        self.onSubmit = onSubmit
        if case let .edit(existing) = mode {
            _request = State(initialValue: CreateHouseRequest(
                ownerName: existing.ownerName ?? "",
                name: existing.name,
                address: existing.address,
                buildYear: existing.buildYear,
                heatingType: existing.heatingType,
                heatingInstallYear: existing.heatingInstallYear,
                lastHeatingService: existing.lastHeatingService,
                roofInstallYear: existing.roofInstallYear,
                lastRoofCheck: existing.lastRoofCheck,
                windowInstallYear: existing.windowInstallYear,
                lastSmokeCheck: existing.lastSmokeCheck
            ))
        }
    }

    var body: some View {
        Form {
            Section("Objekt") {
                TextField("Name", text: $request.name)
                TextField("Adresse", text: $request.address)
                TextField("Eigentümer", text: $request.ownerName)
                Stepper("Baujahr: \(request.buildYear)", value: $request.buildYear, in: 1800...2100)
            }

            Section("Heizung") {
                Picker("Typ", selection: $request.heatingType) {
                    ForEach(heatingTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                Stepper("Einbaujahr: \(request.heatingInstallYear)", value: $request.heatingInstallYear, in: 1900...2100)
                DatePicker("Letzte Wartung", selection: Binding($request.lastHeatingService, Date()), displayedComponents: .date)
            }

            Section("Dach & Fenster") {
                Stepper("Dacheinbau: \(request.roofInstallYear)", value: $request.roofInstallYear, in: 1900...2100)
                DatePicker("Letzte Dachprüfung", selection: Binding($request.lastRoofCheck, Date()), displayedComponents: .date)
                Stepper("Fenster Einbau: \(request.windowInstallYear)", value: $request.windowInstallYear, in: 1900...2100)
            }

            Section("Rauchmelder") {
                DatePicker("Letzte Prüfung", selection: Binding($request.lastSmokeCheck, Date()), displayedComponents: .date)
            }
        }
        .navigationTitle(mode.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen", role: .cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: submit) {
                    if isSubmitting { ProgressView() } else { Text("Speichern") }
                }
                .disabled(isSubmitting)
            }
        }
    }

    private func submit() {
        Task {
            isSubmitting = true
            let success = await onSubmit(request)
            isSubmitting = false
            if success { dismiss() }
        }
    }
}

private extension Binding where Value == Date? {
    init(_ source: Binding<Date?>, _ fallback: Date) {
        self.init(get: { source.wrappedValue ?? fallback }, set: { newValue in
            source.wrappedValue = newValue
        })
    }
}
