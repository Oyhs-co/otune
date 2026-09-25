# SPEC: Gestión de Artwork y Refresco de Biblioteca

## Status
Implemented

## Context
El artwork embebido se persiste como blob por pista y cada consulta carga
todos los blobs de la biblioteca a memoria (`getAllTracks()` / `searchTracks()`).
Con bibliotecas de miles de pistas esto degrada el arranque y el scroll, y
las imágenes de gran resolución se almacenan completas. Además, tras un
escaneo la lista no se refresca hasta que una búsqueda o reinicio la reactiva.

## Goal
Las listas de biblioteca cargan metadatos ligeros, el artwork se resuelve
bajo demanda para las pistas visibles con caché acotada, las imágenes
excesivamente grandes se descartan en el escaneo y la biblioteca refresca
sola al terminar un escaneo.

## Scope
- Carga de listas sin blobs (`albumArt` excluido) en `getAllTracks` y
  `searchTracks`.
- Resolución de artwork por pista bajo demanda (`getTrackArtwork`) con caché
  LRU limitada por número de entradas.
- Descarte de imágenes que excedan el límite de tamaño en el escaneo.
- Widget de artwork lazy en lista, detalle y cuadrícula.
- Refresco reactivo de la lista al completar un escaneo.

## Non-goals
- Miniaturas persistidas en disco o redimensionado con encode (thumbnails).
- Caché de disco para artwork.
- Artwork remoto o descargas.
- Cambiar el contrato de `TrackRef` ni el artwork persistido en snapshots.

## User stories
- Como usuario, quiero que la biblioteca abra y haga scroll fluido aunque
  tenga miles de pistas con carátulas grandes.
- Como usuario, quiero ver las carátulas actualizadas sin reiniciar la app
  después de escanear música nueva.

## Domain rules
- DR-001: las consultas de lista no cargan blobs; el artwork se obtiene con
  una operación dedicada por pista.
- DR-002: la caché de artwork es limitada; el desalojo se rige por LRU.
- DR-003: el artwork de las pistas en reproducción se resuelve por la vía
  existente (persistencia/restauración) y no compite con la caché de listas.
- DR-004: una imagen cuyo tamaño exceda el límite del escáner se descarta y
  la pista se indexa igualmente sin artwork.

## Functional requirements
- FR-AW-001: `getAllTracks` y `searchTracks` devuelven `LibraryTrack` con
  `albumArt: null`.
- FR-AW-002: `getTrackArtwork(id)` devuelve los bytes del artwork o `null`.
- FR-AW-003: el widget de artwork resuelve el blob al construirse la fila y
  muestra placeholder si no existe.
- FR-AW-004: la caché evita recargar el artwork de una pista visible
  repetidamente durante el scroll.
- FR-AW-005: al completar un escaneo, la lista de biblioteca se refresca
  automáticamente sin intervención del usuario.
- FR-AW-006: en el escaneo, imágenes mayores que el límite se descartan.

## Scenarios

### Scenario: Lista grande sin degradación
Given una biblioteca con 3000 pistas con carátula embebida
When el usuario abre la biblioteca y hace scroll
Then las consultas de lista no cargan los blobs
And cada pista visible resuelve su artwork por demanda con caché

### Scenario: Artwork ausente o descartado
Given una pista sin carátula o con carátula mayor que el límite
When la fila se muestra en la biblioteca
Then se muestra el placeholder estable
And la pista reproduce normalmente con su arte nulo

### Scenario: Refresco tras escaneo
Given la biblioteca abierta con N pistas
When un escaneo termina y añade M pistas nuevas
Then la lista muestra N + M pistas sin reiniciar la aplicación

## Edge cases
- Pista eliminada entre la consulta y la resolución del artwork: el widget
  muestra placeholder.
- Caché superada por miles de filas: el desalojo LRU mantiene la cota de
  memoria sin recargar la fila visible.
- Escaneo que actualiza artwork existente: la caché se invalida al refrescar
  la lista.

## Acceptance criteria
- [x] AC-AW-001: las listas no incluyen blobs y `getTrackArtwork` resuelve
  los bytes (test del repositorio sobre base de datos en memoria).
- [x] AC-AW-002: la caché desaloja por LRU y respeta su capacidad (test
  unitario de la caché).
- [x] AC-AW-003: el widget de artwork resuelve bajo demanda y muestra
  placeholder sin datos (test de widget con repositorio falso).
- [x] AC-AW-004: la lista refresca al completar un escaneo (test del
  notifier/proveedor).
- [x] AC-AW-005: imágenes mayores que el límite se descartan en el escaneo
  (test del escáner).

## Testing strategy

### Unit
- Caché LRU: capacidad, desalojo e invalidación.
- Repositorio en memoria: listas sin blobs + resolución puntual de artwork.
- Escáner: descarte de imágenes sobre el límite.

### Widget
- `LazyArtwork` resuelve y muestra placeholder ante ausencia.

## Dependencies
- `LibraryRepository` (nueva operación de artwork).
- `FileSystemLibraryScanner` (límite de imágenes).
- `filteredTracksProvider` (refresco reactivo).

## Related DDD
- Bounded context: `library`
- Aggregate/entity: `LibraryTrack`
- Use case: carga eficiente de biblioteca

## Related architecture decisions
- ADR-010: extracción de las operaciones de mantenimiento de `AppDatabase`
  (la resolución puntual de artwork vive en la extensión
  `TracksMaintenance`, `core/database/tracks_maintenance.dart`).

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-AW-001 | `test/features/library/data/library_repository_test.dart` | ✅ |
| AC-AW-002 | `test/features/library/application/artwork_cache_test.dart` | ✅ |
| AC-AW-003 | `test/features/library/presentation/library_widgets_test.dart` | ✅ |
| AC-AW-004 | `test/features/library/application/library_providers_test.dart` | ✅ |
| AC-AW-005 | `test/features/library/data/file_system_library_scanner_test.dart` | ✅ |

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-25 | Initial spec (Sprint 4) | Sprint 4 «Endurecer biblioteca» |
| 2026-09-25 | Referencia a ADR-010: `getTrackArtwork` vive en `TracksMaintenance` | Revisión 2026-09-25 (F-05) |
