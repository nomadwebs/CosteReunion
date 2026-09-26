//
//  BreakdownView.swift
//  CosteReunion
//
//  Desglose de lo que ha costado la reunión, por persona.
//

import SwiftUI

struct BreakdownView: View {
    let entries: [LedgerEntry]
    let totalTime: TimeInterval
    @Environment(\.dismiss) private var dismiss

    private var total: Double { entries.reduce(0) { $0 + $1.cost } }

    private var timeText: String {
        Duration.seconds(totalTime).formatted(.time(pattern: .hourMinuteSecond))
    }

    /// Texto para compartir el resultado (WhatsApp, Slack, LinkedIn…).
    private var shareText: String {
        "Esta reunión ha costado \(total.formatted(.currency(code: "EUR"))) en \(timeText) con \(entries.count) personas."
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Total", value: total, format: .currency(code: "EUR"))
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
                            Text(entry.cost, format: .currency(code: "EUR"))
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
