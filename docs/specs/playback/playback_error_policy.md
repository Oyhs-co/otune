# SPEC: Política de Errores de Reproducción

## Status
Implemented

## Context
El motor emite errores como strings libres (`errorMessage`) y la aplicación no
hace nada con ellos: una pista inexistente, corrupta o sin permisos deja la
sesión en estado `error` sin feedback y sin recuperación, y el resto de la
cola queda bloqueada. Para bibliotecas reales esto hace inutilizable el
reproductor.

## Goal
Los fallos de reproducción se clasifican en tipos del dominio, se comunican al
usuario con un mensaje accionable y no bloquean el resto de la cola.

## Scope
- Tipado de fallos del motor en una taxonomía de dominio.
- Salto automático a la pista siguiente cuando la carga falla, con límite de
  fallos consecutivos.
- Superficie de error con reintento en Now Playing y mini player.

## Non-goals
- Reparación de archivos o re-descarga de metadatos.
- Reintento automático infinito o backoff exponencial.
- Diagnóstico de codecs no soportados por plataforma.
- Persistencia del historial de fallos.

## Domain rules
- DR-001: el dominio sólo razona con `PlaybackFailureKind` (missingFile,
  corruptFile, permissionDenied, unknown); los strings del motor se traducen
  en el borde de la aplicación.
- DR-002: al fallar la carga de una pista, se avanza automáticamente a la
  siguiente pista disponible; la pista fallida permanece en la cola.
- DR-003: tras `maxConsecutiveFailures` (3) fallos consecutivos sin una
  reproducción sana intermedia, el motor se detiene y se muestra el error;
  el contador se reinicia con cualquier reproducción con éxito.
- DR-004: el mensaje de error del estado sólo es significativo en
  `PlaybackStatus.error`; un estado posterior no contaminado no reporta el
  error anterior.
- DR-005: la acción de reintento reinicia el contador de fallos y recarga la
  pista activa.

## Functional requirements
- FR-ERR-001: cada fallo de carga genera un `PlaybackFailure` clasificado y
  visible para la UI.
- FR-ERR-002: la UI muestra el mensaje accionable del fallo con una acción
  "Reintentar" en Now Playing y un indicador en el mini player.
- FR-ERR-003: si no existe pista siguiente, el motor se detiene en lugar de
  quedar en error silencioso.

## Scenarios

### Scenario: Pista inexistente con cola de varias pistas
Given una cola de tres pistas donde la primera apunta a un archivo inexistente
When el usuario inicia la reproducción
Then la primera pista falla con un fallo clasificado como archivo no disponible
And la segunda pista comienza a reproducirse automáticamente

### Scenario: Demasiados fallos consecutivos
Given tres pistas consecutivas cuyos archivos no existen
When la reproducción avanza automáticamente por cada fallo
Then tras el tercer fallo el motor se detiene
And la UI muestra el mensaje del último fallo con acción de reintento

### Scenario: Recuperación con reintento
Given el motor detenido tras fallos consecutivos
When el usuario pulsa Reintentar
Then la pista activa se recarga y, si tiene éxito, el contador de fallos
And la reproducción continúa con normalidad

### Scenario: Error aislado no bloquea la cola
Given una pista corrupta entre dos pistas válidas
When la pista corrupta intenta reproducirse
Then el salto automático ocurre una sola vez
And las pistas válidas se reproducen sin interrupciones adicionales

## Edge cases
- Fallo en la única pista de la cola: el motor se detiene y la UI muestra el
  error (no hay salto posible).
- Fallo de permisos: se clasifica como permissionDenied y el mensaje sugiere
  revisar permisos del sistema.
- Error de motor con mensaje vacío: se clasifica como unknown.
- Restaura de sesión con pista eliminada: la reproducción falla de forma
  visible (ya definido en session-persistence), ahora con salto automático.

## Acceptance criteria
- [x] AC-001: una pista inexistente no bloquea la cola; se avanza a la
  siguiente automáticamente. *`playback_controller_test.dart`.*
- [x] AC-002: tras 3 fallos consecutivos el motor se detiene.
  *`playback_controller_test.dart`.*
- [x] AC-003: `retryCurrentTrack()` recarga la pista activa y limpia el
  contador. *`playback_controller_test.dart`.*
- [x] AC-004: los fallos se clasifican en la taxonomía del dominio.
  *`playback_failure_test.dart`.*
- [x] AC-005: Now Playing muestra el mensaje accionable con acción
  Reintentar. *`now_playing_page_test.dart`.*
- [x] AC-006: el mini player indica el fallo mientras dura el error.
  *`mini_player_test.dart`.*

## Testing strategy
### Unit
- `PlaybackFailure.categorize` con mensajes representativos del motor.
- Controller con `FakeAudioEngine` forzando errores en `load`.

### Widget
- Banner de error y acción de reintento en `NowPlayingPage`.
- Indicador de error en `MiniPlayer`.

## Related DDD
- Bounded context: `playback`
- Entity: `PlaybackFailure`
- Use case: política de salto ante fallos de carga

## Related ADRs
- ADR-003 (abstracción AudioEngine: los errores del motor se traducen en el
  borde, el dominio no conoce media_kit)

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-001 | `playback_controller_test.dart` | ✅ |
| AC-002 | `playback_controller_test.dart` | ✅ |
| AC-003 | `playback_controller_test.dart` | ✅ |
| AC-004 | `playback_failure_test.dart` | ✅ |
| AC-005 | `now_playing_page_test.dart` | ✅ |
| AC-006 | `mini_player_test.dart` | ✅ |

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-23 | Initial spec | Sprint 3 S3-3 |
