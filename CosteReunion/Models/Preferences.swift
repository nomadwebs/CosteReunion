//
//  Preferences.swift
//  CosteReunion
//
//  Ajustes de visualización que el usuario activa/desactiva.
//

import Foundation

/// Unidad para mostrar la tasa de coste en el subtítulo.
enum RateUnit: String, CaseIterable, Identifiable, Codable {
    case perMinute
    case perHour

    var id: String { rawValue }

    /// Texto para el selector de Ajustes.
    var displayName: String {
        switch self {
        case .perMinute: "Por minuto"
        case .perHour: "Por hora"
        }
    }

    /// Coletilla que se añade en el subtítulo ("… por minuto").
    var suffix: String {
        switch self {
        case .perMinute: "por minuto"
        case .perHour: "por hora"
        }
    }

    /// Segundos que representa la unidad (para convertir coste/segundo).
    var seconds: Double {
        switch self {
        case .perMinute: 60
        case .perHour: 3600
        }
    }
}

/// Preferencias de visualización de la app. Se guardan como un solo bloque JSON
/// en UserDefaults, así añadir un ajuste nuevo es solo un campo más aquí.
/// Los valores por defecto reproducen el comportamiento original de la app.
struct Preferences: Codable, Equatable {
    /// Mostrar la tasa de coste (p. ej. "12 € por minuto") en el subtítulo.
    var showRateInSubtitle: Bool = true
    /// Si se muestra, en qué unidad.
    var rateUnit: RateUnit = .perMinute
    /// Mostrar el coste acumulado en vivo, persona a persona, en la pantalla.
    var showLivePerPerson: Bool = false
    /// Activar la estimación por duración ("a este ritmo, N min ≈ X").
    var estimateEnabled: Bool = false
    /// Duración estimada de la reunión, en minutos.
    var estimatedMinutes: Int = 30
}
