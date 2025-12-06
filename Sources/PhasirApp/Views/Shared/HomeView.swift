import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HouseListViewModel

    @State private var selectedTab: HomeTab = .actions

    enum HomeTab {
        case actions
        case news
    }

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topSegmentedControl

                Divider().opacity(0.1)

                Group {
                    switch selectedTab {
                    case .actions:
                        actionCenterContent
                    case .news:
                        newsContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.load()
            await viewModel.loadNews()
            await viewModel.loadRentBenchmark()
        }
    }

    // MARK: - Top Switcher

    private var topSegmentedControl: some View {
        HStack {
            Spacer()

            topTabButton(
                title: "Aktionen",
                isActive: selectedTab == .actions
            ) {
                selectedTab = .actions
            }

            Spacer()

            topTabButton(
                title: "News",
                isActive: selectedTab == .news
            ) {
                selectedTab = .news
            }

            Spacer()
        }
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(Color.phasirBackground)
    }

    private func topTabButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isActive ? .primary : .phasirSecondaryText)

                Rectangle()
                    .fill(isActive ? Color.primary : Color.gray.opacity(0.15))
                    .frame(width: 80, height: 3)
                    .cornerRadius(2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - ACTION CENTER

    private var actionCenterContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if actionItems.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundColor(.phasirAccent.opacity(0.9))

                        Text("Aktuell keine dringenden Aktionen")
                            .font(.system(size: 17, weight: .semibold))

                        Text("Sobald Wartungen anstehen, Mieten stark vom Markt abweichen oder Objekte negativ laufen, erscheinen sie hier als To-dos.")
                            .font(.system(size: 13))
                            .foregroundColor(.phasirSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Action Center")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Die wichtigsten Aufgaben aus Wartungen, Cashflow und Mietniveau – kompakt gesammelt.")
                            .font(.system(size: 13))
                            .foregroundColor(.phasirSecondaryText)
                    }
                    .padding(.horizontal, PhasirDesign.screenPadding)
                    .padding(.top, 16)

                    VStack(spacing: 12) {
                        ForEach(actionItems) { item in
                            actionItemCard(item)
                        }
                    }
                    .padding(.horizontal, PhasirDesign.screenPadding)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color.phasirBackground.ignoresSafeArea())
    }

    private func actionItemCard(_ item: ActionItemUI) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.phasirAccent.opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: item.iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.phasirAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))

                    if let summary = item.summary {
                        Text(summary)
                            .font(.system(size: 13))
                            .foregroundColor(.phasirSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                if let houseName = item.houseName {
                    tagPill(text: houseName, systemImage: "house.fill")
                }

                if let dueText = item.dueText {
                    tagPill(text: dueText, systemImage: "calendar")
                }

                priorityPill(priority: item.priority)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.phasirCard)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }

    private func tagPill(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 11))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.phasirBackground)
        )
        .foregroundColor(Color.phasirSecondaryText)
    }

    private func priorityPill(priority: ActionItemUI.Priority) -> some View {
        let label: String
        let color: Color

        switch priority {
        case .high:
            label = "Hoch"
            color = .red
        case .medium:
            label = "Mittel"
            color = .orange
        case .low:
            label = "Niedrig"
            color = .gray
        }

        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.phasirBackground)
        )
        .foregroundColor(Color.primary)
    }

    // MARK: - NEWS

    private var newsContent: some View {
        ScrollView {
            if viewModel.newsArticles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(.phasirSecondaryText.opacity(0.8))

                    Text("Noch keine Immobilien-News verfügbar")
                        .font(.system(size: 17, weight: .semibold))

                    Text("Prüfe, ob das Backend läuft und der Endpoint /news/real-estate Daten zurückgibt. Bis dahin bleibt dieser Bereich leer.")
                        .font(.system(size: 13))
                        .foregroundColor(.phasirSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .padding(.horizontal, PhasirDesign.screenPadding)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.newsArticles) { article in
                        NewsFeedPostView(article: article)
                        Divider()
                            .padding(.leading, 72)
                            .opacity(0.2)
                    }
                }
                .padding(.top, 8)
            }
        }
        .background(Color.phasirBackground.ignoresSafeArea())
    }

    // MARK: - Action Logic

    private var houses: [House] {
        viewModel.houses
    }

    private var rentalHouses: [House] {
        houses.filter { house in
            guard let usage = house.usageType?.lowercased() else { return false }
            return usage.contains("vermietet")
                || usage.contains("gewerb")
                || usage.contains("kurzzeit")
        }
    }

    private func monthlyIncome(for house: House) -> Double {
        let warm = house.monthlyRentWarm ?? 0
        let cold = house.monthlyRentCold ?? 0
        return warm > 0 ? warm : cold
    }

    private func monthlyCosts(for house: House) -> Double {
        let credit = house.loanMonthlyPayment ?? 0
        let utilities = house.monthlyUtilities ?? 0
        let hoa = house.monthlyHoaFees ?? 0
        let insurance = (house.insurancePerYear ?? 0) / 12.0
        let maintenance = (house.maintenanceBudgetPerYear ?? 0) / 12.0
        return credit + utilities + hoa + insurance + maintenance
    }

    private func monthlyCashflow(for house: House) -> Double {
        monthlyIncome(for: house) - monthlyCosts(for: house)
    }

    private func daysUntil(_ date: Date?) -> Int? {
        guard let date = date else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    private func maintenancePriority(for date: Date?) -> ActionItemUI.Priority? {
        guard let days = daysUntil(date) else { return nil }

        if days < 0 {
            return .high
        } else if days <= 60 {
            return .high
        } else if days <= 180 {
            return .medium
        } else if days <= 365 {
            return .low
        } else {
            return nil
        }
    }

    private func maintenanceDueText(for date: Date?) -> String? {
        guard let days = daysUntil(date) else { return nil }

        if days < 0 {
            return "Überfällig"
        } else if days == 0 {
            return "Heute fällig"
        } else if days <= 60 {
            return "Fällig in \(days) Tagen"
        } else if days <= 365 {
            return "In ca. \(days / 30) Monaten"
        } else {
            return nil
        }
    }

    private var actionItems: [ActionItemUI] {
        var items: [ActionItemUI] = []

        // 1) Wartungen
        for house in houses {
            let components: [(String, Date?)] = [
                ("Heizung", house.next?.heating),
                ("Dach", house.next?.roof),
                ("Fenster", house.next?.windows),
                ("Rauchmelder", house.next?.smoke)
            ]

            for (component, date) in components {
                guard let priority = maintenancePriority(for: date),
                      let dueText = maintenanceDueText(for: date)
                else { continue }

                let title = "\(component)-Wartung planen"
                let summary = "Bei „\(house.name)“ steht in absehbarer Zeit eine \(component)-Wartung an. Plane rechtzeitig einen Termin ein."

                let item = ActionItemUI(
                    kind: .maintenance,
                    title: title,
                    summary: summary,
                    houseId: house.id,
                    houseName: house.name,
                    dueText: dueText,
                    priority: priority
                )
                items.append(item)
            }
        }

        // 2) Cashflow-Probleme
        for house in rentalHouses {
            let cf = monthlyCashflow(for: house)
            if cf < 0 {
                let title = "Negativer Cashflow bei \(house.name)"
                let summary = "Die monatlichen Kosten liegen aktuell über den Einnahmen. Prüfe Miete, Finanzierung und laufende Ausgaben."

                let item = ActionItemUI(
                    kind: .cashflow,
                    title: title,
                    summary: summary,
                    houseId: house.id,
                    houseName: house.name,
                    dueText: nil,
                    priority: .high
                )
                items.append(item)
            }
        }

        // 3) Mietniveau vs. Markt
        if let advice = viewModel.rentBenchmarkAdvice() {
            for entry in advice.houses {
                let deviation = entry.deviationPercent ?? 0.0
                let deviationText = String(format: "%.1f", deviation)

                switch entry.rating.lowercased() {
                case "unter markt":
                    let title = "Miete unter Marktniveau prüfen"
                    let summary = "Die Miete von „\(entry.name)“ liegt etwa \(deviationText) % unter dem geschätzten Markt. Prüfe eine moderate Anpassung im Rahmen des Mietrechts."

                    let item = ActionItemUI(
                        kind: .rent,
                        title: title,
                        summary: summary,
                        houseId: entry.id,
                        houseName: entry.name,
                        dueText: nil,
                        priority: .medium
                    )
                    items.append(item)

                case "über markt":
                    let title = "Miete über Marktniveau im Blick behalten"
                    let summary = "Die Miete von „\(entry.name)“ liegt etwa \(deviationText) % über dem geschätzten Markt. Stelle sicher, dass Zustand und Ausstattung das Niveau rechtfertigen."

                    let item = ActionItemUI(
                        kind: .rent,
                        title: title,
                        summary: summary,
                        houseId: entry.id,
                        houseName: entry.name,
                        dueText: nil,
                        priority: .low
                    )
                    items.append(item)

                default:
                    break
                }
            }
        }

        return items.sorted { a, b in
            if a.priority != b.priority {
                return a.priority.sortOrder < b.priority.sortOrder
            }
            return a.dueSortScore < b.dueSortScore
        }
    }
}

// MARK: - ActionItemUI

struct ActionItemUI: Identifiable {
    enum Kind {
        case maintenance
        case rent
        case cashflow
    }

    enum Priority {
        case high
        case medium
        case low

        var sortOrder: Int {
            switch self {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let summary: String?
    let houseId: String?
    let houseName: String?
    let dueText: String?
    let priority: Priority

    var iconName: String {
        switch kind {
        case .maintenance:
            return "wrench.and.screwdriver"
        case .rent:
            return "eurosign.circle"
        case .cashflow:
            return "chart.line.uptrend.xyaxis"
        }
    }

    var dueSortScore: Int {
        guard let dueText = dueText else { return 9999 }

        if dueText.contains("Überfällig") { return 0 }
        if dueText.contains("Heute") { return 1 }
        if dueText.contains("fällig in") {
            let digits = dueText.split(whereSeparator: { !$0.isNumber })
            if let first = digits.first, let num = Int(first) {
                return 10 + num
            }
        }
        return 500
    }
}

// MARK: - NewsFeedPostView

private struct NewsFeedPostView: View {
    @Environment(\.openURL) private var openURL

    let article: NewsArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.phasirAccent.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Text(avatarInitial)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.phasirAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(article.source ?? "Immobilien-News")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Immobilien • \(timeAgoText(from: article.publishedAt))")
                        .font(.system(size: 11))
                        .foregroundColor(.phasirSecondaryText)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.system(size: 16, weight: .semibold))

                if let summary = article.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 14))
                        .foregroundColor(.phasirSecondaryText)
                        .lineLimit(4)
                }
            }

            if let img = article.imageUrl,
               let url = URL(string: img) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                }
                .frame(maxHeight: 260)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if let link = article.url, let url = URL(string: link) {
                Button {
                    openURL(url)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Zum Artikel")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.phasirAccent.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, PhasirDesign.screenPadding)
        .padding(.vertical, 14)
        .background(Color.phasirBackground)
    }

    private var avatarInitial: String {
        if let s = article.source,
           let first = s.trimmingCharacters(in: .whitespacesAndNewlines).first {
            return String(first).uppercased()
        }
        return "P"
    }

    private func timeAgoText(from isoString: String?) -> String {
        guard
            let isoString,
            let date = ISO8601DateFormatter().date(from: isoString)
        else { return "" }

        let now = Date()
        let comps = Calendar.current.dateComponents(
            [.minute, .hour, .day],
            from: date,
            to: now
        )

        if let day = comps.day, day > 0 {
            if day == 1 { return "vor 1 Tag" }
            return "vor \(day) Tagen"
        }
        if let hour = comps.hour, hour > 0 {
            if hour == 1 { return "vor 1 Std" }
            return "vor \(hour) Std"
        }
        if let min = comps.minute, min > 0 {
            if min == 1 { return "vor 1 Min" }
            return "vor \(min) Min"
        }
        return "gerade eben"
    }
}
