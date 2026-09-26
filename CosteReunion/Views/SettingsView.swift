//
//  SettingsView.swift
//  CosteReunion
//
//  Hoja de ajustes de la app. De momento: elegir la moneda.
//

import SwiftUI

/// Ajustes de la app. Sigue el mismo patrón desacoplado que AttendeesView:
/// recibe enlaces (`@Binding`) a lo que edita, no el modelo entero. Añadir un
/// ajuste nuevo = una propiedad `@Binding` más y una fila en la lista.
struct SettingsView: View {
    @Binding var currency: Currency
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
