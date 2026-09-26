//
//  AttendeesView.swift
//  CosteReunion
//
//  Editar la lista de asistentes y sus tarifas.
//

import SwiftUI

struct AttendeesView: View {
    @Binding var attendees: [Attendee]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($attendees) { $person in
                        HStack {
                            TextField("Nombre", text: $person.name)
                            TextField("0", value: $person.hourlyRate, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text("€/h")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { attendees.remove(atOffsets: $0) }
                    .deleteDisabled(attendees.count == 1)
                } footer: {
                    Text("Coste por hora de cada persona. Si no lo sabes exacto, pon una estimación: lo que importa es el orden de magnitud.")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Asistentes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        attendees.append(Attendee(
                            name: "Persona \(attendees.count + 1)",
                            hourlyRate: attendees.last?.hourlyRate ?? 50))
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}
