import SwiftUI
import MapKit

/// Ein Screen für den neuen USP: Probleme beschreiben, KI analysiert, passende Dienstleister zeigen.
public struct ProblemSolverView: View {
    /// Das aktuelle Haus, zu dem das Problem beschrieben wird.
    public let house: House

    @State private var descriptionText: String = ""
    @State private var diagnosis: ProblemDiagnosis?
    @State private var vendors: [Vendor] = []
    @State private var isLoadingDiagnosis: Bool = false
    @State private var isLoadingVendors: Bool = false
    @State private var errorMessage: String?
    @State private var mapRegion: MKCoordinateRegion?

    @Environment(\.openURL) private var openURL

    public init(house: House) {
        self.house = house
    }

    public var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    descriptionCard
                    if let diagnosis = diagnosis {
                        diagnosisCard(diagnosis)
                    }
                    if !vendors.isEmpty {
                        vendorMapCard
                        vendorListCard
                    }
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.phasirCaption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Problem lösen")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Problem-Assistent")
                .font(.phasirSectionTitle)
            Text("Beschreibe kurz, was in dieser Immobilie nicht stimmt. Die KI analysiert das Problem, schätzt die Dringlichkeit ein und zeigt dir passende Fachbetriebe in deiner Nähe.")
                .font(.phasirCaption)
                .foregroundColor(Color.phasirSecondaryText)
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("USP von Phasir: Von der Problembeschreibung zur konkreten Hilfe – in einem Schritt.")
            }
            .font(.phasirCaption)
            .foregroundColor(Color.phasirAccent)
        }
        .phasirCard()
    }

    // MARK: - Eingabe Card
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Problembeschreibung")
                .font(.phasirSectionTitle)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $descriptionText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.phasirCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.phasirCardBorder, lineWidth: 1)
                    )
                    .font(.phasirBody)
                if descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("z.B. \"Die Heizung im Wohnzimmer wird nur lauwarm und macht seit gestern komische Geräusche.\"")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                        .padding(14)
                }
            }
            Button {
                Task {
                    await runAnalysis()
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoadingDiagnosis {
                        ProgressView()
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text("Problem analysieren")
                }
                .font(.phasirButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.phasirAccent)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .disabled(isLoadingDiagnosis || descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Text("Dein Objekt: \(house.name) – \(house.address)")
                .font(.phasirCaption)
                .foregroundColor(Color.phasirSecondaryText)
        }
        .phasirCard()
    }

    // MARK: - Dringlichkeits-Badge
    private func urgencyBadge(_ urgency: Int) -> some View {
        let clamped = max(1, min(5, urgency))
        let (text, color): (String, Color) = {
            switch clamped {
            case 5: return ("Sehr hoch", .red)
            case 4: return ("Hoch", .orange)
            case 3: return ("Mittel", .yellow)
            case 2: return ("Niedrig", .green.opacity(0.7))
            default: return ("Sehr niedrig", .green)
            }
        }()
        return Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(999)
    }

    // MARK: - Kategorie-Titel und Icons
    private func categoryLabel(_ category: String) -> String {
        switch category {
        case "heating": return "Heizung"
        case "water": return "Wasser / Sanitär"
        case "plumbing": return "Leitungen / Abfluss"
        case "roof": return "Dach"
        case "electric": return "Strom / Elektrik"
        case "humidity": return "Feuchtigkeit / Schimmel"
        case "energy": return "Energie / Effizienz"
        default: return "Allgemein"
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "heating": return "flame.fill"
        case "water": return "drop.fill"
        case "plumbing": return "wrench.adjustable.fill"
        case "roof": return "house.lodge.fill"
        case "electric": return "bolt.fill"
        case "humidity": return "aqi.medium"
        case "energy": return "leaf.fill"
        default: return "questionmark.circle.fill"
        }
    }

    // MARK: - Diagnose Card
    private func diagnosisCard(_ diagnosis: ProblemDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: categoryIcon(diagnosis.category))
                    .font(.title3)
                    .foregroundColor(Color.phasirAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Einschätzung der KI")
                        .font(.phasirSectionTitle)
                    Text(categoryLabel(diagnosis.category))
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                }
                Spacer()
                urgencyBadge(diagnosis.urgency)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Wahrscheinliche Ursache")
                    .font(.phasirCaption)
                    .foregroundColor(Color.phasirSecondaryText)
                Text(diagnosis.likelyCause)
                    .font(.phasirBody)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider().padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 8) {
                Text("Empfohlene nächsten Schritte")
                    .font(.phasirCaption)
                    .foregroundColor(Color.phasirSecondaryText)
                Text(diagnosis.recommendedAction)
                    .font(.phasirBody)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !vendors.isEmpty {
                Divider().padding(.vertical, 4)
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Passende Fachbetriebe wurden basierend auf dieser Einschätzung gefunden.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                }
            }
        }
        .phasirCard()
    }

    // MARK: - Vendor Map Card
    private var vendorMapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Fachbetriebe in deiner Nähe")
                    .font(.phasirSectionTitle)
                Spacer()
                if isLoadingVendors {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            if let region = mapRegion {
                Map(
                    coordinateRegion: Binding(
                        get: { region },
                        set: { newValue in mapRegion = newValue }
                    ),
                    annotationItems: vendors
                ) { vendor in
                    if let coord = vendor.coordinate {
                        MapAnnotation(coordinate: coord) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            } else {
                Text("Sobald Dienstleister gefunden wurden, siehst du sie hier auf der Karte.")
                    .font(.phasirCaption)
                    .foregroundColor(Color.phasirSecondaryText)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            }
        }
        .phasirCard()
    }

    // MARK: - Vendor List Card
    private var vendorListCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ausgewählte Anbieter")
                .font(.phasirSectionTitle)
            ForEach(vendors.prefix(3)) { vendor in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(vendor.name)
                            .font(.phasirBody.weight(.semibold))
                        Spacer()
                        if let rating = vendor.rating {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text(String(format: "%.1f", rating))
                                    .font(.phasirCaption)
                            }
                            .foregroundColor(.yellow)
                        }
                    }
                    if let address = vendor.address {
                        Text(address)
                            .font(.phasirCaption)
                            .foregroundColor(Color.phasirSecondaryText)
                    }
                    if let distance = vendor.distanceKm {
                        Text(String(format: "%.1f km entfernt", distance))
                            .font(.phasirCaption)
                            .foregroundColor(Color.phasirSecondaryText)
                    }
                }
                .padding(.vertical, 6)
                if vendor.id != vendors.prefix(3).last?.id {
                    Divider()
                }
            }
            if let first = vendors.first, let coord = first.coordinate {
                Button {
                    let query = "\(first.name) \(first.address ?? "")"
                    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "http://maps.apple.com/?q=\(encoded)&ll=\(coord.latitude),\(coord.longitude)") {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("In Karten-App ansehen")
                        Spacer()
                    }
                    .font(.phasirButton)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .phasirCard()
    }

    // MARK: - Networking
    private func runAnalysis() async {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        isLoadingDiagnosis = true
        isLoadingVendors = true
        do {
            let newDiagnosis = try await requestDiagnosis(description: trimmed)
            await MainActor.run {
                self.diagnosis = newDiagnosis
            }
            let newVendors = try await requestVendors(category: newDiagnosis.category)
            await MainActor.run {
                self.vendors = newVendors
                if let firstCoord = newVendors.compactMap({ $0.coordinate }).first {
                    self.mapRegion = MKCoordinateRegion(
                        center: firstCoord,
                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    )
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        await MainActor.run {
            self.isLoadingDiagnosis = false
            self.isLoadingVendors = false
        }
    }

    private func requestDiagnosis(description: String) async throws -> ProblemDiagnosis {
        var request = URLRequest(url: ApiClient.shared.baseURL.appendingPathComponent("ai/problem-diagnosis"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "houseId": house.id,
            "description": description
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try decoder.decode(ProblemDiagnosis.self, from: data)
    }

    private func requestVendors(category: String) async throws -> [Vendor] {
        var components = URLComponents(url: ApiClient.shared.baseURL.appendingPathComponent("vendors/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "address", value: house.address)
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let responseObject = try decoder.decode(VendorResponse.self, from: data)
        return responseObject.vendors
    }
}
