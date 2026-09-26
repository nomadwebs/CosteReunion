//
//  AttendeesView.swift
//  CosteReunion
//
//  Editar la lista de asistentes y sus tarifas.
//

import SwiftUI

/// Hoja para editar la lista de asistentes.
/// No conoce el modelo: recibe un `@Binding` a la lista, así que edita
/// directamente el array del dueño (ContentView → modelo). Esto la mantiene
/// reutilizable y fácil de previsualizar con datos de prueba.
struct AttendeesView: View {
    // `@Binding` = referencia editable a un dato de OTRA vista (no lo poseemos).
    @Binding var attendees: [Attendee]
    // `dismiss` cierra la hoja; lo inyecta el entorno de SwiftUI.
    @Environment(\.dismiss) private var dismiss

    /// Tope de asistentes. La app está pensada para reuniones pequeñas.
    private let maxAttendees = 10

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
                    // Al llegar al tope avisamos; si no, mostramos la ayuda normal.
                    if attendees.count >= maxAttendees {
                        Text("Máximo \(maxAttendees) asistentes.")
                    } else {
                        Text("Coste por hora de cada persona. Si no lo sabes exacto, pon una estimación: lo que importa es el orden de magnitud.")
                    }
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
                    // Se desactiva al alcanzar el tope de asistentes.
                    .disabled(attendees.count >= maxAttendees)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}
