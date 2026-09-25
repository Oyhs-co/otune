# ADR-010: Extracción de las operaciones de mantenimiento de `AppDatabase`

## Estado
Accepted

## Contexto
La revisión de código del 2026-09-25 (hallazgo F-05) detectó que
`core/database/app_database.dart` acumulaba tres responsabilidades en un
mismo archivo:

1. propiedad de la conexión y definición del esquema (tablas `Tracks` y
   `PlaybackSnapshots`, migraciones v2→v4);
2. consultas de lista y ordenación SQL (SPEC library-sorting);
3. operaciones de mantenimiento de datos: resolución puntual de artwork
   (FR-AW-002 de artwork-management) y ciclo de vida de huérfanos
   (detección, borrado y restauración transaccional, FR-SCANR-005/006 de
   scan-robustness).

Estas responsabilidades evolucionan por motivos distintos: la ordenación y
el esquema cambian con las SPECs de biblioteca, mientras que la limpieza de
huérfanos y el artwork puntual pertenecen a la robustez del escaneo. Tener
ambas en el mismo archivo obligó a agrupar tres temas en un único commit de
capa de datos y aumenta el riesgo de conflictos: cualquier cambio en la
ordenación toca un archivo que también contiene la lógica de limpieza.

Alternativas consideradas:

1. **Wrapper independiente** (`DriftLibraryMaintenance` con su propia
   conexión): duplicaría el ciclo de vida de la base de datos y obligaría a
   coordinar transacciones entre dos objetos, rompiendo la garantía
   transaccional de la limpieza (DR-004 de scan-robustness).
2. **Extensión Dart sobre `AppDatabase` en archivo propio**: separa el
   código sin separar el objeto; `AppDatabase` sigue siendo el único dueño
   de la conexión, del esquema y de las transacciones.
3. **Repositorio separado de mantenimiento**: crearía una segunda
   abstracción para operaciones que `LibraryRepository` ya expone,
   duplicando el contrato sin un caso de uso propio.

## Decisión
Extraer las operaciones de mantenimiento a la extensión
`TracksMaintenance on AppDatabase`, en `core/database/tracks_maintenance.dart`,
declarada como `part of 'app_database.dart'`:

- `getTrackArtwork(id)` (FR-AW-002);
- `findMissingTracks({candidateIds})` (FR-SCANR-005);
- `deleteTracks(ids)` en transacción (DR-004);
- `restoreTracks(tracks)` en transacción (deshacer de FR-SCANR-006).

`AppDatabase` conserva la propiedad de la conexión, la definición del
esquema, las migraciones, las consultas de lista y la ordenación SQL. La
API pública no cambia: `DriftLibraryRepository` sigue invocando las
operaciones sobre la instancia de `AppDatabase`, por lo que el contrato de
`LibraryRepository` y todos sus consumidores permanecen intactos.

## Consecuencias

### Positivas
- Un cambio de ordenación ya no toca el archivo que contiene la limpieza de
  huérfanos (motivación original del hallazgo F-05).
- Las garantías transaccionales se mantienen: la extensión opera sobre la
  misma conexión y `transaction()` de la misma instancia.
- Ningún cambio de firma ni de proveedores: sin migración para consumidores
  ni para pruebas existentes.

### Negativas / límites
- Al ser una extensión `part of`, el archivo sigue compilándose junto al
  principal; la separación es de lectura y evolución, no de compilación.
- Si en el futuro el mantenimiento necesitara su propia conexión o su propio
  esquema, habrá que sustituir la extensión por un wrapper; ese cambio sí
  requeriría revisar la frontera transaccional.

## Cumplimiento de la plantilla del proyecto
- Problema: archivo con tres responsabilidades que evolucionan por motivos
  distintos (revisión 2026-09-25, F-05).
- Capacidad nueva en dominio: ninguna; es una reorganización de la capa de
  datos sin cambios de contrato.
- Por qué la abstracción actual no basta: no bastaba con «mover métodos»:
  había que decidir quién es dueño de la conexión y de las transacciones de
  limpieza; la extensión responde a esa pregunta sin duplicar el objeto.
- Parte extensible: el archivo `tracks_maintenance.dart`; nuevas operaciones
  de mantenimiento (p. ej. vacuum, limpieza de artwork huérfano) deben vivir
  ahí y no en `app_database.dart`.
- Complejidad permanente: una convención de colocación que mantener.

## Referencias
- Review `docs/reviews/2026-09-25-sprint-3-4-code-review.md` (hallazgo F-05)
- SPEC artwork-management (`docs/specs/library/artwork-management.md`)
- SPEC scan-robustness (`docs/specs/library/scan-robustness.md`)
- ADR-005 (Drift/SQLite como persistencia)
