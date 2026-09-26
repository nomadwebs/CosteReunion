//
//  Attendee.swift
//  CosteReunion
//
//  Una persona de la reunión y lo que cuesta por hora.
//

import Foundation

/// Una persona de la reunión y lo que cuesta por hora.
struct Attendee: Identifiable, Equatable, Codable {
    // `var` (no `let`) para que Codable decodifique el id y sea estable
    // entre lanzamientos; con `let` se generaría uno nuevo en cada arranque.
    var id = UUID()
    var name: String
    var hourlyRate: Double
}
