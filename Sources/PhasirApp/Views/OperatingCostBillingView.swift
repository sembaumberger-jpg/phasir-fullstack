import SwiftUI

/// Eine Ansicht, die die Nebenkosten‑Abrechnung für ein Haus ermöglicht. Der Nutzer kann für verschiedene Kostenkategorien Beträge eingeben
/// und erhält eine Zusammenfassung inkl. Gesamt- und Einheitskosten gemäß dem im Haus hinterlegten Umlageschlüssel.
struct OperatingCostBillingView: View {
    /// ViewModel, das alle Eingaben und Berechnungen verwaltet.
    @ObservedObject var viewModel: OperatingCostBillingViewModel
    /// Felder für die Mieterabrechnung – Name, Anschrift, Anteil, Vorauszahlungen.
    @State private var tenantName: String = ""
    @State private var tenantAddress: String = ""
    @State private var shareValue: Double = 1.0
    @State private var prepaymentMonthly: Double = 0.0
    @State private var prepaymentMonths: Int = 12
    /// Felder für Vermieterinformationen (optional). Bei Mehrfamilienhäusern kann der Nutzer sie überschreiben.
    @State private var landlordName: String = ""
    @State private var landlordAddress: String = ""
    @State private var landlordContact: String = ""
    /// Flag, ob ein PDF generiert wurde.
    @State private var generatedPDFUrl: URL? = nil
    /// Formatter für numerische Eingaben (maximal zwei Dezimalstellen, keine Währungssymbole).
    private let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.decimalSeparator = ","
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Titel
                Text("Nebenkosten‑Abrechnung")
                    .font(.phasirSectionTitle)
                    .padding(.top, 8)

                // Vermieterinformationen (optional) – nur anzeigen, wenn der Nutzer etwas eingibt oder wenn kein Name im House hinterlegt ist
                VStack(alignment: .leading, spacing: 12) {
                    Text("Vermieter (optional)")
                        .font(.phasirCaption.weight(.semibold))
                    TextField("Name des Vermieters", text: $landlordName)
                        .textFieldStyle(PhasirNumberFieldStyle())
                    TextField("Adresse des Vermieters", text: $landlordAddress)
                        .textFieldStyle(PhasirNumberFieldStyle())
                    TextField("Kontakt (E‑Mail, Tel)", text: $landlordContact)
                        .textFieldStyle(PhasirNumberFieldStyle())
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )

                // Hausname und Jahr
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.house.name)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    HStack {
                        Text("Abrechnungsjahr")
                            .font(.phasirCaption)
                            .foregroundColor(Color.phasirSecondaryText)
                        Spacer()
                        // Stepper zur Auswahl des Jahres
                        Stepper(value: $viewModel.billingYear, in: 2000...2100, step: 1) {
                            Text("\(viewModel.billingYear)")
                                .font(.phasirCaption.weight(.semibold))
                        }
                        .labelsHidden()
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )

                // Eingabe der Kostenkategorien
                VStack(alignment: .leading, spacing: 0) {
                    Text("Betriebskosten")
                        .font(.phasirSectionTitle)
                        .padding(.bottom, 8)
                    ForEach(OperatingCostCategory.allCases) { category in
                        HStack(alignment: .center) {
                            Image(systemName: category.systemImageName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.phasirAccent)
                                .frame(width: 24)
                            Text(category.displayName)
                                .font(.phasirCaption)
                            Spacer()
                            TextField(
                                "0",
                                value: Binding(
                                    get: { viewModel.categoryCosts[category] ?? 0 },
                                    set: { viewModel.categoryCosts[category] = $0 }
                                ),
                                formatter: numberFormatter
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .textFieldStyle(PhasirNumberFieldStyle())
                        }
                        .padding(.vertical, 8)
                        // Divider zwischen Zeilen, außer nach der letzten Kategorie
                        if category != OperatingCostCategory.allCases.last {
                            Divider()
                                .padding(.leading, 28)
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )

                // Ergebniszusammenfassung
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ergebnis")
                        .font(.phasirSectionTitle)
                    HStack {
                        Text("Gesamtkosten")
                            .font(.phasirCaption)
                        Spacer()
                        Text(viewModel.totalCost.formattedCurrency())
                            .font(.phasirCaption.weight(.semibold))
                    }
                    HStack {
                        Text("Verteilungsschlüssel")
                            .font(.phasirCaption)
                        Spacer()
                        Text(viewModel.distributionKeyDescription)
                            .font(.phasirCaption.weight(.semibold))
                    }
                    if let perUnit = viewModel.costPerUnit {
                        HStack {
                            Text("Kosten pro Einheit")
                                .font(.phasirCaption)
                            Spacer()
                            Text(perUnit.formattedCurrency())
                                .font(.phasirCaption.weight(.semibold))
                        }
                    } else {
                        Text("Keine Verteilung möglich – bitte Werte im Hausprofil ergänzen.")
                            .font(.phasirCaption)
                            .foregroundColor(Color.phasirSecondaryText)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )

                // Mieterinformationen & individuelle Abrechnung
                VStack(alignment: .leading, spacing: 0) {
                    Text("Mieterabrechnung")
                        .font(.phasirSectionTitle)
                        .padding(.bottom, 8)
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Name des Mieters", text: $tenantName)
                            .textFieldStyle(PhasirNumberFieldStyle())
                        TextField("Anschrift des Mieters", text: $tenantAddress)
                            .textFieldStyle(PhasirNumberFieldStyle())
                        // Anteil / Schlüsselwert
                        if !isSingleUnit {
                            Text("Anteil des Mieters")
                                .font(.phasirCaption.weight(.semibold))
                            TextField(sharePlaceholder(), value: $shareValue, formatter: numberFormatter)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(PhasirNumberFieldStyle())
                        } else {
                            // Bei Einzelobjekten hat der Mieter immer 100 % Anteil
                            Text("Anteil des Mieters: 100 %")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }
                        // Vorauszahlungen
                        Text("Vorauszahlungen")
                            .font(.phasirCaption.weight(.semibold))
                        TextField("Monatliche Vorauszahlung (€)", value: $prepaymentMonthly, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(PhasirNumberFieldStyle())
                        HStack {
                            Text("Monate vorausbezahlt")
                                .font(.phasirCaption)
                            Spacer()
                            Stepper(value: $prepaymentMonths, in: 1...24, step: 1) {
                                Text("\(prepaymentMonths)")
                                    .font(.phasirCaption.weight(.semibold))
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)

                    // Ergebnisabschnitt für Mieter
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mieter-Ergebnis")
                            .font(.phasirCaption.weight(.semibold))
                        HStack {
                            Text("Kostenanteil des Mieters")
                                .font(.phasirCaption)
                            Spacer()
                            if let shareCost = tenantShareCost {
                                Text(shareCost.formattedCurrency())
                                    .font(.phasirCaption.weight(.semibold))
                            } else {
                                Text("–")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                        HStack {
                            Text("Vorauszahlungen gesamt")
                                .font(.phasirCaption)
                            Spacer()
                            Text(prepaymentTotal.formattedCurrency())
                                .font(.phasirCaption.weight(.semibold))
                        }
                        HStack {
                            Text("Nachzahlung / Guthaben")
                                .font(.phasirCaption)
                            Spacer()
                            if let result = finalResult {
                                if result > 0 {
                                    Text("+" + result.formattedCurrency())
                                        .font(.phasirCaption.weight(.semibold))
                                        .foregroundColor(Color.red)
                                } else if result < 0 {
                                    Text("−" + ((-result).formattedCurrency()))
                                        .font(.phasirCaption.weight(.semibold))
                                        .foregroundColor(Color.green)
                                } else {
                                    Text("0,00 €")
                                        .font(.phasirCaption.weight(.semibold))
                                }
                            } else {
                                Text("–")
                                    .font(.phasirCaption)
                                    .foregroundColor(Color.phasirSecondaryText)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                    // Aktionen: PDF generieren / teilen
                    VStack(spacing: 12) {
                        if generatedPDFUrl == nil {
                            Button {
                                // Versuche, die Eingaben in PDF zu konvertieren
                            generatedPDFUrl = viewModel.generateTenantPDF(
                                    tenantName: tenantName,
                                    tenantAddress: tenantAddress,
                                    shareValue: shareValue,
                                    prepaymentMonthly: prepaymentMonthly,
                                    prepaymentMonths: prepaymentMonths,
                                    landlordName: landlordName.isEmpty ? nil : landlordName,
                                    landlordAddress: landlordAddress.isEmpty ? nil : landlordAddress,
                                    landlordContact: landlordContact.isEmpty ? nil : landlordContact
                                )
                            } label: {
                                HStack {
                                    Image(systemName: "doc.richtext")
                                    Text("PDF generieren")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.phasirAccent.opacity(0.1))
                                )
                                .foregroundColor(Color.phasirAccent)
                            }
                            .buttonStyle(.plain)
                        }
                        if let pdfURL = generatedPDFUrl {
                            ShareLink(item: pdfURL) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("PDF teilen")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.phasirAccent.opacity(0.1))
                                )
                                .foregroundColor(Color.phasirAccent)
                            }
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )
                .padding(.vertical, 8)

                Spacer(minLength: 24)
            }
            .padding(.horizontal, PhasirDesign.screenPadding)
            .padding(.bottom, 24)
        }
        .background(Color.phasirBackground.ignoresSafeArea())
        .navigationBarTitle("Nebenkosten", displayMode: .inline)
        .onAppear {
            // Setze den Anteil auf 100 % für Einzelobjekte
            if isSingleUnit {
                shareValue = 1.0
            }
        }
    }

    // MARK: - Mieterbezogene Berechnungen
    /// Kostenanteil des Mieters auf Basis des Schlüsselwerts.
    private var tenantShareCost: Double? {
        guard let perUnit = viewModel.costPerUnit else { return nil }
        return perUnit * shareValue
    }

    /// Gesamtsumme der Vorauszahlungen des Mieters.
    private var prepaymentTotal: Double {
        prepaymentMonthly * Double(prepaymentMonths)
    }

    /// Endergebnis (Nachzahlung oder Guthaben). Positive Werte bedeuten Nachzahlung.
    private var finalResult: Double? {
        guard let shareCost = tenantShareCost else { return nil }
        return shareCost - prepaymentTotal
    }

    /// Erzeugt einen Platzhaltertext für den Anteil des Mieters basierend auf dem Verteilungsschlüssel des Hauses.
    private func sharePlaceholder() -> String {
        switch viewModel.house.primaryOperatingCostKey {
        case "sqm": return "Wohnfläche des Mieters (m²)"
        case "people": return "Personenzahl des Mieters"
        case "units": return "Anzahl Einheiten des Mieters"
        case "consumption": return "Verbrauchseinheit des Mieters"
        default: return "Wert für Schlüssel"
        }
    }

    /// Gibt zurück, ob es sich um ein Einzelobjekt handelt (nur eine Einheit).
    private var isSingleUnit: Bool {
        if let billingModel = viewModel.house.billingModel, billingModel == "multi" {
            return false
        }
        if let units = viewModel.house.unitCount, units > 1 {
            return false
        }
        return true
    }
}

// MARK: - Individuelles TextField‑Style für numerische Eingaben
/// Spezieller Input‑Style für Zahleneingaben, passend zum Phasir‑Design.
private struct PhasirNumberFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.phasirCard.opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.phasirAccent.opacity(0.4), lineWidth: 1)
            )
            .font(.system(size: 14, weight: .regular, design: .rounded))
    }
}

// MARK: - Hilfs-Extensions
/// Globale Extension zum Formatieren von Geldbeträgen als Euro.
extension Double {
    /// Gibt die Zahl formatiert als Eurobetrag zurück (z. B. "1.234,56 €").
    func formattedCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f €", self)
    }
}
