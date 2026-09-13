# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [0.4.0-alpha.0] - 2026-09-13

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

### Changed

- Renombrado del paquete Dart en `pubspec.yaml` a `otune`.
- Actualización de la versión base a `0.1.0-alpha.0+1` durante la fase inicial.

---

## [0.1.0-alpha.0] - 2026-09-10

### Added

- Creación del repositorio inicial del proyecto Otune.
