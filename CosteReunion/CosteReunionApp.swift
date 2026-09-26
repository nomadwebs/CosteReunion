//
//  CosteReunionApp.swift
//  CosteReunion
//
//  Created by Francisco Sánchez on 23/09/2026.
//

import SwiftUI

// MARK: - Punto de entrada de la app
//
// Mapa rápido del proyecto (por dónde entra el flujo):
//
//   CosteReunionApp  ← estás aquí: arranca la app y muestra la primera pantalla
//        └── ContentView          (Views/… + este fichero) pantalla principal
//              ├── MeetingCostModel  toda la lógica y el estado (el "cerebro")
//              ├── AttendeesView      hoja para editar personas y tarifas
//              └── BreakdownView      hoja con el desglose por persona
//
// Modelos de datos puros en Models/: Attendee y LedgerEntry.

/// `@main` marca el tipo por el que arranca la app: solo puede haber uno.
/// Un `App` describe la app como una o varias "escenas" (ventanas).
@main
struct CosteReunionApp: App {
    // `body` devuelve la escena. `WindowGroup` es la ventana principal;
    // en iOS ocupa toda la pantalla y su contenido es nuestra vista raíz.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
