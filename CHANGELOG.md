# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Added

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
