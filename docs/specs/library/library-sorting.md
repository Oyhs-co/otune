# SPEC: Ordenación de Biblioteca

## Status
Implemented

## Context
La biblioteca se muestra siempre en el orden de inserción de la base de
datos. Con catálogos medianos y grandes, encontrar una pista exige pasar por
la búsqueda; no existe una forma estable de navegar alfabéticamente ni por
fecha de incorporación. El ítem de la Fase 3 del ROADMAP («Ordenar por
título, artista, álbum y fecha de incorporación») queda así cubierto.

## Goal
La lista de biblioteca puede ordenarse por título, artista, álbum y fecha de
incorporación de forma estable y persistida junto al resto de preferencias
de vista.

## Scope
- Selector de orden en las acciones del AppBar de biblioteca.
- Ordenación en la capa de datos (SQL) para título, artista, álbum y fecha
  de incorporación (`added_at`, migración de esquema v3 → v4).
- Persistencia de la preferencia de orden en `SettingsRepository`.
- Truncamiento con ellipsis coherente de títulos y artistas largos en las
  tres vistas de la biblioteca.

## Non-goals
- Ordenación personalizada manual (drag & drop de la biblioteca).
- Agrupaciones por sección (encabezados alfabéticos).
- Ordenación dentro de la cola de reproducción (ya cubierta por la SPEC de
  cola adaptativa).
- Filtros por género.

## User stories
- Como usuario, quiero ordenar mi biblioteca alfabéticamente para localizar
  una pista sin escribir una búsqueda.
- Como usuario, quiero ver primero lo último que añadí para validar un
  escaneo reciente.

## Domain rules
- DR-001: el orden es un parámetro de la consulta de listado; el dominio no
  reordena en memoria lo que la base de datos puede devolver ordenado.
- DR-002: la ordenación por texto es insensible a mayúsculas/minúsculas.
- DR-003: la pista en reproducción conserva su resaltado con independencia
  del orden activo.
- DR-004: la preferencia de orden sobrevive al reinicio de la aplicación.

## Functional requirements
- FR-SORT-001: existe una enumeración de criterios `title`, `artist`,
  `album` y `addedAt`, con `title` como predeterminado.
- FR-SORT-002: cada criterio ordena de forma ascendente y estable.
- FR-SORT-003: la fecha de incorporación ordena de más reciente a más
  antigua.
- FR-SORT-004: cambiar el criterio reordena la lista visible al instante.
- FR-SORT-005: la preferencia persiste vía `SettingsRepository`.
- FR-SORT-006: títulos, artistas y álbumes largos se truncan con ellipsis en
  lista, detalle y cuadrícula.

## Scenarios

### Scenario: Ordenar por título
Given una biblioteca con pistas «Zeta», «alfa» y «Midnight»
When el usuario selecciona ordenar por título
Then la lista muestra «alfa», «Midnight», «Zeta» en ese orden

### Scenario: Ordenar por incorporación
Given una biblioteca donde la última pista escaneada es «Nueva»
When el usuario selecciona ordenar por fecha de incorporación
Then «Nueva» aparece en la primera posición

### Scenario: Persistencia del criterio
Given el usuario selecciona ordenar por artista
When la aplicación se cierra y reabre
Then la biblioteca se muestra ordenada por artista

## Edge cases
- Artista o álbum nulos: se ordenan con el fallback «Artista desconocido» /
  «Álbum desconocido» al final del grupo correspondiente.
- Títulos con acentos y Unicode: la ordenación es estable y predecible.
- Pistas añadidas en la misma transacción: el orden de incorporación conserva
  el orden del escaneo.

## Acceptance criteria
- [x] AC-SORT-001: cada criterio ordena correctamente en una base de datos
  en memoria (test del repositorio).
- [x] AC-SORT-002: la migración v3 → v4 añade `added_at` sin pérdida de
  datos (test de migración/open de esquema v4).
- [x] AC-SORT-003: el criterio persiste y se hidrata al arrancar (test del
  notifier de settings).
- [x] AC-SORT-004: el selector de orden está disponible en la biblioteca y
  reordena la lista (test de widget).

## Testing strategy

### Unit
- Repositorio en memoria: orden por cada criterio y nulos.
- Settings: persistencia e hidratación del criterio.

### Widget
- Selector de orden en el AppBar y reordenación visible.

## Dependencies
- Migración Drift v3 → v4 (columna `added_at`).
- `SettingsRepository` (persistencia del criterio).
- `filteredTracksProvider` (parámetro de orden).

## Related DDD
- Bounded context: `library`
- Aggregate/entity: `LibraryTrack`
- Use case: listado ordenado de biblioteca

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-SORT-001 | `test/features/library/data/library_repository_test.dart` | ✅ |
| AC-SORT-002 | `test/features/library/data/library_repository_test.dart` | ✅ |
| AC-SORT-003 | `test/features/settings/settings_repository_test.dart` | ✅ |
| AC-SORT-004 | `test/features/library/presentation/library_widgets_test.dart` | ✅ |

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-25 | Initial spec (Sprint 4) | Sprint 4 «Endurecer biblioteca» |
