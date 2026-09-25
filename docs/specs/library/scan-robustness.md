# SPEC: Robustez del Escaneo de Biblioteca

## Status
Implemented

## Context
El escáner actual itera toda la carpeta sin poder cancelarse, no impide que
dos escaneos corran a la vez sobre la misma base de datos, guarda las rutas
tal cual las entrega el selector del sistema y no detecta pistas cuyo archivo
fue eliminado o movido. Con bibliotecas reales esto produce estados zombis,
duplicidad de trabajo y registros que apuntan a archivos inexistentes.

## Goal
Un escaneo cancelable, no reentrante y con limpieza verificable de huérfanos,
sobre rutas normalizadas de forma consistente.

## Scope
- Token de cancelación cooperativo en `LibraryScanner` y `FileSystemLibraryScanner`.
- Guard de escaneo simultáneo en `LibraryScanNotifier`.
- Normalización de rutas (`p.normalize`) al indexar.
- Detección de huérfanos (archivo ausente) con eliminación confirmada y acción
  de deshacer.
- Botón de cancelación en el banner de progreso y estado de cancelación.

## Non-goals
- Escaneo incremental con watcher del filesystem (detección pasiva de cambios).
- Escaneo por lotes paralelizados o aislados (isolate).
- Programación de escaneos automáticos periódicos.
- Reconciliación de metadatos con servicios externos.

## User stories
- Como usuario, quiero cancelar un escaneo largo para seguir usando la app
  sin esperar a que termine.
- Como usuario, quiero que las pistas de archivos que ya no existen se
  limpien de la biblioteca, sin perderlas si me equivoco de botón.

## Domain rules
- DR-001: la cancelación es cooperativa; el escáner emite `ScanCancelled`
  como último evento y no emite `ScanComplete`.
- DR-002: un segundo `scanDirectory` mientras hay un escaneo activo se ignora
  sin interrumpir el escaneo en curso.
- DR-003: el estado de escaneo pertenece al `LibraryScanNotifier`; el
  repositorio sólo expone operaciones de datos (detección y borrado de
  huérfanos).
- DR-004: la eliminación de huérfanos es transaccional, sólo afecta pistas
  verificadas como ausentes y conserva los metadatos para poder restaurarlos.
- DR-005: las operaciones de datos del escaneo (detección y borrado de
  huérfanos, restauración) viven en la extensión `TracksMaintenance`
  (`core/database/tracks_maintenance.dart`, ADR-010), separadas de las
  consultas de lista y ordenación de `AppDatabase`.
- DR-006: el contador de versión del catálogo se expone como
  `libraryVersionProvider` (convención de nombres del resto de providers);
  las listas reactivas se refrescan al observarlo (revisión 2026-09-25, F-03).

## Functional requirements
- FR-SCANR-001: la petición de cancelación detiene el procesamiento en la
  siguiente frontera de archivo y emite `ScanCancelled`.
- FR-SCANR-002: el estado tras cancelar es `isScanning: false` con el resumen
  parcial de archivos procesados.
- FR-SCANR-003: mientras `isScanning` es true, nuevas peticiones de escaneo
  se ignoran y el estado no se reinicia.
- FR-SCANR-004: las rutas indexadas se normalizan con `p.normalize` antes de
  persistirse y de calcular su identificador.
- FR-SCANR-005: existe una operación que devuelve las pistas cuyo archivo no
  existe y otra que las elimina por identificador en una transacción.
- FR-SCANR-006: la UI ofrece la acción «Limpiar ausentes» con confirmación y
  deshacer; tras confirmar, la biblioteca refresca.

## Scenarios

### Scenario: Cancelar un escaneo en curso
Given un escaneo de 200 archivos en progreso
When el usuario pulsa Cancelar en el banner
Then el escáner deja de procesar archivos
And el estado final indica cancelación con el progreso parcial
And no se emite un evento de finalización

### Scenario: Escaneo simultáneo
Given un escaneo activo
When se solicita otro escaneo de otra carpeta
Then la segunda petición se ignora
And el estado del escaneo original no se altera

### Scenario: Archivos eliminados del disco
Given una biblioteca con pistas cuyo archivo ya no existe
When el usuario ejecuta la acción de limpieza de ausentes
Then el sistema lista las pistas afectadas y pide confirmación
And al confirmar, sólo esas pistas se eliminan en una transacción
And la acción puede deshacerse restaurando los registros

## Edge cases
- La cancelación llega justo después del último archivo: se emite
  `ScanComplete` con el total y no `ScanCancelled`.
- El directorio raíz desaparece a mitad de escaneo: error crítico estándar.
- Todas las pistas están ausentes: la acción confirma y vacía la biblioteca.

## Acceptance criteria
- [x] AC-SCANR-001: cancelar un escaneo activo detiene el procesamiento y
  emite `ScanCancelled` (test del escáner con cancelación a mitad de lote).
- [x] AC-SCANR-002: un segundo escaneo mientras hay uno activo se ignora
  (test del notifier con escáner falso que nunca completa).
- [x] AC-SCANR-003: las rutas indexadas quedan normalizadas (test del
  escáner con rutas redundantes).
- [x] AC-SCANR-004: los huérfanos detectados se eliminan de forma
  transaccional y pueden restaurarse (test del repositorio y del notifier).

## Testing strategy

### Unit
- Escáner: cancelación a mitad de lote, `ScanCancelled` como evento final,
  normalización de rutas.
- Notifier: ignorar escaneo concurrente, estado de cancelación, limpieza con
  deshacer.
- Repositorio: detección de huérfanos y eliminación transaccional con
  restauración.

### Widget
- Banner muestra botón Cancelar durante el escaneo y estado de cancelación.
- Banner muestra «Reintentar» habilitado en estado de error con el escaneo
  detenido (revisión 2026-09-25, F-02: la rama de error sólo es alcanzable
  con `isScanning: false`, sin guard redundante).
- Acción de limpieza con diálogo de confirmación y badge de deshacer.

## Dependencies
- `LibraryRepository` (operaciones de huérfanos).
- `LibraryScanNotifier` (guard y ciclo de vida del token).
- `TracksMaintenance` (`core/database/tracks_maintenance.dart`, ADR-010):
  acceso a datos de mantenimiento de pistas.

## Related DDD
- Bounded context: `library`
- Aggregate/entity: `LibraryTrack`
- Use case: escaneo robusto de biblioteca

## Related architecture decisions
- ADR-010: extracción de las operaciones de mantenimiento de `AppDatabase`.

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-SCANR-001 | `test/features/library/data/file_system_library_scanner_test.dart` | ✅ |
| AC-SCANR-002 | `test/features/library/application/library_scan_notifier_test.dart` | ✅ |
| AC-SCANR-003 | `test/features/library/data/file_system_library_scanner_test.dart` | ✅ |
| AC-SCANR-004 | `test/features/library/data/library_repository_test.dart` | ✅ |
| Widget (F-02) | `test/features/library/presentation/library_scan_banner_test.dart` («Reintentar» habilitado con escaneo detenido) | ✅ |

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-25 | Initial spec (Sprint 4) | Sprint 4 «Endurecer biblioteca» |
| 2026-09-25 | DR-005 (`TracksMaintenance`, ADR-010), DR-006 (`libraryVersionProvider`), test de banner «Reintentar» | Revisión 2026-09-25 (F-02, F-03, F-05) |
