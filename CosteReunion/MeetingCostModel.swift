//
//  MeetingCostModel.swift
//  CosteReunion
//
//  Estado y cálculos del coste de la reunión, separados de la vista.
//  El tiempo se deriva del reloj real, no sumando segundos, para no acumular deriva.
//
//  Este es el "cerebro" de la app. La vista (ContentView) solo lo observa y
//  llama a sus acciones; aquí NO se importa SwiftUI ni UIKit a propósito, para
//  que la lógica sea testeable de forma aislada.
//
//  Para AMPLIAR la app, la mayoría de funcionalidades empiezan aquí:
//  añadir estado nuevo (p. ej. moneda, historial) y una acción que lo modifique.
//

import Foundation

/// `@Observable` (macro de iOS 17) hace que SwiftUI redibuje automáticamente
/// las vistas que leen estas propiedades cuando cambian. Es la evolución del
/// antiguo `ObservableObject` + `@Published`, pero sin escribir `@Published`.
/// `final class` (no `struct`) porque queremos una única instancia compartida
/// con identidad, cuyo estado muta a lo largo de la reunión.
@Observable
final class MeetingCostModel {

    /// Personas presentes y su tarifa. La vista la edita directamente.
    /// Se guarda en el dispositivo en cada cambio y se recupera al arrancar.
    var attendees: [Attendee] {
        didSet { persist() }
    }

    /// Moneda elegida en Ajustes. También se guarda y se recupera al arrancar.
    var currency: Currency {
        didSet { persistCurrency() }
    }

    /// Preferencias de visualización (subtítulo, coste por persona, estimación).
    var preferences: Preferences {
        didSet { persistPreferences() }
    }

    init() {
        // El `didSet` no se dispara en `init`, así que cargar aquí no re-guarda.
        attendees = Self.loadAttendees()
        currency = Self.loadCurrency()
        preferences = Self.loadPreferences()
    }

    // CONCEPTO CLAVE — el cronómetro no cuenta segundos con un temporizador
    // (eso acumularía error y se pausaría en segundo plano). En su lugar
    // guardamos DOS datos y el tiempo transcurrido se CALCULA al leerlo:
    //   · segmentStart: cuándo empezó el tramo que corre ahora (nil = parado).
    //   · savedTime: suma de todos los tramos ya cerrados.
    // Tiempo actual = savedTime + (ahora - segmentStart). Ver currentTime(at:).
    //
    // `private(set)` = se puede leer desde fuera, pero solo el modelo lo cambia.
    private(set) var segmentStart: Date? = nil     // nil = parado
    private(set) var savedTime: TimeInterval = 0    // Tiempo de tramos cerrados

    // El "libro de cuentas": cuánto lleva gastado cada persona, por su id.
    // Guardarlo aparte (y no recalcular sobre la lista actual) permite que
    // alguien se vaya a mitad de reunión sin perder lo que ya costó.
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
    //
    // Reciben `now` como parámetro (en vez de leer Date() dentro) para que la
    // vista pueda pedir "el coste EN ESTE instante de dibujo" usando el reloj
    // del TimelineView. Esto los hace además fáciles de testear con fechas fijas.

    func currentTime(at now: Date) -> TimeInterval {
        // Si está parado, el tiempo es solo lo ya acumulado.
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

    /// Coste por unidad de tiempo (minuto u hora) al ritmo actual.
    func costRate(_ unit: RateUnit) -> Double {
        costPerSecond * unit.seconds
    }

    /// Cuánto costaría una reunión de `minutes` minutos al ritmo actual.
    /// Es una proyección de planificación: no depende del tiempo ya transcurrido.
    func projectedCost(forMinutes minutes: Int) -> Double {
        costPerSecond * Double(minutes) * 60
    }

    /// Coste acumulado de cada persona EN VIVO: lo de tramos cerrados (`ledger`)
    /// más su parte del tramo en curso hasta `now`. Ordenado de más a menos.
    func liveEntries(at now: Date) -> [LedgerEntry] {
        let elapsed = segmentStart.map { now.timeIntervalSince($0) } ?? 0
        var costs = ledger   // copia de lo ya facturado
        for person in attendees {
            costs[person.id, default: LedgerEntry(name: person.name, cost: 0)].cost
                += elapsed * person.hourlyRate / 3600
            costs[person.id]?.name = person.name
        }
        return costs.values.sorted { $0.cost > $1.cost }
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

    /// Cierra el tramo en curso: acumula su tiempo y reparte su coste entre las
    /// personas de `list`, y acto seguido abre un tramo nuevo. Se llama al pausar
    /// y también cuando cambia el reparto de asistentes (con la lista ANTIGUA),
    /// para que cada tramo se facture con las tarifas que estaban vigentes.
    func closeSegment(using list: [Attendee]) {
        guard let start = segmentStart else { return }   // si está parado, nada que cerrar
        let now = Date.now
        let elapsed = now.timeIntervalSince(start)
        savedTime += elapsed
        for person in list {
            // Suma al acumulado de esa persona su parte del tramo.
            // `[clave, default:]` crea la entrada si aún no existía.
            ledger[person.id, default: LedgerEntry(name: person.name, cost: 0)].cost
                += elapsed * person.hourlyRate / 3600
            ledger[person.id]?.name = person.name   // guarda el nombre más reciente
        }
        segmentStart = now   // el nuevo tramo empieza justo donde terminó el anterior
    }

    // MARK: - Persistencia (UserDefaults + JSON)

    private static let storageKey = "attendees"

    /// Lista inicial cuando no hay nada guardado todavía.
    private static let defaultAttendees: [Attendee] = [
        Attendee(name: "Persona 1", hourlyRate: 60),
        Attendee(name: "Persona 2", hourlyRate: 45),
        Attendee(name: "Persona 3", hourlyRate: 35),
    ]

    private static func loadAttendees() -> [Attendee] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Attendee].self, from: data),
              !decoded.isEmpty else {
            return defaultAttendees
        }
        return decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(attendees) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static let currencyKey = "currency"

    private static func loadCurrency() -> Currency {
        guard let raw = UserDefaults.standard.string(forKey: currencyKey),
              let saved = Currency(rawValue: raw) else {
            return .eur   // por defecto, euro
        }
        return saved
    }

    private func persistCurrency() {
        UserDefaults.standard.set(currency.rawValue, forKey: Self.currencyKey)
    }

    private static let prefsKey = "preferences"

    private static func loadPreferences() -> Preferences {
        guard let data = UserDefaults.standard.data(forKey: prefsKey),
              let decoded = try? JSONDecoder().decode(Preferences.self, from: data) else {
            return Preferences()   // valores por defecto
        }
        return decoded
    }

    private func persistPreferences() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: Self.prefsKey)
    }
}
