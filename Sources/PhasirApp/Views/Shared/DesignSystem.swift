import SwiftUI

/// Zentrales Designsystem für Phasir
struct PhasirDesign {
    /// Generelle Rundung für Karten
    static let cornerRadius: CGFloat = 18
    /// Speziell für Card-Helper (identisch, nur explizit)
    static let cardCornerRadius: CGFloat = 18

    /// Standard Screen-Padding
    static let screenPadding: CGFloat = 20

    /// Weicher Schatten
    static let softShadow: Color = Color.black.opacity(0.06)
}

// MARK: - Farben

extension Color {
    /// Hintergrund der App
    static let phasirBackground = Color(UIColor.systemGroupedBackground)

    /// Karten-Hintergrund
    static let phasirCard = Color.white

    /// Primäre Akzentfarbe (LinkedIn / PayPal-Vibe)
    static let phasirAccent = Color(red: 0.0, green: 0.47, blue: 0.96)

    /// Sekundärer Text
    static let phasirSecondaryText = Color(UIColor.secondaryLabel)

    /// Dezente Rahmen-/Outline-Farbe für Inputs & Progressbars
    static let phasirCardBorder = Color.black.opacity(0.08)
}


// MARK: - Typografie

extension Font {


    static var phasirTitle: Font {
        .custom("Menlo-Bold", size: 26)
    }

    /// Abschnittstitel für Cards (z.B. "Energie", "Finanzen", "Überblick")
    static var phasirSectionTitle: Font {
            .system(size: 18, weight: .semibold, design: .default)
    }

        /// Normale Texte (Beschreibung, Inputs, Body)
    static var phasirBody: Font {
            .system(size: 15, weight: .regular, design: .default)
    }

        /// Kleine Sub-Informationen, Zeitstempel, Labels
    static var phasirCaption: Font {
            .system(size: 12, weight: .regular, design: .default)
    }

        /// Buttons im Login und UI-CTAs
    static var phasirButton: Font {
            .system(size: 16, weight: .semibold, design: .rounded)
    }
}



// MARK: - View-Helper

extension View {
    /// Einheitlicher Phasir-Card-Stil
    func phasirCard() -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: PhasirDesign.cardCornerRadius, style: .continuous)
                    .fill(Color.phasirCard)
                    .shadow(color: PhasirDesign.softShadow, radius: 14, x: 0, y: 8)
            )
    }

    /// Einheitlicher TextField-Stil
    func textFieldStylePhasir() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.phasirCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.phasirCardBorder, lineWidth: 1)
            )
    }
}
