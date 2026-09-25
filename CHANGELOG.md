# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [0.7.0-alpha.0+25] - 2026-09-25

### Added

- Política de errores de reproducción (Sprint 3 S3-3): nueva entidad de dominio `PlaybackFailure` con taxonomía cerrada (archivo ausente, corrupto, permisos, desconocido), salto automático a la pista siguiente al fallar la carga con límite de 3 fallos consecutivos antes de detener, y `retryCurrentTrack()` para la acción de reintento.
- Superficie de error accionable en `NowPlayingPage` (banner con mensaje clasificado y botón Reintentar, visible también cuando la reproducción queda detenida por fallos) e indicador de error en el `MiniPlayer`.
- Excepción tipada `PlaybackLoadException` en el contrato `AudioEngine`: la carga fallida es determinista para el llamador y el error del stream queda reservado para la UI.
- `PlaybackState.errorMessage` ahora sólo es significativo en estado `error`: un estado posterior sano no reporta errores anteriores.
- SPECs de playback: `audio-engine-lifecycle.md` (Implemented), `playback_error_policy.md` (Implemented), `background_audio.md` (Proposed) y `playback_interruptions.md` (Proposed).
- ADR-009: estrategia de reproducción en segundo plano (se adopta `audio_service` detrás de los contratos existentes; implementación en la siguiente iteración).
- Pruebas de la política de errores (salto automático, límite de fallos, reintento, pista única, fallo aislado), clasificación de `PlaybackFailure`, controles deshabilitados, indicadores de error y contratos de UI S3-1 (mini player entre secciones en móvil/escritorio, sesión única al abrir Now Playing).
- Sprint 4 S4-1 «Escaneo robusto» (SPEC `scan-robustness.md`): cancelación cooperativa del escáner con token (`ScanCancellationToken` + evento terminal `ScanCancelled`), botón Cancelar en el banner de progreso, guard de escaneo simultáneo en `LibraryScanNotifier`, normalización de rutas indexadas y detección/limpieza transaccional de pistas huérfanas con acción de deshacer.
- Sprint 4 S4-2 «Gestión de artwork» (SPEC `artwork-management.md`): las consultas de lista ya no cargan blobs; nueva operación `getTrackArtwork(id)` con caché LRU acotada; widget `LazyArtwork` que resuelve la carátula bajo demanda en lista, detalle y cuadrícula; límite de tamaño de imágenes embebidas en el escaneo (descarte sobre 2 MB); refresco reactivo de la biblioteca al terminar un escaneo o limpiar el catálogo.
- Sprint 4 S4-3 «Ordenación de biblioteca» (SPEC `library-sorting.md`): migración Drift v3 → v4 (columna `added_at`), ordenación SQL por título, artista, álbum y fecha de incorporación (NOCASE, más reciente primero), criterio persistido en `SettingsRepository` y selector de orden en la biblioteca.
- Búsqueda con debounce de 300 ms (NFR-SEARCH-002 de `search-library.md`): la lista consulta la base de datos una vez el usuario deja de escribir; la consulta vacía se aplica de inmediato.
- Pruebas de cancelación, exclusión mutua, normalización, límite de artwork, caché LRU, resolución lazy, ordenación por criterios, persistencia del criterio y limpieza de huérfanos con deshacer (150 pruebas en total).

### Changed

- `PlaybackControls`: play/pausa, siguiente, anterior, shuffle y repetir se deshabilitan sin pista activa; siguiente/anterior respetan `hasNext`/`hasPrevious` (DR-001/FR-AE-002 de la SPEC audio-engine-lifecycle).
- Transición automática con repeat one: reintenta la pista actual con seek a cero sin recargar el archivo ni mover el índice (elimina el hueco audible).
- El contador de fallos de carga se reinicia con cualquier reproducción sana y su último fallo se limpia de la superficie de error.
- Tests existentes de shuffle/repeat de `PlayerWidget` ahora activan una pista antes de tocar los botones, alineados con la nueva regla de controles deshabilitados.
- `LibraryRepository` ampliado con orden por criterio, resolución puntual de artwork y operaciones de huérfanos (detección, borrado y restauración transaccional); el estado de escaneo pasa a exponer `LibraryScanControllerState` (escaneo + limpieza).
- El lector de metadatos del escáner es inyectable (`MediaMetadataReader`), desacoplando el plugin nativo de la lógica de escaneo y permitiendo pruebas unitarias deterministas.
- Actualizada la versión de la aplicación a `0.7.0-alpha.0+25`.

### Fixed

- Restaurado el `BottomNavigationBar` del shell en pantallas estrechas tras la refactorización de acciones de biblioteca del Sprint 4.
- Títulos, artistas y álbumes largos se truncan con ellipsis de forma coherente en las tres vistas de la biblioteca (FR-SORT-006).

## [Unreleased]

## [0.6.1-alpha.0+24] - 2026-09-22

### Added

- Persistencia de la sesión de reproducción (Sprint 2): la cola, el índice activo, los modos (aleatorio/repetición) y la posición de la pista se guardan con debounce y se restauran al arrancar la aplicación sin iniciar audio automáticamente.
- Nueva tabla `playback_snapshots` (migración de esquema v2 → v3) y repositorio `DriftPlaybackSnapshotRepository` para la instantánea de sesión.
- Entidad de dominio `PlaybackSnapshot` con conversión validada hacia `PlaybackQueue` (índice fuera de rango → 0, snapshot vacío → sesión limpia).
- Interfaz de dominio `SettingsRepository` y adaptador `SharedPreferencesSettingsRepository`: el tema y la duración de badges sobreviven al reinicio de la aplicación.
- `SessionRestoreWatcher`: restauración de sesión al arrancar y guardado inmediato del snapshot al pasar a segundo plano (`paused`/`detached`).
- SPEC `docs/specs/playback/session-persistence.md` con criterios de aceptación y pruebas asociadas.
- Pruebas de persistencia de settings, roundtrip del snapshot en Drift en memoria, restauración sin autoplay y layout de `NowPlayingPage` en pantallas estrechas y amplias.
- Pipeline de CD para Windows (`release-windows.yml`): build automático en tags `v*` y manual por entorno, con artefacto `otune-windows-x64.zip` y release en GitHub Releases.

### Changed

- `SettingsNotifier` hidrata las preferencias desde el repositorio en el arranque (`hydrate()`) y persiste cada cambio; los fallos de almacenamiento se registran sin revertir el estado en memoria.
- `PlaybackController` programa el guardado del snapshot en cada mutación de cola y en los cambios de posición/estado del motor.
- Pantalla de reproducción actual (`NowPlayingPage`): layout reorganizado en zona flexible (portada/letras + info de pista) con barra de progreso y controles anclados abajo; el artwork escala según el ancho y alto disponibles evitando overflow en pantallas bajas.
- Actualizada la versión de la aplicación a `0.6.1-alpha.0+24`.

### Fixed

- `NowPlayingPage`: el layout ahora usa `SafeArea` para respetar la barra de estado y navegación de Android, espaciado escalable mediante `DesignTokens.scale` (1.0–1.5 según ancho de pantalla) y artwork más grande en pantallas anchas (token `artworkXLarge`).

## [0.6.0-alpha.0+23] - 2026-09-22

### Added

- Widget `StateBadge`: indicador de estado reutilizable con timeout configurable, auto-dismiss tras duración definida, animación de entrada/salida y soporte para acciones (ej: Deshacer).
- Proveedor `badgeProvider`: servicio global para mostrar badges de estado programáticamente desde cualquier widget.
- Configuración de duración de badges en Ajustes (1, 2, 3, 5, 10 segundos).
- Badges reemplazan SnackBars en toda la app (permisos, cola vaciada, eliminación de elementos con acción de deshacer).
- Proveedor `badgeDefaultDurationProvider`: la duración configurada en Ajustes controla la caducidad real de los badges (contrato settings→badges).
- Enum `BadgeDurationOption` en el dominio de settings con catálogo cerrado de duraciones válidas.
- Pruebas de duración efectiva de badges y de rechazo de valores inválidos.

### Changed

- Actualizada la versión de la aplicación a `0.6.0-alpha.0+23`.
- El título de cada sección vive en el `AppShell` ('Mi Biblioteca', 'Ajustes'); `SettingsPage` y `LibraryPage` ya no montan AppBar propio (elimina el doble AppBar apilado en móvil).
- La caducidad de los badges la programa únicamente `BadgeNotifier`; `StateBadge` ya no mantiene temporizadores propios.
- CI ejecuta análisis y pruebas también en la rama `Improve-UX-UI`.
- Pantalla de reproducción actual (`NowPlayingPage`): objetos distribuidos uniformemente en el espacio disponible usando `MainAxisAlignment.spaceEvenly`. Área de artwork/letras limitada por token `DesignTokens.artworkLarge`.

### Fixed

- Arreglados los tests de navegación y ajustes que esperaban contratos visuales anteriores ('Mi Biblioteca' y título de Ajustes en SettingsPage).
- El feedback de cambio de duración de badges sólo se muestra cuando la preferencia se aplicó realmente.

## [0.5.0-alpha.1+22] - 2026-09-18

### Added

- Cerrada la experiencia local de cola con superficie adaptativa, reordenamiento y acciones reversibles.
- Añadidas especificaciones verificables para cola adaptativa, búsqueda, interacciones de pistas, preferencias y accesibilidad.
- Añadida acción para limpiar la búsqueda y normalizar consultas con espacios.

### Changed

- Actualizada la versión de Flutter a `0.5.0-alpha.1+22`.
- Marcadas como implementadas las SPECS de estados de biblioteca, progreso de escaneo y cola funcional.

### Fixed

- Corregido el flujo de escaneo para continuar ante errores de archivos individuales y reservar el estado crítico para errores de directorio.
- Añadido reintento real para errores de carga de la biblioteca y para el último escaneo fallido.
- Alineada la documentación del shell adaptativo con sus tres destinos persistentes actuales y la ruta independiente de reproducción actual.
- Corregido el layout del shell para reservar espacio al mini-player y evitar solapamientos con el contenido o la navegación inferior.
- Añadidas pruebas de navegación móvil, navegación amplia y continuidad de reproducción al cambiar de sección.
- Convertida Biblioteca en la pantalla principal y eliminada la navegación duplicada desde la antigua pantalla de Inicio.

## [0.5.0-alpha.0+21] - 2026-09-18

### Added

- Añadida una nueva suite de pruebas con `flutter_test` que cubre 73 casos de dominio, aplicación, repositorios, letras, playback, widgets y permisos, incluyendo generación de cobertura mediante `flutter test --coverage`.
- Añadida la shell adaptativa de la aplicación con navegación responsive y estructura visual centralizada.
- Añadido sistema de tokens de diseño para colores, espacios, radios y tipografía de la interfaz.
- Añadido placeholder visual para carátulas ausentes y componente de mini reproductor para la experiencia de escucha compacta.
- Añadido estado vacío de biblioteca con mensaje contextual y botón de escaneo cuando la colección está vacía o no hay resultados de búsqueda.
- Añadido banner visual para mostrar el progreso del escaneo de carpetas y el resultado final del proceso.
- Añadida pantalla de reproducción actual con controles de reproducción, barra de progreso y opciones de aleatorio y repetición.
- Añadida vista de letras integrada en la pantalla de reproducción actual con alternancia entre portada y letras.
- Añadido modo de letras con resaltado de línea activa, auto-scroll y salto por toque de línea para sincronizar la reproducción.
- Añadida hoja de cola de reproducción con vista lista/detallada, reordenado y acciones de vaciado y eliminación.
- Añadido mini-player persistente para acceder rápidamente a la pista activa desde el shell principal.
- Añadidas especificaciones de diseño y UX para navegación adaptativa, estados vacíos de biblioteca y feedback de progreso de escaneo.
- Añadida especificación del flujo de letras integradas para la experiencia de escucha actual.
- Documentado el plan de evolución de UX/UI para la aplicación y la hoja de ruta visual futura.

### Changed

- Desactivada globalmente la regla `unnecessary_type_name_in_constructor` para mantener la convención actual de constructores también en el análisis del pipeline de CI.
- Actualizada la navegación de la app para integrar el shell adaptativo y la estructura de rutas actualizada.
- Reorganizado el diseño de la biblioteca y la capa visual del reproductor para reflejar la nueva experiencia de uso y continuidad del flujo.
- Actualizada la pantalla de biblioteca para integrar el estado vacío, el buscador y la retroalimentación visual del escaneo de música.
- Reorganizado el flujo de biblioteca para que la acción de escaneo y el feedback del estado sean más claros y mantenibles.
- Ajustada la navegación global para incluir la vista de reproducción actual y la persistencia del mini-player dentro del shell.
- Actualizada la pantalla de reproducción para mostrar la vista de letras y mantener el control de progreso con seek interactivo.
- Reorganizado el flujo de sincronización de letras para que el texto siga la pista activa y gestione estados vacíos de forma más clara.
- Mejorado el flujo de escucha para abrir rápidamente la cola y la reproducción detallada desde la vista principal.

### Fixed

- Corregido el tratamiento visual de elementos sin carátula para mantener una apariencia consistente en la biblioteca y el reproductor.
- Corregido el comportamiento visual de la biblioteca para no mostrar un estado vacío ambiguo cuando la colección está vacía o filtrada.
- Corregido el flujo de acceso a la reproducción actual para evitar pantallas de audio incompletas y transiciones poco claras entre la cola y el detalle.
- Corregido el estado sin letras para mostrar una indicación útil cuando la pista no tiene LRC asociado.
- Corregido el desplazamiento de la lista de letras para mantener visible la línea activa durante la reproducción.

## [0.4.0-alpha.2+20] - 2026-09-17

### Added

- Añadida pantalla splash con navegación inicial hacia la pantalla principal.
- Añadidas acciones para reproducir una pista a continuación o añadirla a la
  cola desde las vistas de biblioteca.
- Añadido resaltado visual de la pista que se está reproduciendo.
- Añadido soporte para mostrar el icono de la aplicación y la firma `By
Oyhs-Co` en la información de Otune.

### Changed

- Actualizada la navegación para incluir las rutas de splash, biblioteca,
  ajustes y pantalla principal.
- Ampliado el modelo de referencia de pista para conservar la carátula del
  álbum junto con sus metadatos.
- Persistidas las carátulas de álbum en la biblioteca local mediante una migración del esquema de Drift/SQLite.
- Ampliada la selección de archivos locales para leer título, artista, álbum, duración y carátula desde los metadatos del archivo.
- Añadidos controles de silencio y ajustes de reproducción en el reproductor.
- Actualizados los textos de versión de la aplicación a `0.4.0-alpha.2+20`.

### Fixed

- Corregido el flujo de metadatos de biblioteca a reproducción para conservar título, artista, álbum, duración y carátula del archivo seleccionado.
- Normalizada la generación de URIs locales con `Uri.file()` para evitar rutas inválidas o sin formato `file://` en la reproducción.
- Declarados los flavors Android `staging` y `prod` usados por la pipeline de
  releases.
- Correccion en el release.yml y upgrade de las versionde de node.js y Java.
- Corregido el seek del reproductor para que arrastrar la barra de progreso no deje el audio silenciado al soltarla o cambiar de pista.

## [0.4.0-alpha.1+19] - 2026-09-14

### Added

- Añadida la visualización de biblioteca en lista, cuadrícula y modo detallado.
- Añadidos búsqueda de biblioteca y modos de visualización para biblioteca y
  cola.
- Añadido escaneo recursivo de audio y vídeo con persistencia de metadatos en
  Drift/SQLite.
- Añadidas pruebas de persistencia de pistas y del widget de cola.

### Changed

- Sustituido el lector de metadata por `media_metadata`, con soporte para
  etiquetas de audio y video y texto Unicode.
- Actualizada la UI de la cola para la API vigente de Flutter y tipada con
  entidades del dominio.
- Actualizados los textos de versión de la aplicación a `0.4.0-alpha.1+19`.

### Fixed

- Protegidas las búsquedas de biblioteca frente a comodines de SQLite para
  conservar resultados correctos con títulos que contienen `%`, `_` o `\`.
- Corregido el smoke test de la pantalla principal para reflejar la navegación
  actual de la aplicación.
- Corregidos todos los issues de `flutter analyze` y los fallos de compilación
  de `flutter test`.

### Verification

- `flutter analyze`: sin issues.
- `flutter test`: 39 tests aprobados.

## [0.4.0-alpha.0+18] - 2026-09-13

### Changed

- Reorganizados los widgets de Library y Settings bajo sus respectivas
  carpetas `presentation/widgets`, dejando que las páginas los compongan.
- Desacoplado `PlayerWidget` de `QueueSheet`; ahora `HomePage` compone ambos.
- Añadida la implementación Android de permisos para audio y vídeo.
- Añadido `PermissionService` para solicitar permisos multimedia desde Flutter
  mediante el canal nativo `otune/permissions`.
- Añadidas las rutas y accesos de navegación para Biblioteca y Ajustes desde la
  pantalla principal.
- Configurada la identidad Android de la aplicación con el identificador
  `com.otune.app` y la etiqueta `Otune`.
- Documentado el acceso a archivos `.lrc` mediante la carpeta seleccionada en
  el selector del sistema.
- Actualizada la versión de la aplicación a `0.4.0-alpha.0+18`.

---

## [0.4.0-alpha.0+17] - 2026-09-13

### Added

- **Biblioteca Local**:
  - Implementación de persistencia con Drift/SQLite para gestión de pistas.
  - Servicio de escaneo recursivo de directorios locales.
  - Extracción de metadatos de audio mediante `audio_metadata_reader`.
  - Repositorio desacoplado `LibraryRepository`.
  - Interfaz de usuario `LibraryPage` para gestión y selección de música.
  - Suite de pruebas unitarias para el repositorio de biblioteca.
- **Soporte de Letras (LRC)**:
  - Parser de archivos LRC con soporte de timestamps sincronizados.
  - Repositorio `LocalLyricsRepository` con búsqueda automática por convención de nombres.
  - Sistema de sincronización reactiva basado en la posición del audio.
  - Widget `LyricsWidget` con resaltado dinámico de líneas activas.
- **Configuración y Pulido**:
  - Sistema de preferencias de tema (Claro/Oscuro/Sistema) mediante `SettingsNotifier`.
  - Pantalla de ajustes `SettingsPage`.
  - Refactorización de la arquitectura de estado utilizando Riverpod Notifiers para eliminar lógica de negocio de la UI.
- **Documentación y Gobernanza**:
  - Definición de política de versionado SemVer en `docs/VERSIONING.md`.
  - Guías de arquitectura, DDD, SDD y contrato de agentes en `AGENTS.md` y `docs/`.
  - Definición de SPECs para Library, Playback y Lyrics.
- **Core de Reproducción**:
  - Abstracción `AudioEngine` implementada con `media_kit`.
  - `PlaybackController` para coordinación de reproducción.
  - Componente `PlayerWidget` con controles interactivos.
  - Suite de pruebas unitarias y de widget para el flujo de reproducción.
- **Infraestructura de CI/CD**:
  - Pipeline de calidad continua (`ci.yml`).
  - Pipeline de releases automatizado para Android (`release.yml`) con soporte para entornos Debug, Staging y Prod.
  - Guía de firma y despliegue en `docs/release-android.md`.

### Fixed

- Corregido error de tipo `ColorScheme` entre `dynamic_color` y Flutter al cambiar `AppTheme` para aceptar un color semilla (`Color?`) en lugar de `ColorScheme?`.
- Corregido uso de `AudioMetadataReader` por la función `readMetadata` correcta del paquete `audio_metadata_reader`.
- Corregid uso de `FilePicker.platform` por `FilePicker` estático para la versión 12.x de `file_picker`.
- Corregidos errores de sintaxis y tipado en `PlaybackController` y `LyricsSyncNotifier`.
- Corregidos todos los warnings y lints de `flutter analyze` (75 → 0 issues): orden de imports, nombres de constructores, lambdas innecesarios, variables finales, literales int, longitud de líneas, cláusulas catch con `on`, I/O síncrono, deprecaciones `withOpacity`, imports no usados, y orden de dependencias en `pubspec.yaml`.

### Changed

- Renombrado del paquete Dart en `pubspec.yaml` a `otune`.
- Actualización de la versión base a `0.4.0-alpha.0+17`.

---

## [0.1.0-alpha.0] - 2026-09-10

### Added

- Creación del repositorio inicial del proyecto Otune.
