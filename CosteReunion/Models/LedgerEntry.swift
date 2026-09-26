//
//  LedgerEntry.swift
//  CosteReunion
//
//  Lo que lleva gastado cada persona en los tramos ya cerrados.
//

import Foundation

/// Lo que lleva gastado cada persona en los tramos ya cerrados.
/// Se guarda aparte para no perder a quien se va a mitad de la reunión.
struct LedgerEntry {
    var name: String
    var cost: Double
}
