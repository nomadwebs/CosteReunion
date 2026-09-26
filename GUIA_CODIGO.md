# Guía para estudiar el código de CosteReunion

Una guía práctica para entender cómo está montada la app y por dónde empezar
según lo que quieras tocar. Pensada para aprender, no como documentación formal.

> Si solo lees un fichero, que sea `MeetingCostModel.swift`: es el "cerebro".

---

## 1. El mapa mental (la regla de oro)

La app separa **estado/lógica** de **interfaz**:

- **El modelo** (`MeetingCostModel`) guarda los datos y hace los cálculos.
  No sabe nada de SwiftUI ni de pantallas. Es puro y testeable.
- **Las vistas** (`ContentView` y las de `Views/`) solo *muestran* el modelo y
  le *piden* acciones. No hacen cuentas.

Cuando dudes "¿esto dónde va?": si es un dato o un cálculo → modelo; si es cómo
se ve o se presenta algo → vista.

---

## 2. Orden de lectura recomendado (de fuera hacia dentro)

Léelos en este orden la primera vez:

1. **`CosteReunionApp.swift`** — el arranque. 15 líneas. Aquí está el mapa del
   proyecto en un comentario. Verás que solo lanza `ContentView`.
2. **`Models/`** — los "sustantivos" de la app, todos pequeños:
   - `Attendee.swift` — una persona (nombre + tarifa).
   - `LedgerEntry.swift` — lo que lleva gastado alguien.
   - `Currency.swift` — la moneda (enum con el código ISO).
   - `Preferences.swift` — los ajustes que se activan/desactivan.
3. **`MeetingCostModel.swift`** — el cerebro. Léelo despacio; el resto de la app
   gira alrededor de él. Fíjate en el bloque "CONCEPTO CLAVE" del cronómetro.
4. **`ContentView.swift`** — la pantalla principal: junta el modelo con los
   botones, el contador y las hojas (sheets).
5. **`Views/`** — las pantallas secundarias, cada una independiente:
   - `AttendeesView.swift` — editar personas (recibe un `@Binding`, edita).
   - `SettingsView.swift` — ajustes (recibe `@Binding`, edita).
   - `BreakdownView.swift` — desglose (recibe datos `let`, solo lee).
   - `MeetingRoomBackground.swift` — el fondo.

---

## 3. Conceptos clave que verás repetidos

| Concepto | Qué es | Dónde mirarlo |
|----------|--------|---------------|
| `@Observable` | Hace que la vista se redibuje al cambiar un dato del modelo | `MeetingCostModel` |
| `@State` | La vista es DUEÑA de ese dato y sobrevive a redibujos | arriba de `ContentView` |
| `@Binding` | Referencia editable a un dato de OTRA vista | `AttendeesView`, `SettingsView` |
| `@Bindable` | Sacar `$enlaces` de un objeto `@Observable` | dentro del `body` de `ContentView` |
| Reloj real | El tiempo se CALCULA (no se cuenta con un timer) | `segmentStart`/`savedTime` en el modelo |
| `TimelineView` | Redibuja a intervalos para animar el contador | `ContentView`, primer bloque |
| `ledger` | Coste por persona guardado por `id`, para no perder a quien se va | modelo |
| Persistencia | `UserDefaults` + JSON en un `didSet` | final del modelo |

---

## 4. "Quiero cambiar X": por dónde empiezo

### Cambiar un cálculo (coste, tiempo, proyección)
→ **`MeetingCostModel.swift`**, sección `// MARK: - Cálculos`.
Ahí están `currentCost(at:)`, `costRate(_:)`, `projectedCost(forMinutes:)`,
`liveEntries(at:)`. Cambia la fórmula y la interfaz se actualiza sola.

### Añadir un ajuste nuevo (un interruptor, un selector)
Tres pasos:
1. Añade el campo a **`Preferences`** (con su valor por defecto).
2. Añade una fila (`Toggle`/`Picker`/`Stepper`) en **`SettingsView`** usando
   `$preferences.tuCampo`.
3. Úsalo donde toque en **`ContentView`** (`model.preferences.tuCampo`).
La persistencia es automática: `Preferences` se guarda entero en un `didSet`.

### Cambiar la pantalla principal (contador, subtítulo, avisos)
→ **`ContentView.swift`**, dentro de `body`. El contador grande vive en el
`TimelineView`; el subtítulo y la estimación, justo debajo.

### Tocar los botones (empezar, pausar, reiniciar, ajustes)
→ **`ContentView.swift`**, propiedad `controlPanel`. La acción de arrancar/parar
está en `toggle()` (vista) que llama a `model.toggle()` (lógica).

### Editar personas o su límite
→ **`AttendeesView.swift`**. El tope está en `maxAttendees`.

### Cambiar el desglose o el texto de compartir
→ **`BreakdownView.swift`**.

### Añadir una moneda
→ **`Currency.swift`**: un `case` más con su código ISO y su `displayName`.

### Cambiar dónde/cómo se guardan los datos
→ **`MeetingCostModel.swift`**, sección `// MARK: - Persistencia`.
Ojo: la reunión en curso (tiempo y `ledger`) NO se guarda a propósito; solo la
lista de asistentes, la moneda y las preferencias.

---

## 5. Cómo probar sin compilar toda la app

- **`XcodeRefreshCodeIssuesInFile`**: errores del fichero en segundo (types,
  APIs mal escritas). Úsalo mientras editas.
- **`RunCodeSnippet`**: ejecuta un trozo de código en el contexto de un fichero.
  Ideal para probar el modelo (p. ej. crear un `MeetingCostModel`, mutar y ver
  qué guarda). Así verificamos la persistencia sin abrir la app.
- **`BuildProject`**: compila del todo. La verdad definitiva, pero más lento.

---

## 6. Siguiente paso natural para aprender

Escribir un test del modelo con **Swift Testing** (`import Testing`, `@Test`,
`#expect`) en `CosteReunionTests`. Como la lógica está aislada en
`MeetingCostModel`, puedes comprobar, por ejemplo, que tras cambiar tarifas a
mitad de reunión el reparto por persona sigue siendo correcto. Es la mejor forma
de entender el modelo... rompiéndolo a propósito y viendo qué falla.
