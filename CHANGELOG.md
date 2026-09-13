# Changelog
 
Todos los cambios notables en este proyecto serán documentados en este archivo.
 
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).
 
---
 
## [Unreleased]
 
### Added
- Persistencia local implementada con Drift/SQLite para la gestión de pistas musicales.
- Servicio de escaneo de directorios locales con extracción de metadatos mediante `audio_metadata_reader`.
- Repositorio de biblioteca (`LibraryRepository`) para el acceso desacoplado a los datos de pistas.
- Gestión de estado de la biblioteca y el proceso de escaneo mediante Riverpod Notifiers.
- Pantalla de Biblioteca (`LibraryPage`) para la gestión y selección de canciones locales.
- Suite de pruebas unitarias para la validación del repositorio de la biblioteca.
- Implementación de soporte de letras sincronizadas (LRC):
  - Parser de archivos LRC con soporte de timestamps.
  - Repositorio de letras con búsqueda automática por convención de nombre.
  - Sincronizador de letras reactivo basado en la posición del audio.
  - Widget de visualización de letras con resaltado de línea activa.
- Especificación formal de versionado semántico y política de tags Git en [`docs/VERSIONING.md`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/docs/VERSIONING.md).
- Documentación de arquitectura fundacional y gobernanza:
  - Contrato de agentes y directrices técnicas en [`AGENTS.md`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/AGENTS.md).
  - Propuesta del proyecto y alcance MVP en [`docs/PROJECT_PROPOSAL.md`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/docs/PROJECT_PROPOSAL.md).
  - Pautas tecnológicas e investigación del stack en [`docs/STACK.md`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/docs/STACK.md).
  - Diseño guiado por el dominio pragmático en [`docs/DDD.md`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/docs/DDD.md).
  - Metodología de desarrollo guiado por especificaciones en [`docs/SDD.md`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/docs/SDD.md).
- Registros de Decisiones de Arquitectura (ADRs):
  - `ADR-001`: Uso de Flutter como framework multiplataforma.
  - `ADR-002`: Selección de `media_kit` como motor de audio.
  - `ADR-003`: Desacoplamiento mediante abstracción de dominio `AudioEngine`.
  - `ADR-004`: Uso de Riverpod para inyección de dependencias y estado reactivo.
  - `ADR-005`: Uso de Drift/SQLite para persistencia local.
  - `ADR-006`: Navegación centralizada con `go_router`.
  - `ADR-007`: Metodología SDD y DDD para gobernanza técnica.
- Requisitos funcionales y no funcionales en `docs/requirements/` para Library, Playback, Lyrics y Personalization.
- Especificaciones de comportamiento (SPECs) en `docs/specs/`:
  - `library/scan-library.md` y `library/search-library.md`.
  - `playback/play-track.md`, `playback/queue.md`, `playback/repeat.md` y `playback/shuffle.md`.
  - `lyrics/read-lrc.md`.
  - `personalization/basic-theme.md`.
- Inicialización del proyecto base Flutter en `frontend/` para plataformas móviles y desktop.
- Scaffolding de arquitectura modular en `frontend/lib/` (`app/`, `core/`, `features/playback/`, `features/library/`, `features/lyrics/`, `features/settings/`).
- Abstracción de dominio puro [`AudioEngine`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/playback/domain/services/audio_engine.dart).
- Entidades y modelos de dominio: [`TrackRef`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/playback/domain/entities/track_ref.dart), [`PlaybackState`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/playback/domain/entities/playback_state.dart), [`Track`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/library/domain/entities/track.dart), [`Lyrics`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/lyrics/domain/entities/lyrics.dart) y [`AppSettings`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/settings/domain/entities/app_settings.dart).
- Implementación de infraestructura [`MediaKitAudioEngine`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/playback/data/services/media_kit_audio_engine.dart) desacoplada de la UI.
- Implementación de [`FakeAudioEngine`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/test/fakes/fake_audio_engine.dart) y suite de pruebas unitarias para el contrato de reproducción.
- Configuración estricta de análisis estático con `very_good_analysis` en [`analysis_options.yaml`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/analysis_options.yaml).
- Implementación de [`PlaybackController`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/playback/application/playback_controller.dart) y `playbackControllerProvider` para coordinar las operaciones de reproducción (`playTrack`, `togglePlayPause`, `seek`, `stop`, `pickAndPlay`).
- Implementación del servicio de selección local de audio [`LocalAudioPicker`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/playback/application/file_picker_service.dart) con `FilePicker`.
- Creación del componente visual [`PlayerWidget`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/playback/presentation/widgets/player_widget.dart) para visualización de pista, progreso interactivo y botones de control.
- Integración de `PlayerWidget` en la pantalla principal [`HomePage`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/frontend/lib/features/playback/presentation/pages/home_page.dart).
- Implementación de suite de pruebas unitarias para `PlaybackController` y pruebas de widget para `PlayerWidget`.
- Cumplimiento y verificación formal de todos los criterios de aceptación en [`docs/specs/playback/play-track.md`](file:///C:/Users/ACER/Documents/Proyectos_ISCO\GitHub\otune/docs/specs/playback/play-track.md).
 
### Changed
- Renombrado del paquete Dart en `pubspec.yaml` a `otune` c
- on versión `0.1.0-alpha.0+1`.
 
---
 
## [0.1.0-alpha.0] - 2026-09-10
 
### Added
- Creación del repositorio inicial del proyecto Otune.

