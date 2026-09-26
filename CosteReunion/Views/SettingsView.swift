//
//  SettingsView.swift
//  CosteReunion
//
//  Hoja de ajustes: moneda, subtítulo, coste por persona y estimación.
//

import SwiftUI

/// Ajustes de la app. Sigue el mismo patrón desacoplado que AttendeesView:
/// recibe enlaces (`@Binding`) a lo que edita, no el modelo entero. Añadir un
/// ajuste nuevo = una propiedad `@Binding` más y una fila en la lista.
struct SettingsView: View {
    @Binding var currency: Currency
    @Binding var preferences: Preferences
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // `Picker` con estilo de navegación: muestra el valor actual
                    // y abre una lista para elegir. Recorre todos los casos del
                    // enum gracias a `CaseIterable`.
                    Picker("Moneda", selection: $currency) {
                        ForEach(Currency.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } header: {
                    Text("Moneda")
                } footer: {
                    Text("Se usa para mostrar todos los importes de la app.")
                }

                // MARK: Subtítulo
                Section {
                    Toggle("Mostrar tasa de coste", isOn: $preferences.showRateInSubtitle)
                    // El selector de unidad solo tiene sentido si la tasa se muestra.
                    if preferences.showRateInSubtitle {
                        Picker("Unidad", selection: $preferences.rateUnit) {
                            ForEach(RateUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                    }
                } header: {
                    Text("Subtítulo")
                } footer: {
                    Text("Muestra el ritmo de gasto bajo el contador (por minuto o por hora).")
                }

                // MARK: Coste por persona
                Section {
                    Toggle("Coste en vivo por persona", isOn: $preferences.showLivePerPerson)
                } footer: {
                    Text("Añade bajo el contador cuánto lleva gastado cada asistente, en tiempo real.")
                }

                // MARK: Estimación por duración
                Section {
                    Toggle("Estimar por duración", isOn: $preferences.estimateEnabled)
                    if preferences.estimateEnabled {
                        Stepper("Duración: \(preferences.estimatedMinutes) min",
                                value: $preferences.estimatedMinutes,
                                in: 5...480,
                                step: 5)
                    }
                } header: {
                    Text("Duración estimada")
                } footer: {
                    Text("Muestra cuánto costaría la reunión a este ritmo y avisa al superar la duración.")
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}
