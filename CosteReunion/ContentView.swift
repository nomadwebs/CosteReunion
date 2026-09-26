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

    @State private var model = MeetingCostModel()
    @State private var showingAttendees = false
    @State private var showingBreakdown = false

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 24) {
            Spacer()

            // Se redibuja ~10 veces por segundo solo mientras corre.
            TimelineView(.animation(minimumInterval: 0.1, paused: !model.isRunning)) { context in
                VStack(spacing: 8) {
                    Text(model.currentCost(at: context.date), format: .currency(code: "EUR"))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    Text(Duration.seconds(model.currentTime(at: context.date))
                            .formatted(.time(pattern: .hourMinuteSecond)))
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .shadow(radius: 8)

            Text("\(model.attendees.count) personas · \((model.costPerSecond * 60).formatted(.currency(code: "EUR"))) por minuto")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            controlPanel
        }
        .padding()
        .background { MeetingRoomBackground() }
        .preferredColorScheme(.dark) // Texto claro sobre la foto oscurecida
        .sheet(isPresented: $showingAttendees) {
            AttendeesView(attendees: $model.attendees)
        }
        .sheet(isPresented: $showingBreakdown) {
            BreakdownView(entries: model.breakdownEntries(), totalTime: model.savedTime)
        }
        // Si alguien entra, sale o cambia de tarifa con el contador en marcha,
        // cerramos el tramo con la lista ANTIGUA antes de aplicar la nueva.
        .onChange(of: model.attendees) { oldValue, _ in
            model.closeSegment(using: oldValue)
        }
        // Pantalla siempre encendida mientras corre.
        .onChange(of: model.isRunning) { _, running in
            UIApplication.shared.isIdleTimerDisabled = running
        }
        .sensoryFeedback(.impact, trigger: model.isRunning)
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
