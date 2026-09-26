//
//  BreakdownView.swift
//  CosteReunion
//
//  Desglose de lo que ha costado la reunión, por persona.
//

import SwiftUI

/// Hoja de solo lectura con el desglose por persona.
/// Recibe DATOS ya calculados (`let`, no un binding ni el modelo): es una "foto"
/// del resultado en el momento de abrirla. Al no mutar nada, es la subvista más
/// simple y la más fácil de testear.
struct BreakdownView: View {
    let entries: [LedgerEntry]
    let totalTime: TimeInterval
    let currencyCode: String   // código ISO de la moneda elegida en Ajustes
    @Environment(\.dismiss) private var dismiss

    private var total: Double { entries.reduce(0) { $0 + $1.cost } }

    private var timeText: String {
        Duration.seconds(totalTime).formatted(.time(pattern: .hourMinuteSecond))
    }

    /// Texto para compartir el resultado (WhatsApp, Slack, LinkedIn…).
    private var shareText: String {
        "Esta reunión ha costado \(total.formatted(.currency(code: currencyCode))) en \(timeText) con \(entries.count) personas."
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Total", value: total, format: .currency(code: currencyCode))
                        .font(.title3.bold())
                    LabeledContent("Duración", value: timeText)
                }

                Section("Por persona") {
                    ForEach(entries.indices, id: \.self) { i in
                        let entry = entries[i]
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.name)
                                if total > 0 {
                                    Text((entry.cost / total).formatted(.percent.precision(.fractionLength(0))))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(entry.cost, format: .currency(code: currencyCode))
                                .monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("Lo que ha costado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: shareText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
