import SwiftUI
import PDFKit

/// Eine Ansicht zur Eingabe der Mieterangaben und Berechnung des individuellen Kostenanteils.
/// Sie ermöglicht außerdem das Erstellen und Teilen einer rechtssicheren Nebenkostenabrechnung als PDF.
struct TenantBillingView: View {
    @ObservedObject var viewModel: TenantBillingViewModel
    @State private var generatedPDFUrl: URL? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Mieterabrechnung")
                    .font(.phasirSectionTitle)
                    .padding(.top, 8)

                // Stammdaten
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stammdaten des Mieters")
                        .font(.phasirCaption.weight(.semibold))
                    TextField("Name des Mieters", text: $viewModel.tenantName)
                        .textFieldStyle(TenantNumberFieldStyle())
                    TextField("Anschrift des Mieters", text: $viewModel.tenantAddress)
                        .textFieldStyle(TenantNumberFieldStyle())
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )

                // Anteil / Schlüsselwert
                VStack(alignment: .leading, spacing: 12) {
                    Text("Anteil des Mieters")
                        .font(.phasirCaption.weight(.semibold))
                    HStack {
                        Text("Verteilungsschlüssel:")
                            .font(.phasirCaption)
                        Spacer()
                        Text(viewModel.costModel.distributionKeyDescription)
                            .font(.phasirCaption.weight(.semibold))
                            .foregroundColor(Color.phasirAccent)
                    }
                    TextField(
                        placeholderText(),
                        value: $viewModel.shareValue,
                        formatter: numberFormatter
                    )
                    .keyboardType(.decimalPad)
                    .textFieldStyle(TenantNumberFieldStyle())
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )

                // Vorauszahlungen
                VStack(alignment: .leading, spacing: 12) {
                    Text("Vorauszahlungen")
                        .font(.phasirCaption.weight(.semibold))
                    TextField("Monatliche Vorauszahlung (€)", value: $viewModel.prepaymentMonthly, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(TenantNumberFieldStyle())
                    HStack {
                        Text("Monate vorausbezahlt")
                            .font(.phasirCaption)
                        Spacer()
                        Stepper(value: $viewModel.prepaymentMonths, in: 1...24, step: 1) {
                            Text("\(viewModel.prepaymentMonths)")
                                .font(.phasirCaption.weight(.semibold))
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )

                // Ergebnis anzeigen
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ergebnis")
                        .font(.phasirCaption.weight(.semibold))
                    HStack {
                        Text("Kostenanteil des Mieters")
                            .font(.phasirCaption)
                        Spacer()
                        if let shareCost = viewModel.tenantShareCost {
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
                        Text(viewModel.prepaymentTotal.formattedCurrency())
                            .font(.phasirCaption.weight(.semibold))
                    }
                    HStack {
                        Text("Nachzahlung / Guthaben")
                            .font(.phasirCaption)
                        Spacer()
                        if let result = viewModel.finalResult {
                            if result > 0 {
                                Text("+" + result.formattedCurrency())
                                    .font(.phasirCaption.weight(.semibold))
                                    .foregroundColor(Color.red)
                            } else if result < 0 {
                                Text("−" + (-result).formattedCurrency())
                                    .font(.phasirCaption.weight(.semibold))
                                    .foregroundColor(Color.green)
                            } else {
                                Text("0,00 €")
                                    .font(.phasirCaption.weight(.semibold))
                            }
                        } else {
                            Text("–")
                                .font(.phasirCaption)
                                .foregroundColor(Color.phasirSecondaryText)
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.phasirCard)
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
                )

                // PDF generieren / teilen
                VStack(spacing: 12) {
                    if generatedPDFUrl == nil {
                        Button {
                            generatedPDFUrl = viewModel.generatePDF()
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
            .padding(.horizontal, PhasirDesign.screenPadding)
            .padding(.bottom, 32)
        }
        .background(Color.phasirBackground.ignoresSafeArea())
        .navigationTitle("Mieterabrechnung")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Nummernformatter (ohne Währungszeichen) für Eingaben.
    private let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.decimalSeparator = ","
        return f
    }()

    /// Liefert einen anpassbaren Platzhalter für den Schlüsselwert (m², Personen, Einheiten).
    private func placeholderText() -> String {
        switch viewModel.costModel.house.primaryOperatingCostKey {
        case "sqm": return "Wohnfläche des Mieters (m²)"
        case "people": return "Personenzahl des Mieters"
        case "units": return "Anzahl Einheiten (z. B. 1)"
        case "consumption": return "Verbrauchseinheit des Mieters"
        default: return "Wert für Schlüssel"
        }
    }
}

// MARK: - Individueller TextField-Style für Tenant-Billing
/// Stil für Textfelder in der Mieterabrechnung. Ähnlich wie der Nummernfeld-Stil aus der Nebenkostenabrechnung.
private struct TenantNumberFieldStyle: TextFieldStyle {
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
