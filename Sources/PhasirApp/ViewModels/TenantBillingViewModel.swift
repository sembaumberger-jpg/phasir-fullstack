import Foundation
import SwiftUI
import PDFKit
import UIKit

/// ViewModel zur Berechnung und Erstellung einer Nebenkostenabrechnung für einen einzelnen Mieter.
/// Es nutzt die bereits eingegebenen Betriebskosten eines Hauses und den Verteilungsschlüssel, um den Anteil des Mieters zu bestimmen.
final class TenantBillingViewModel: ObservableObject {
    /// ViewModel mit den Gesamtkosten und Verteilungseinstellungen des Hauses.
    let costModel: OperatingCostBillingViewModel

    /// Name des Mieters, wie er in der Abrechnung erscheinen soll.
    @Published var tenantName: String
    /// Anschrift des Mieters (optional, für die PDF).
    @Published var tenantAddress: String
    /// Wohnfläche, Personenanzahl oder Einheitenanzahl des Mieters – abhängig vom Verteilungsschlüssel.
    @Published var shareValue: Double
    /// Monatliche Vorauszahlung des Mieters (in Euro).
    @Published var prepaymentMonthly: Double
    /// Anzahl Monate, für die der Mieter Vorauszahlungen geleistet hat.
    @Published var prepaymentMonths: Int

    init(costModel: OperatingCostBillingViewModel) {
        self.costModel = costModel
        self.tenantName = ""
        self.tenantAddress = ""
        // Standardmäßig ein Anteil von 1 Einheit / Person / Quadratmeter
        self.shareValue = 1.0
        self.prepaymentMonthly = 0.0
        self.prepaymentMonths = 12
    }

    /// Gesamtanteil des Mieters an den Betriebskosten (Kosten pro Einheit * shareValue).
    var tenantShareCost: Double? {
        guard let perUnit = costModel.costPerUnit else { return nil }
        return perUnit * shareValue
    }

    /// Gesamtsumme der bereits gezahlten Vorauszahlungen.
    var prepaymentTotal: Double {
        return prepaymentMonthly * Double(prepaymentMonths)
    }

    /// Endergebnis: Nachzahlung (positiv) oder Guthaben (negativ).
    var finalResult: Double? {
        guard let shareCost = tenantShareCost else { return nil }
        return shareCost - prepaymentTotal
    }

    /// Erstellt ein PDF-Dokument der Nebenkostenabrechnung und speichert es in einem temporären Verzeichnis.
    /// - Returns: URL zum generierten PDF oder `nil` bei Fehler.
    func generatePDF() -> URL? {
        // Bereite Dateinamen und Meta-Daten vor
        let safeTenantName = tenantName.replacingOccurrences(of: " ", with: "_")
        let fileName = "Nebenkostenabrechnung_\(safeTenantName)_\(costModel.billingYear).pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Standard A4 (595x842pt) Hochformat.
        let pageRect = CGRect(x: 0, y: 0, width: 595.0, height: 842.0)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: UIGraphicsPDFRendererFormat())

        do {
            let data = try renderer.pdfData { context in
                context.beginPage()
                let ctx = UIGraphicsGetCurrentContext()!

                let margin: CGFloat = 36
                var yPos: CGFloat = margin

                // Überschrift
                draw(text: "Nebenkostenabrechnung \(costModel.billingYear)", at: CGPoint(x: margin, y: yPos), font: UIFont.boldSystemFont(ofSize: 20))
                yPos += 32

                // Vermieter / Mieter Info
                draw(text: "Vermieter: \(costModel.house.ownerName ?? "–")", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12))
                yPos += 16
                draw(text: "Mieter: \(tenantName)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12))
                yPos += 16
                draw(text: "Anschrift Mieter: \(tenantAddress)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12))
                yPos += 24

                // Objektinfo
                draw(text: "Objekt: \(costModel.house.name)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12))
                yPos += 16
                if let _ = costModel.house.livingArea {
                    draw(text: "Wohnfläche Wohnung: \(shareValue) (vom Schlüssel \(costModel.distributionKeyDescription))", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12))
                    yPos += 16
                }
                draw(text: "Abrechnungszeitraum: 01.01.\(costModel.billingYear) – 31.12.\(costModel.billingYear)", at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 12))
                yPos += 24

                // Tabelle Kopf
                let tableStartY = yPos
                draw(text: "Kostenart", at: CGPoint(x: margin, y: tableStartY), font: UIFont.boldSystemFont(ofSize: 12))
                draw(text: "Gesamt", at: CGPoint(x: margin + 200, y: tableStartY), font: UIFont.boldSystemFont(ofSize: 12))
                draw(text: "Schlüssel", at: CGPoint(x: margin + 320, y: tableStartY), font: UIFont.boldSystemFont(ofSize: 12))
                draw(text: "Anteil Mieter", at: CGPoint(x: margin + 420, y: tableStartY), font: UIFont.boldSystemFont(ofSize: 12))
                yPos += 16

                // Linie unter Kopf
                ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
                ctx.setLineWidth(0.5)
                ctx.move(to: CGPoint(x: margin, y: yPos))
                ctx.addLine(to: CGPoint(x: pageRect.maxX - margin, y: yPos))
                ctx.strokePath()
                yPos += 4

                // Tabelle Einträge pro Kategorie
                for category in OperatingCostCategory.allCases {
                    let catName = category.displayName
                    let cost = costModel.categoryCosts[category] ?? 0
                    // Anteil Mieter = (Gesamtkosten / Divisor) * shareValue
                    let share: Double
                    if let perUnit = costModel.costPerUnit {
                        // Anteil der Kategorie = Anteil an Gesamtkosten proportioniert
                        let proportion = costModel.totalCost > 0 ? cost / costModel.totalCost : 0
                        share = (perUnit * shareValue) * proportion
                    } else {
                        share = 0
                    }
                    draw(text: catName, at: CGPoint(x: margin, y: yPos), font: UIFont.systemFont(ofSize: 10))
                    draw(text: cost.formattedCurrency(), at: CGPoint(x: margin + 200, y: yPos), font: UIFont.systemFont(ofSize: 10))
                    draw(text: costModel.distributionKeyDescription, at: CGPoint(x: margin + 320, y: yPos), font: UIFont.systemFont(ofSize: 10))
                    draw(text: share.formattedCurrency(), at: CGPoint(x: margin + 420, y: yPos), font: UIFont.systemFont(ofSize: 10))
                    yPos += 14
                }

                // Summen
                yPos += 8
                draw(text: "Summe umlagefähige Kosten", at: CGPoint(x: margin, y: yPos), font: UIFont.boldSystemFont(ofSize: 12))
                draw(text: costModel.totalCost.formattedCurrency(), at: CGPoint(x: margin + 200, y: yPos), font: UIFont.boldSystemFont(ofSize: 12))
                let shareSum = tenantShareCost ?? 0
                draw(text: shareSum.formattedCurrency(), at: CGPoint(x: margin + 420, y: yPos), font: UIFont.boldSystemFont(ofSize: 12))
                yPos += 24

                // Vorauszahlungen
                draw(text: "Vorauszahlungen des Mieters", at: CGPoint(x: margin, y: yPos), font: UIFont.boldSystemFont(ofSize: 12))
                yPos += 16
                draw(text: "Monatliche Vorauszahlung", at: CGPoint(x: margin + 20, y: yPos), font: UIFont.systemFont(ofSize: 10))
                draw(text: prepaymentMonthly.formattedCurrency() + " × \(prepaymentMonths) Monate", at: CGPoint(x: margin + 200, y: yPos), font: UIFont.systemFont(ofSize: 10))
                draw(text: prepaymentTotal.formattedCurrency(), at: CGPoint(x: margin + 420, y: yPos), font: UIFont.systemFont(ofSize: 10))
                yPos += 20

                // Ergebnis
                draw(text: "Ergebnis", at: CGPoint(x: margin, y: yPos), font: UIFont.boldSystemFont(ofSize: 12))
                yPos += 16
                if let result = finalResult {
                    let resultText: String
                    if result > 0 {
                        resultText = "Nachzahlung: " + result.formattedCurrency()
                    } else if result < 0 {
                        resultText = "Guthaben: " + (result * -1).formattedCurrency()
                    } else {
                        resultText = "Keine Nachzahlung oder Guthaben"
                    }
                    draw(text: resultText, at: CGPoint(x: margin + 20, y: yPos), font: UIFont.systemFont(ofSize: 12))
                } else {
                    draw(text: "Berechnung nicht möglich", at: CGPoint(x: margin + 20, y: yPos), font: UIFont.systemFont(ofSize: 12))
                }
            }
            // Schreibe das PDF auf die Platte
            try data.write(to: outputURL)
            return outputURL
        } catch {
            print("Fehler beim Erstellen des PDFs: \(error)")
            return nil
        }
    }

    /// Hilfsfunktion zum Zeichnen von Text auf den PDF-Context.
    private func draw(text: String, at point: CGPoint, font: UIFont) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: point)
    }
}
