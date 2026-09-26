//
//  ContentView.swift
//  Coste de Reunión
//
//  Una sola función: ver en tiempo real cuánto cuesta una reunión.
//  La lógica del cronómetro y el coste vive en MeetingCostModel.
//  Requiere iOS 17 o superior.
//

import SwiftUI

struct ContentView: View {

    // `@State` aquí = esta vista es la DUEÑA de estos datos y sobreviven a los
    // redibujos. El modelo (el "cerebro") lo posee la vista raíz y vive mientras
    // la pantalla exista. Las dos banderas son estado SOLO de interfaz (qué hoja
    // está abierta); por eso viven en la vista y no en el modelo.
    @State private var model = MeetingCostModel()
    @State private var showingAttendees = false
    @State private var showingBreakdown = false
    @State private var showingSettings = false

    var body: some View {
        // `@Bindable` nos deja crear enlaces de dos vías (`$model.attendees`) a
        // las propiedades de un objeto @Observable, para pasarlos a subvistas
        // que editan datos (aquí, AttendeesView).
        @Bindable var model = model

        VStack(spacing: 24) {
            Spacer()

            // `TimelineView` redibuja su contenido según un horario. Con
            // `.animation` va a ~10 fps, y `paused` lo detiene si no corre el
            // cronómetro (no gastamos batería parados). `context.date` es el
            // instante de cada redibujo: se lo pasamos al modelo para pintar el
            // coste "ahora mismo" sin guardar un contador que se desincronice.
            TimelineView(.animation(minimumInterval: 0.1, paused: !model.isRunning)) { context in
                VStack(spacing: 8) {
                    Text(model.currentCost(at: context.date), format: .currency(code: model.currency.code))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    Text(Duration.seconds(model.currentTime(at: context.date))
                            .formatted(.time(pattern: .hourMinuteSecond)))
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(.secondary)

                    // Coste acumulado en vivo, persona a persona.
                    if model.preferences.showLivePerPerson {
                        livePerPersonList(at: context.date)
                    }

                    // Aviso al superar la duración estimada (solo con el reloj en marcha).
                    if model.preferences.estimateEnabled,
                       model.currentTime(at: context.date) > Double(model.preferences.estimatedMinutes) * 60 {
                        Label("Superados los \(model.preferences.estimatedMinutes) min estimados",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.bold())
                            .foregroundStyle(.orange)
                            .padding(.top, 4)
                    }
                }
            }
            .shadow(radius: 8)

            // Subtítulo: siempre el nº de personas; la tasa de coste es opcional.
            Group {
                if model.preferences.showRateInSubtitle {
                    let rate = model.costRate(model.preferences.rateUnit)
                    Text("\(model.attendees.count) personas · \(rate.formatted(.currency(code: model.currency.code))) \(model.preferences.rateUnit.suffix)")
                } else {
                    Text("\(model.attendees.count) personas")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Proyección de coste para la duración estimada.
            if model.preferences.estimateEnabled {
                let projected = model.projectedCost(forMinutes: model.preferences.estimatedMinutes)
                Text("A este ritmo, \(model.preferences.estimatedMinutes) min ≈ \(projected.formatted(.currency(code: model.currency.code)))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            controlPanel
        }
        .padding()
        // Botón de ajustes flotando arriba a la derecha, sobre el espacio vacío.
        .overlay(alignment: .topTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .tint(.white)
            .padding()
        }
        .background { MeetingRoomBackground() }
        .preferredColorScheme(.dark) // Texto claro sobre la foto oscurecida
        // `.sheet` presenta una hoja modal cuando su bandera es true.
        // A AttendeesView le pasamos un ENLACE ($) para que edite la lista;
        // a BreakdownView solo DATOS (una foto del desglose), porque solo lee.
        // Así las subvistas no dependen del modelo y son reutilizables/testeables.
        .sheet(isPresented: $showingAttendees) {
            AttendeesView(attendees: $model.attendees)
        }
        .sheet(isPresented: $showingBreakdown) {
            BreakdownView(entries: model.breakdownEntries(),
                          totalTime: model.savedTime,
                          currencyCode: model.currency.code)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(currency: $model.currency, preferences: $model.preferences)
        }
        // Si alguien entra, sale o cambia de tarifa con el contador en marcha,
        // cerramos el tramo con la lista ANTIGUA antes de aplicar la nueva.
        .onChange(of: model.attendees) { oldValue, _ in
            model.closeSegment(using: oldValue)
        }
        // `.onChange` reacciona a que un valor cambie. Aquí evitamos que la
        // pantalla se apague mientras el cronómetro corre (efecto de UIKit, por
        // eso vive en la vista y no en el modelo, que se mantiene puro).
        .onChange(of: model.isRunning) { _, running in
            UIApplication.shared.isIdleTimerDisabled = running
        }
        // Vibración sutil (feedback háptico) cada vez que empieza o para.
        .sensoryFeedback(.impact, trigger: model.isRunning)
    }

    // MARK: - Coste en vivo por persona

    /// Lista compacta con lo que lleva gastado cada persona, actualizada en vivo
    /// dentro del TimelineView. Se calcula en el modelo (`liveEntries(at:)`).
    private func livePerPersonList(at now: Date) -> some View {
        let entries = model.liveEntries(at: now)
        return VStack(spacing: 4) {
            ForEach(entries.indices, id: \.self) { i in
                HStack {
                    Text(entries[i].name)
                    Spacer()
                    Text(entries[i].cost, format: .currency(code: model.currency.code))
                        .monospacedDigit()
                }
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: 320)
        .padding(.top, 8)
    }

    // MARK: - Controles

    private var controlPanel: some View {
        VStack(spacing: 12) {
            Button {
                showingAttendees = true
            } label: {
                Label("Asistentes y tarifas", systemImage: "person.2.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if !model.isRunning && model.savedTime > 0 {
                Button {
                    showingBreakdown = true
                } label: {
                    Label("Ver desglose", systemImage: "list.bullet.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    model.reset()
                } label: {
                    Label("Reiniciar", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(model.isRunning || model.savedTime == 0)

                Button(action: toggle) {
                    Label(model.isRunning ? "Pausar" : "Empezar",
                          systemImage: model.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(model.isRunning ? .orange : .green)
            }
        }
        .controlSize(.large)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Acciones

    // La lógica (arrancar/parar, cerrar tramo) la hace el modelo; la vista solo
    // añade el efecto de interfaz: si veníamos de correr, al pausar mostramos
    // automáticamente el desglose.
    private func toggle() {
        let wasRunning = model.isRunning
        model.toggle()
        // Al pausar, enseñamos lo que ha costado cada uno.
        if wasRunning {
            showingBreakdown = true
        }
    }
}

#Preview {
    ContentView()
}
