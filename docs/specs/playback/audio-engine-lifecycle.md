# SPEC: Motor de Audio y Ciclo de Vida de la Cola

## Status
Implemented

## Context
La transición automática entre pistas y los controles de la UI presentan
estados contradictorios en frontera: con cola vacía todos los botones de
`PlaybackControls` permanecen activos y provocan operaciones sin sentido; el
listener de finalización llama a `getNextIndex()` incluso con `repeat one`,
donde recargar la pista produce un hueco audible y un reinicio de posición
innecesario.

## Goal
Play/pausa/reanudar/detener y la transición automática al terminar una pista
se comportan de forma predecible en todos los modos (off/all/one, shuffle) y
la UI no ofrece acciones sin sentido.

## Scope
- Deshabilitar controles de reproducción sin pista activa.
- Transición automática al terminar pista, en todos los modos de repetición
  y con shuffle activo.
- Comportamiento en frontera de shuffle/repeat (pista ya reproducida,
  repeat cambiando mientras la pista termina).

## Non-goals
- Reproducción en segundo plano y controles del sistema (SPEC
  background_audio).
- Interrupciones y audio focus (SPEC playback_interruptions).
- Políticas de errores de carga (SPEC playback_error_policy).
- Gapless playback real (decodificación anticipada).

## Domain rules
- DR-001: sin pista activa, ningún control de reproducción es accionable.
- DR-002: con `repeat one`, la transición automática reinicia la posición y
  reanuda la misma pista sin recargarla ni mover el índice.
- DR-003: con `repeat off` al llegar al final de la cola, el motor se detiene
  en estado idle y la cola conserva el último índice.
- DR-004: con `repeat all`, la transición automática regresa al primer
  elemento (o al primero de la secuencia shuffle).
- DR-005: alternar shuffle con una pista ya reproducida conserva la pista
  actual como cabeza de la nueva secuencia aleatoria; el historial previo no
  se conserva.

## Functional requirements
- FR-AE-001: los botones play/pausa, siguiente, anterior, shuffle y repetir
  se deshabilitan cuando no existe pista activa.
- FR-AE-002: siguiente/anterior se habilitan sólo si existe destino
  (`hasNext`/`hasPrevious`).
- FR-AE-003: al recibir `completed` del motor, el controller aplica la
  regla correspondiente al modo activo sin intervención del usuario.

## Scenarios

### Scenario: Cola vacía
Given una cola sin pistas
When se muestra la pantalla de reproducción
Then todos los controles de reproducción están deshabilitados
And no se produce ninguna operación de audio

### Scenario: Repeat one al terminar la pista
Given repeat one activo y la pista actual terminando
When el motor emite completed
Then la posición vuelve a cero
And la misma pista se reanuda sin recargar el archivo

### Scenario: Repeat off al terminar la última pista
Given repeat off y la última pista de la cola terminando
When el motor emite completed
Then el motor queda en idle con posición cero
And el índice de cola no cambia

### Scenario: Repeat all al terminar la última pista
Given repeat all y la última pista terminando
When el motor emite completed
Then la primera pista de la cola comienza a reproducirse

### Scenario: Shuffle activado con pista en curso
Given una pista ya reproducida hasta la mitad
When el usuario activa shuffle
Then la pista actual continúa
And la siguiente pista de la nueva secuencia aleatoria no es la actual

## Edge cases
- Cola de una sola pista con shuffle: siguiente está deshabilitado con
  repeat off.
- Cambiar repeat mientras la pista está terminando: se aplica el modo que
  esté activo en el instante del evento `completed`.
- `completed` recibido dos veces para la misma carga (protección: la
  transición sólo se dispara una vez por estado `completed` recibido).

## Acceptance criteria
- [x] AC-001: sin pista activa, los controles se deshabilitan.
  *`playback_controls_test.dart`.*
- [x] AC-002: con repeat one, completed reinicia y reanuda sin recargar.
  *`playback_controller_test.dart` (repeat one no recarga ni mueve índice).*
- [x] AC-003: con repeat off al fin de cola, el motor queda idle.
  *`playback_controller_test.dart`.*
- [x] AC-004: con repeat all, completed regresa al primer elemento.
  *`queue_test.dart` + `playback_controller_test.dart`.*
- [x] AC-005: shuffle alternado conserva la pista actual como cabeza de la
  secuencia. *`queue_test.dart` (ya cubierto; se mantiene como contrato).*

## Testing strategy
### Unit
- Transiciones de `PlaybackQueue` en frontera (ya existentes + nuevas).
- Listener de `completed` del controller con `FakeAudioEngine`.

### Widget
- Estado habilitado/deshabilitado de `PlaybackControls`.

## Related DDD
- Bounded context: `playback`
- Aggregate: `PlaybackQueue`
- Use case: transición automática de pista

## Related ADRs
- ADR-003 (abstracción AudioEngine)

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-001 | `playback_controls_test.dart` | ✅ |
| AC-002 | `playback_controller_test.dart` | ✅ |
| AC-003 | `playback_controller_test.dart` | ✅ |
| AC-004 | `queue_test.dart`, `playback_controller_test.dart` | ✅ |
| AC-005 | `queue_test.dart` | ✅ |

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-23 | Initial spec | Sprint 3 S3-2 |
