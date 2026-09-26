//
//  Attendee.swift
//  CosteReunion
//
//  Una persona de la reunión y lo que cuesta por hora.
//

import Foundation

/// Una persona de la reunión y lo que cuesta por hora.
struct Attendee: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var hourlyRate: Double
}
