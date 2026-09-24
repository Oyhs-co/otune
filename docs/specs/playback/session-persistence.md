# SPEC: Session Persistence

## Status
Implemented

## Context
Las preferencias visibles (tema, duración de badges), la última pista, la
posición de reproducción y la cola actual viven sólo en memoria: se pierden al
reiniciar la aplicación. Para un uso diario real, la sesión de escucha debe
sobrevivir al cierre y reapertura de la app.

## Goal
Al abrir la aplicación, las preferencias y la última sesión de reproducción se
restauran de forma predecible, sin iniciar audio automáticamente.

## Scope
- Persistencia de preferencias de settings (tema, duración de badges).
- Persistencia de la cola activa, índice actual, modos (shuffle/repeat) y
  posición de la pista activa.
- Restauración al arrancar desde un snapshot guardado.
- Guardado con debounce durante la reproducción y guardado inmediato al pasar
  a segundo plano.
- Validación del índice de restauración.

## Non-goals
- Reproducir audio automáticamente tras restaurar.
- Persistir el arte embebido del snapshot (se recupera de la biblioteca).
- Persistir historial de reproducción o playlists guardadas.
- Sincronización entre dispositivos.

## Domain rules
- La restauración nunca inicia reproducción: la sesión queda en pausa/idle.
- El índice guardado fuera de rango restaura la cola con índice 0.
- Un snapshot de cola vacía limpia la sesión en lugar de fallar.
- Los modos (shuffle/repeat) se restauran tal cual se guardaron.

## Functional requirements
- FR-SESS-001: cada cambio de preferencia se persiste antes de reportar éxito
  en la UI.
- FR-SESS-002: la cola, el índice, shuffle, repeat y la pista activa con su
  posición se guardan al cambiar y periódicamente durante la reproducción.
- FR-SESS-003: al arrancar, la app restaura preferencias y sesión desde el
  almacenamiento.
- FR-SESS-004: si el snapshot referencia una pista que ya no existe en la
  biblioteca local, la pista se restaura con sus metadatos guardados y la
  reproducción fallará de forma visible si el archivo no está disponible
  (comportamiento de error existente del motor).
- FR-SESS-005: al pasar a segundo plano (`AppLifecycleState.paused`) se
  fuerza un guardado inmediato del snapshot pendiente.

## Scenarios

### Scenario: Reabrir la app con sesión previa
Given una cola con varias pistas y la segunda en reproducción en el minuto 1:23
When el usuario cierra y reabre la aplicación
Then la cola se muestra con las mismas pistas y la segunda como activa
And la posición mostrada es 1:23
And la reproducción NO comienza automáticamente

### Scenario: Snapshot con índice inválido
Given un snapshot guardado con índice 9 para una cola de 3 pistas
When la aplicación restaura la sesión
Then la cola se restaura completa con índice 0
And la reproducción no comienza automáticamente

### Scenario: Snapshot de cola vacía
Given un snapshot guardado sin pistas
When la aplicación restaura la sesión
Then la sesión queda vacía e idle sin errores

### Scenario: Cambiar el tema
Given el usuario está en tema claro
When selecciona tema oscuro en Ajustes
Then el tema oscuro se aplica
And la preferencia persiste tras reiniciar la aplicación

## Edge cases
- Cola con una única pista y shuffle activo.
- Pista eliminada de la biblioteca entre sesiones (se conserva metadatos).
- Corrupción del JSON del snapshot (se descarta y arranca sesión limpia).
- Fallo del almacenamiento al guardar (se registra en el log, sin crash).

## Acceptance criteria
- [x] AC-001: la preferencia de tema sobrevive a un reinicio del contenedor.
  *`test/features/settings/settings_persistence_test.dart`.*
- [x] AC-002: la duración de badges sobrevive a un reinicio del contenedor.
  *`test/features/settings/settings_persistence_test.dart`.*
- [x] AC-003: la cola y el índice se restauran desde el snapshot persistido.
  *`test/features/playback/application/playback_restore_test.dart` y
  `test/features/playback/domain/playback_snapshot_test.dart`.*
- [x] AC-004: la posición de la pista activa se restaura desde el snapshot.
  *`playback_restore_test.dart`.*
- [x] AC-005: la restauración no inicia reproducción automática.
  *`playback_restore_test.dart` (estado del engine tras restaurar).*
- [x] AC-006: un índice fuera de rango restaura con índice 0.
  *`playback_snapshot_test.dart`.*
- [x] AC-007: un snapshot de cola vacía restaura una sesión limpia.
  *`playback_snapshot_test.dart`.*
- [x] AC-008: el watcher fuerza guardado inmediato en `paused`.
  *`flush()` cubierto en `playback_restore_test.dart`; el watcher invoca
  `flush()` en `paused`/`detached`/`hidden`.*

## Testing strategy
- Unit: repositorio de settings con adapter en memoria y repo de snapshots con
  Drift en memoria (`AppDatabase.forTesting`).
- Unit: `PlaybackSnapshotMapper` (serialización/validación de índice).
- Unit: controller con fake: guardado con debounce y restauración.
- Unit: `SessionRestoreWatcher` con lifecycle observable.
- Widget: layout de `NowPlayingPage` en pantallas estrechas y amplias.

## Verification
- `dart format .`: sin cambios pendientes.
- `flutter analyze`: sin issues.
- `flutter test`: 104 pruebas en verde (2026-09-22).
- Nota de implementación: el debounce de guardado es anulable vía
  `playbackSaveDebounceProvider` para que los widget tests no dejen timers
  pendientes.

## Related architecture decisions
- ADR-005-drift-persistence.md (persistencia local)
- ADR-004-riverpod-state.md (arranque vía observers/proveedores)

## Open questions
- Ninguna abierta para este sprint; la decisión de no-autoplay queda definida
  en las reglas de dominio (alineada con ROADMAP Fase 2: "Evitar que una
  restauración automática empiece a reproducir audio sin una decisión de
  producto clara").
