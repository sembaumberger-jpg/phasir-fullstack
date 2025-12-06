import SwiftUI

// MARK: - Profil-Hauptscreen

struct ProfileView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Header
                    headerSection

                    // MARK: - Account / Einstellungen / Rechtliches
                    settingsBlock
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.phasirAccent, Color.phasirAccent.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Text(initials)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Dein Phasir Konto")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                if let emailLikeId = sessionManager.session?.userId {
                    Text(emailLikeId)
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                } else {
                    Text("Immobilien-OS für Eigentümer & Investoren.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)
                }

                Text("Angemeldet")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.phasirAccent.opacity(0.08))
                    )
                    .foregroundColor(Color.phasirAccent)
            }

            Spacer()
        }
    }

    private var initials: String {
        if let id = sessionManager.session?.userId,
           let firstChar = id.first {
            return String(firstChar).uppercased()
        }
        return "P"
    }

    // MARK: - Block mit Einträgen (alles verbunden)

    private var settingsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Konto & App")
                .font(.phasirSectionTitle)

            Text("Verwalte dein Konto, App-Einstellungen und alle rechtlichen Informationen zu Phasir.")
                .font(.phasirCaption)
                .foregroundColor(Color.phasirSecondaryText)

            // Ein großer, zusammenhängender Block
            VStack(spacing: 0) {
                // Einstellungen
                NavigationLink {
                    AppSettingsView()
                } label: {
                    profileRowContent(
                        icon: "gearshape.fill",
                        title: "Einstellungen",
                        subtitle: "App-Verhalten & Darstellung"
                    )
                }
                .buttonStyle(.plain)

                dividerLine

                // Mitteilungen
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    profileRowContent(
                        icon: "bell.badge.fill",
                        title: "Mitteilungen",
                        subtitle: "Benachrichtigungen & E-Mails"
                    )
                }
                .buttonStyle(.plain)

                dividerLine

                // Impressum & Rechtliches
                NavigationLink {
                    LegalInfoView()
                } label: {
                    profileRowContent(
                        icon: "doc.text.magnifyingglass",
                        title: "Impressum & Rechtliches",
                        subtitle: "Impressum, Datenschutz, Nutzungsbedingungen"
                    )
                }
                .buttonStyle(.plain)

                dividerLine

                // Support & Feedback
                NavigationLink {
                    SupportFeedbackView()
                } label: {
                    profileRowContent(
                        icon: "questionmark.circle",
                        title: "Support & Feedback",
                        subtitle: "Fragen, Ideen oder Fehler melden"
                    )
                }
                .buttonStyle(.plain)

                dividerLine

                // Logout
                logoutRow
            }
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.phasirCard)
                    .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 10)
            )
        }
    }

    // MARK: - Rows & Divider

    private var dividerLine: some View {
        Divider()
            .padding(.leading, 52) // Linie startet unter dem Text, nicht unter dem Icon
    }

    /// Reiner Inhalt einer Profil-Zeile (ohne Button / Navigation)
    private func profileRowContent(icon: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.phasirAccent.opacity(0.06))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.phasirAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.phasirSecondaryText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.phasirSecondaryText.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var logoutRow: some View {
        Button {
            sessionManager.logout()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.06))
                        .frame(width: 32, height: 32)

                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Abmelden")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)

                    Text("Sicher von deinem Phasir Konto abmelden")
                        .font(.caption)
                        .foregroundColor(Color.phasirSecondaryText)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Einstellungen-View (ein Block, interne Struktur)

struct AppSettingsView: View {
    @State private var useDarkMode: Bool = false
    @State private var showAdvancedHints: Bool = true

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Einstellungen")
                        .font(.phasirSectionTitle)

                    Text("Passe grundlegende App-Einstellungen an. Später können hier weitere Optionen hinzukommen.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    VStack(alignment: .leading, spacing: 0) {
                        Toggle(isOn: $showAdvancedHints) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Hinweise & Erklärungen")
                                    .font(.phasirBody)
                                Text("Zusätzliche Tooltips und Hinweise im Interface anzeigen.")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)

                        Divider()
                            .padding(.leading, 4)

                        Toggle(isOn: $useDarkMode) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Dunkles Design (Preview)")
                                    .font(.phasirBody)
                                Text("Nur Vorschau – tatsächliche System-Einstellung wird aktuell nicht verändert.")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: PhasirDesign.cardCornerRadius, style: .continuous)
                            .fill(Color.phasirCard)
                            .shadow(color: PhasirDesign.softShadow, radius: 14, x: 0, y: 8)
                    )
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Mitteilungen-View (ein Block)

struct NotificationSettingsView: View {
    @State private var pushMaintenance: Bool = true
    @State private var pushCashflow: Bool = true
    @State private var emailNews: Bool = false

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mitteilungen")
                        .font(.phasirSectionTitle)

                    Text("Steuere, welche Benachrichtigungen du von Phasir erhalten möchtest. Später kann dies mit einem echten Notification-System verbunden werden.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    VStack(alignment: .leading, spacing: 0) {
                        Toggle(isOn: $pushMaintenance) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Wartungen & Fristen")
                                    .font(.phasirBody)
                                Text("Erinnerungen bei anstehenden oder überfälligen Wartungen.")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)

                        Divider()
                            .padding(.leading, 4)

                        Toggle(isOn: $pushCashflow) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Cashflow & Miete")
                                    .font(.phasirBody)
                                Text("Hinweise bei negativem Cashflow oder Auffälligkeiten im Mietniveau.")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)

                        Divider()
                            .padding(.leading, 4)

                        Toggle(isOn: $emailNews) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("News & Updates per E-Mail")
                                    .font(.phasirBody)
                                Text("Gelegentliche Produkt-Updates und Immobilien-News per E-Mail.")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: PhasirDesign.cardCornerRadius, style: .continuous)
                            .fill(Color.phasirCard)
                            .shadow(color: PhasirDesign.softShadow, radius: 14, x: 0, y: 8)
                    )
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Mitteilungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Impressum & Rechtliches (ein großer Block mit Dividern)

struct LegalInfoView: View {
    private var dividerLine: some View {
        Divider()
            .padding(.leading, 2)
            .padding(.vertical, 8)
    }

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Impressum & Rechtliches")
                        .font(.phasirSectionTitle)

                    Text("Rechtliche Informationen zur Nutzung von Phasir in dieser frühen Testphase. Für einen produktiven Einsatz werden diese Texte durch eine rechtlich geprüfte Fassung ersetzt.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    VStack(alignment: .leading, spacing: 0) {
                        // Impressum
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Impressum")
                                .font(.phasirBody)

                            Text("Verantwortlich für den Inhalt dieser App:")
                                .font(.phasirCaption)

                            // TODO: Durch echte Daten ersetzen
                            Text("""
Sem Baumberger
dein Boss wenn du
das ließt solltetst
 du dir gedanken machen
""")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }
                        .padding(.bottom, 4)

                        dividerLine

                        // Datenschutz
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Datenschutzerklärung")
                                .font(.phasirBody)

                            Text("Der Schutz deiner Daten ist uns wichtig. In dieser App werden primär Immobilien- und Finanzdaten verarbeitet, die du selbst einträgst.")
                                .font(.phasirCaption)

                            Text("""
Hinweis:
- Die aktuelle Testversion speichert Daten zu Demo-Zwecken.
- Für einen produktiven Einsatz wird eine vollständige, rechtssichere Datenschutzerklärung ergänzt.
""")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }
                        .padding(.bottom, 4)

                        dividerLine

                        // Nutzungsbedingungen
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nutzungsbedingungen")
                                .font(.phasirBody)

                            Text("Phasir befindet sich aktuell in einer Testphase (Beta).")
                                .font(.phasirCaption)

                            Text("""
Die Nutzung erfolgt auf eigene Verantwortung.
Es werden keine Gewährleistungen für Vollständigkeit, Richtigkeit oder rechtliche Verbindlichkeit der bereitgestellten Analysen, Hinweise oder Berechnungen übernommen.
""")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: PhasirDesign.cardCornerRadius, style: .continuous)
                            .fill(Color.phasirCard)
                            .shadow(color: PhasirDesign.softShadow, radius: 14, x: 0, y: 8)
                    )
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Rechtliches")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Support & Feedback (ein Block mit Divider)

struct SupportFeedbackView: View {
    @Environment(\.openURL) private var openURL

    private var dividerLine: some View {
        Divider()
            .padding(.leading, 2)
            .padding(.vertical, 8)
    }

    var body: some View {
        ZStack {
            Color.phasirBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Support & Feedback")
                        .font(.phasirSectionTitle)

                    Text("Phasir lebt davon, dass echte Eigentümer und Investoren rückmelden, was ihnen hilft – und was noch fehlt.")
                        .font(.phasirCaption)
                        .foregroundColor(Color.phasirSecondaryText)

                    VStack(alignment: .leading, spacing: 0) {
                        // Feedback-Bereich
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feedback geben")
                                .font(.phasirBody)

                            Text("Schick uns kurz dein Feedback, Bugs oder Feature-Ideen. In der frühen Phase lesen wir wirklich alles.")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)

                            Button {
                                if let url = URL(string: "mailto:feedback@phasir.app?subject=Feedback%20zur%20Phasir%20App") {
                                    openURL(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("Feedback per E-Mail senden")
                                }
                                .font(.phasirButton)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.phasirAccent)
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 4)

                        dividerLine

                        // Fehler in Daten
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fehler in Daten oder Berechnungen?")
                                .font(.phasirBody)

                            Text("Wenn dir etwas komisch vorkommt – zum Beispiel eine Berechnung, ein Energie-Hinweis oder ein Cashflow-Wert – schreib uns kurz, um welches Objekt es geht und was dir auffällt.")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: PhasirDesign.cardCornerRadius, style: .continuous)
                            .fill(Color.phasirCard)
                            .shadow(color: PhasirDesign.softShadow, radius: 14, x: 0, y: 8)
                    )
                }
                .padding(.horizontal, PhasirDesign.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Support & Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
}
