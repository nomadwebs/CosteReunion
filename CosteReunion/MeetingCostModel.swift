//
//  MeetingCostModel.swift
//  CosteReunion
//
//  Estado y cálculos del coste de la reunión, separados de la vista.
//  El tiempo se deriva del reloj real, no sumando segundos, para no acumular deriva.
//

import Foundation

@Observable
final class MeetingCostModel {

    /// Personas presentes y su tarifa. La vista la edita directamente.
    var attendees: [Attendee] = [
        Attendee(name: "Persona 1", hourlyRate: 60),
        Attendee(name: "Persona 2", hourlyRate: 45),
        Attendee(name: "Persona 3", hourlyRate: 35),
    ]

    // El cronómetro se calcula a partir del reloj real, no sumando segundos.
    private(set) var segmentStart: Date? = nil     // nil = parado
    private(set) var savedTime: TimeInterval = 0    // Tiempo de tramos cerrados
    private var ledger: [UUID: LedgerEntry] = [:]   // Coste por persona de tramos cerrados

    var isRunning: Bool { segmentStart != nil }

    /// Coste de un segundo de reunión: la suma de todas las tarifas / 3600.
    var costPerSecond: Double {
        attendees.reduce(0) { $0 + $1.hourlyRate } / 3600
    }

    var savedCost: Double {
        ledger.values.reduce(0) { $0 + $1.cost }
    }

    // MARK: - Cálculos

    func currentTime(at now: Date) -> TimeInterval {
        guard let start = segmentStart else { return savedTime }
        return savedTime + now.timeIntervalSince(start)
    }

    func currentCost(at now: Date) -> Double {
        guard let start = segmentStart else { return savedCost }
        return savedCost + now.timeIntervalSince(start) * costPerSecond
    }

    /// Lista para el desglose, de quien más ha costado a quien menos.
    func breakdownEntries() -> [LedgerEntry] {
        ledger.map { id, entry in
            // Si la persona sigue en la lista, usamos su nombre actual.
            let name = attendees.first(where: { $0.id == id })?.name ?? entry.name
            return LedgerEntry(name: name, cost: entry.cost)
        }
        .sorted { $0.cost > $1.cost }
    }

    // MARK: - Acciones

    func toggle() {
        if isRunning {
            closeSegment(using: attendees)
            segmentStart = nil
        } else {
            segmentStart = .now
        }
    }

    func reset() {
        savedTime = 0
        ledger = [:]
        segmentStart = nil
    }

    /// Reparte el tramo en curso entre las personas presentes y empieza uno nuevo.
    func closeSegment(using list: [Attendee]) {
        guard let start = segmentStart else { return }
        let now = Date.now
        let elapsed = now.timeIntervalSince(start)
        savedTime += elapsed
        for person in list {
            ledger[person.id, default: LedgerEntry(name: person.name, cost: 0)].cost
                += elapsed * person.hourlyRate / 3600
            ledger[person.id]?.name = person.name
        }
        segmentStart = now
    }
}
