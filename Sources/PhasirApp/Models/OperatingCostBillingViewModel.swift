import Foundation
import SwiftUI
// UIKit wird benötigt für PDF-Rendering (UIFont, UIColor, UIGraphicsPDFRenderer)
import UIKit

/// Repräsentiert eine Kategorie der umlagefähigen Betriebskosten. Jedes Element hat einen Anzeigenamen und ein System‑Symbol für die UI.
/// Repräsentiert eine Kategorie der umlagefähigen Betriebskosten nach der
/// Betriebskostenverordnung (BetrKV). Jedes Element hat einen Anzeigenamen und ein
/// System‑Symbol für die UI. Die Reihenfolge orientiert sich an den Positionen in § 2 BetrKV.
enum OperatingCostCategory: String, CaseIterable, Identifiable, Codable {
    /// Laufende öffentliche Lasten des Grundstücks (Grundsteuer).
    case publicCharges
    /// Kosten der Wasserversorgung und Entwässerung.
    case waterSupply
    /// Heizkosten (Brennstoffe, Betrieb der Heizanlage, Messdienstleister).
    case heating
    /// Warmwasserkosten, sofern getrennt abgerechnet.
    case warmWater
    /// Straßenreinigung und Müllbeseitigung.
    case streetCleaningWaste
    /// Gebäudereinigung und Ungezieferbekämpfung.
    case buildingCleaning
    /// Gartenpflege und Winterdienst.
    case garden
    /// Allgemeinstrom (Treppenhaus, Keller, Außenbeleuchtung).
    case electricity
    /// Kosten für den Hausmeister / Hauswart.
    case caretaker
    /// Aufzugskosten (Betrieb, Wartung, Strom).
    case elevator
    /// Gebäudeversicherung (Sach‑ und Haftpflicht).
    case insurance
    /// Gemeinschaftsantenne, Kabel‑ oder Breitbandnetz.
    case cable
    /// Hauswart / Verwaltungsleistungen (nur praktische Tätigkeiten).
    case management
    /// Sonstige umlagefähige Betriebskosten.
    case other

    var id: String { rawValue }

    /// Benutzerfreundlicher Name für die Kategorie.
    var displayName: String {
        switch self {
        case .publicCharges: return "Grundsteuer"
        case .waterSupply: return "Wasser & Entwässerung"
        case .heating: return "Heizkosten"
        case .warmWater: return "Warmwasser"
        case .streetCleaningWaste: return "Straßenreinigung & Müll"
        case .buildingCleaning: return "Gebäudereinigung"
        case .garden: return "Gartenpflege"
        case .electricity: return "Allgemeinstrom"
        case .caretaker: return "Hausmeister"
        case .elevator: return "Aufzug"
        case .insurance: return "Gebäudeversicherung"
        case .cable: return "Antenne / Kabel / Internet"
        case .management: return "Hauswart / Verwaltung"
        case .other: return "Sonstige Kosten"
        }
    }

    /// System‑Symbolname für die Kategorie (SFSymbols), um die UI anschaulicher zu gestalten.
    var systemImageName: String {
        switch self {
        case .publicCharges: return "doc.text.fill"
        case .waterSupply: return "drop.fill"
        case .heating: return "flame.fill"
        case .warmWater: return "drop.circle.fill"
        case .streetCleaningWaste: return "trash.fill"
        case .buildingCleaning: return "broom.fill"
        case .garden: return "leaf.fill"
        case .electricity: return "bolt.fill"
        case .caretaker: return "person.fill"
        case .elevator: return "arrow.up.arrow.down"
        case .insurance: return "shield.fill"
        case .cable: return "antenna.radiowaves.left.and.right"
        case .management: return "person.2.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// ViewModel für die Nebenkosten‑Abrechnung. Hält alle Eingaben und berechnet Summen sowie Kosten pro Einheit basierend auf dem Verteilungsschlüssel des Hauses.
final class OperatingCostBillingViewModel: ObservableObject {
    /// Das aktuell ausgewählte Haus, für das die Betriebskosten berechnet werden.
    @Published var house: House
    /// Das Jahr der Abrechnung. Vorausgefüllt mit dem aktuellen Jahr.
    @Published var billingYear: Int
    /// Eingaben für jede Kostenkategorie. Standardmäßig 0, damit keine Felder leer bleiben.
    @Published var categoryCosts: [OperatingCostCategory: Double]

    /// Initialisiert das ViewModel mit einem Haus und optional einem Jahr (standardmäßig aktuelles Jahr).
    init(house: House, billingYear: Int = Calendar.current.component(.year, from: Date())) {
        self.house = house
        self.billingYear = billingYear
        var costs: [OperatingCostCategory: Double] = [:]
        OperatingCostCategory.allCases.forEach { costs[$0] = 0 }
        self.categoryCosts = costs
    }

    /// Gesamtsumme aller eingegebenen Kosten.
    var totalCost: Double {
        categoryCosts.values.reduce(0, +)
    }

    /// Divisor basierend auf dem Verteilungsschlüssel. Gibt `nil` zurück, wenn keine sinnvolle Berechnung möglich ist.
    var unitDivisor: Double? {
        guard let key = house.primaryOperatingCostKey else { return nil }
        switch key {
        case "sqm":
            if let area = house.livingArea, area > 0 { return Double(area) }
            return nil
        case "people":
            if let count = house.residentsCount, count > 0 { return Double(count) }
            return nil
        case "units":
            if let units = house.unitCount, units > 0 { return Double(units) }
            return nil
        case "consumption":
            // Verbrauchsbasierte Verteilung erfordert einzelne Verbrauchsdaten. Ohne Daten kein sinnvoller Divisor.
            return nil
        default:
            return nil
        }
    }

    /// Berechneter Betrag pro Einheit (je nach Verteilungsschlüssel). Gibt `nil` zurück, wenn divisor fehlt.
    var costPerUnit: Double? {
        guard let divisor = unitDivisor, divisor > 0 else { return nil }
        return totalCost / divisor
    }

    /// Lesbare Darstellung des Verteilungsschlüssels.
    var distributionKeyDescription: String {
        guard let key = house.primaryOperatingCostKey else { return "Nicht definiert" }
        switch key {
        case "sqm": return "Wohnfläche (m²)"
        case "people": return "Personen"
        case "units": return "Einheiten"
        case "consumption": return "Verbrauch"
        default: return "Unbekannt"
        }
    }

    // MARK: - PDF-Erstellung für einen einzelnen Mieter
    /// Erstellt ein PDF-Dokument der Nebenkostenabrechnung für einen konkreten Mieter und speichert es in einem temporären Verzeichnis.
    /// - Parameters:
    ///   - tenantName: Name des Mieters.
    ///   - tenantAddress: Anschrift des Mieters.
    ///   - shareValue: Anteil des Mieters entsprechend dem Umlageschlüssel (z. B. Wohnfläche, Personen, Einheiten).
    ///   - prepaymentMonthly: Monatliche Nebenkostenvorauszahlung des Mieters.
    ///   - prepaymentMonths: Anzahl der Monate, die der Mieter Vorauszahlungen geleistet hat.
    /// - Returns: URL zum generierten PDF oder `nil` bei Fehler.
    func generateTenantPDF(tenantName: String,
                          tenantAddress: String,
                          shareValue: Double,
                          prepaymentMonthly: Double,
                          prepaymentMonths: Int,
                          landlordName: String? = nil,
                          landlordAddress: String? = nil,
                          landlordContact: String? = nil) -> URL? {
        // Bereite Dateinamen und Meta-Daten vor
        let safeTenantName = tenantName.replacingOccurrences(of: " ", with: "_")
        let fileName = "Nebenkostenabrechnung_\(safeTenantName)_\(billingYear).pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let pageRect = CGRect(x: 0, y: 0, width: 595.0, height: 842.0)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: UIGraphicsPDFRendererFormat())

        do {
            let data = try renderer.pdfData { context in
                context.beginPage()
                let ctx = UIGraphicsGetCurrentContext()!
                let margin: CGFloat = 36
                var yPos: CGFloat = margin

                // Letter‑style Kopfbereich: Zweispaltig (links Vermieter, rechts Mieter)
                // Spaltenbreite ermitteln
                let usableWidth = pageRect.width - margin * 2
                let colWidth = usableWidth / 2.0
                let leftX = margin
                let rightX = margin + colWidth
                var yLeft = yPos
                var yRight = yPos
                // Vermieterinformationen (links) – klar benannt
                let senderName = landlordName ?? house.ownerName ?? "–"
                draw(text: "Vermieter / Hausverwaltung: \(senderName)", at: CGPoint(x: leftX, y: yLeft), font: UIFont.systemFont(ofSize: 12), context: ctx)
                yLeft += 16
                // Verwende bevorzugt die vom Nutzer eingegebene Vermieteradresse, sonst die Hausadresse
                let landlordAddrToUse: String = {
                    if let providedAddress = landlordAddress, !providedAddress.isEmpty {
                        return providedAddress
                    } else {
                        return house.address
                    }
                }()
                draw(text: "Adresse: \(landlordAddrToUse)", at: CGPoint(x: leftX, y: yLeft), font: UIFont.systemFont(ofSize: 12), context: ctx)
                yLeft += 16
                if let providedContact = landlordContact, !providedContact.isEmpty {
                    draw(text: "Kontakt: \(providedContact)", at: CGPoint(x: leftX, y: yLeft), font: UIFont.systemFont(ofSize: 12), context: ctx)
                    yLeft += 16
                }
                // Mieterinformationen (rechts) – klar benannt
                draw(text: "Mieter: \(tenantName)", at: CGPoint(x: rightX, y: yRight), font: UIFont.systemFont(ofSize: 12), context: ctx)
                yRight += 16
                draw(text: "Adresse: \(tenantAddress)", at: CGPoint(x: rightX, y: yRight), font: UIFont.systemFont(ofSize: 12), context: ctx)
                yRight += 16
                // Setze yPos auf die größere Höhe der beiden Spalten
                yPos = max(yLeft, yRight) + 24
                // Titel zentriert unter dem Kopfbereich
                draw(text: "Nebenkostenabrechnung \(billingYear)", at: CGPoint(x: margin, y: yPos), font: UIFont.boldSystemFont(ofSize: 20), context: ctx)
                yPos += 32

                // Objektangaben und Abrechnungsperiode
                draw(text: "Objekt: \(house.name)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                yPos += 16
                // Objektadresse (falls vorhanden)
                draw(text: "Adresse: \(house.address)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                yPos += 16
                // Anteil und Schlüssel erläutern (sofern ein Divisor vorhanden ist)
                if let divisor = self.unitDivisor, divisor > 0 {
                    // Prozentualer Anteil
                    let percent = (shareValue / divisor) * 100
                    let percentString = String(format: "%.2f %%", percent).replacingOccurrences(of: ".", with: ",")
                    // Zeige Mieterwert und Gesamtwert je nach Schlüssel
                    switch house.primaryOperatingCostKey ?? "" {
                    case "sqm":
                        draw(text: "Wohnfläche Mieter: \(shareValue) m²", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                        draw(text: "Gesamtwohnfläche: \(divisor) m²", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                    case "people":
                        draw(text: "Personen im Haushalt: \(shareValue)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                        draw(text: "Gesamtpersonen: \(divisor)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                    case "units":
                        draw(text: "Einheiten Mieter: \(shareValue)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                        draw(text: "Gesamteinheiten: \(divisor)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                    case "consumption":
                        draw(text: "Verbrauch Mieter: \(shareValue)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                        draw(text: "Gesamtverbrauch: \(divisor)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                    default:
                        // Fallback: nur Wert und Gesamt ausgeben
                        draw(text: "Schlüsselwert Mieter: \(shareValue)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                        draw(text: "Schlüsselwert Gesamt: \(divisor)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                        yPos += 16
                    }
                    draw(text: "Anteil: \(percentString) = \(shareValue) / \(divisor)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                    yPos += 16
                } else {
                    // Kein Divisor – einfach den eingegebenen Wert mit Schlüssel ausgeben
                    draw(text: "Wert für Schlüssel (\(distributionKeyDescription)): \(shareValue)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                    yPos += 16
                }
                // Abrechnungszeitraum (muss 12 Monate umfassen)
                draw(text: "Abrechnungszeitraum: 01.01.\(billingYear) – 31.12.\(billingYear)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                yPos += 24

                // Tabelleneinträge
                draw(text: "Nr.", at: CGPoint(x: margin, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                draw(text: "Kostenart", at: CGPoint(x: margin + 30, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                draw(text: "Gesamt", at: CGPoint(x: margin + 230, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                draw(text: "Schlüssel", at: CGPoint(x: margin + 340, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                draw(text: "Anteil Mieter", at: CGPoint(x: margin + 440, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                yPos += 16
                // Linie unter Kopf
                ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
                ctx.setLineWidth(0.5)
                ctx.move(to: CGPoint(x: margin, y: yPos))
                ctx.addLine(to: CGPoint(x: pageRect.maxX - margin, y: yPos))
                ctx.strokePath()
                yPos += 4

                // Laufende Nummern
                var idx = 1
                for category in OperatingCostCategory.allCases {
                    let catName = category.displayName
                    let cost = categoryCosts[category] ?? 0
                    let proportion: Double = totalCost > 0 ? cost / totalCost : 0
                    let share: Double
                    if let perUnit = costPerUnit {
                        share = (perUnit * shareValue) * proportion
                    } else {
                        share = 0
                    }
                    draw(text: "\(idx)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 10), context: ctx)
                    draw(text: catName, at: CGPoint(x: margin + 30, y: yPos), font: UIFont.systemFont(ofSize: 10), context: ctx)
                    draw(text: cost.formattedCurrency(), at: CGPoint(x: margin + 230, y: yPos), font: UIFont.systemFont(ofSize: 10), context: ctx)
                    draw(text: distributionKeyDescription, at: CGPoint(x: margin + 340, y: yPos), font: UIFont.systemFont(ofSize: 10), context: ctx)
                    draw(text: share.formattedCurrency(), at: CGPoint(x: margin + 440, y: yPos), font: UIFont.systemFont(ofSize: 10), context: ctx)
                    yPos += 14
                    idx += 1
                }
                // Summenzeile
                yPos += 8
                draw(text: "Summe umlagefähige Kosten", at: CGPoint(x: margin + 30, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                draw(text: totalCost.formattedCurrency(), at: CGPoint(x: margin + 230, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                let shareSum: Double = {
                    if let perUnit = costPerUnit {
                        return perUnit * shareValue
                    } else { return 0 }
                }()
                draw(text: shareSum.formattedCurrency(), at: CGPoint(x: margin + 440, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                yPos += 16
                // Trenner unter der Summe der umlagefähigen Kosten
                ctx.move(to: CGPoint(x: margin, y: yPos))
                ctx.addLine(to: CGPoint(x: pageRect.maxX - margin, y: yPos))
                ctx.setLineWidth(0.5)
                ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.6).cgColor)
                ctx.strokePath()
                yPos += 4
                // Vorauszahlungen in Rechnungseintrag integrieren (als negative Position)
                let prepaymentTotal = prepaymentMonthly * Double(prepaymentMonths)
                // Zeile: Vorauszahlungen – Label mit Details (monatlicher Betrag × Monate)
                let prepaymentLabel = "Vorauszahlungen (" + prepaymentMonthly.formattedCurrency() + " × \(prepaymentMonths))"
                draw(text: prepaymentLabel, at: CGPoint(x: margin + 30, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                let negativePrepayment = (-prepaymentTotal).formattedCurrency()
                draw(text: negativePrepayment, at: CGPoint(x: margin + 440, y: yPos), font: UIFont.systemFont(ofSize: 12), context: ctx)
                yPos += 16
                // erneuter Trenner vor dem Endbetrag
                ctx.move(to: CGPoint(x: margin, y: yPos))
                ctx.addLine(to: CGPoint(x: pageRect.maxX - margin, y: yPos))
                ctx.setLineWidth(0.5)
                ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.6).cgColor)
                ctx.strokePath()
                yPos += 4
                // Endbetrag (Nachzahlung/Guthaben)
                let finalResult = shareSum - prepaymentTotal
                let resultString: String = {
                    if finalResult > 0 {
                        return finalResult.formattedCurrency()
                    } else if finalResult < 0 {
                        return finalResult.formattedCurrency()
                    } else {
                        return "0,00 €"
                    }
                }()
                draw(text: "Endbetrag", at: CGPoint(x: margin + 30, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                draw(text: resultString, at: CGPoint(x: margin + 440, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                yPos += 24
                // Zahlungsziel / Fälligkeit: 30 Tage nach Zustellung
                // Berechne Fälligkeitsdatum basierend auf aktuellem Datum plus 30 Tage
                let currentDate = Date()
                if let dueDate = Calendar.current.date(byAdding: .day, value: 30, to: currentDate) {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy"
                    let dueDateString = dateFormatter.string(from: dueDate)
                    draw(text: "Zahlbar bis: \(dueDateString)", at: CGPoint(x: margin + 30, y: yPos), font: UIFont.systemFont(ofSize: 10), context: ctx)
                    yPos += 20
                }

                // Belegübersicht & rechtliche Hinweise
                draw(text: "Belegübersicht", at: CGPoint(x: margin, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                yPos += 16
                draw(text: "Die zugehörigen Rechnungen und Belege können nach Terminvereinbarung eingesehen werden.", at: CGPoint(x: margin + 30, y: yPos), font: UIFont.systemFont(ofSize: 10), context: ctx)
                yPos += 24
                draw(text: "Rechtliche Hinweise", at: CGPoint(x: margin, y: yPos), font: UIFont.boldSystemFont(ofSize: 12), context: ctx)
                yPos += 16
                draw(text: "Einwendungen gegen diese Abrechnung sind innerhalb eines Jahres nach Erhalt geltend zu machen. Es gelten die Vorschriften der Heizkostenverordnung.", at: CGPoint(x: margin + 30, y: yPos), font: UIFont.systemFont(ofSize: 10), context: ctx)
                yPos += 40
            }
            try data.write(to: outputURL)
            return outputURL
        } catch {
            print("Fehler beim Erstellen des PDF: \(error)")
            return nil
        }
    }

    /// Hilfsfunktion zum Zeichnen von Text auf den PDF-Context.
    private func draw(text: String, at point: CGPoint, font: UIFont, context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: point)
    }
}
