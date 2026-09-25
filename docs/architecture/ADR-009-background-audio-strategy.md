# ADR-009: Estrategia de reproducción en segundo plano

## Estado
Accepted (estrategia) / Pendiente de implementación

## Contexto
Sprint 3 (ROADMAP, Fase 2) exige reproducción en segundo plano con controles
del sistema (notificación y pantalla de bloqueo), hoy inexistentes. El motor
actual es `media_kit` (`media_kit_libs_audio`) detrás de la abstracción
`AudioEngine`, y toda la sesión se coordina en `PlaybackController`
(Riverpod).

Alternativas consideradas:

1. **`audio_service` (ryanheise)** — envuelve el cliente y el motor en un
   foreground service con MediaSession, notificación y lock screen listos,
   con API Dart multiplataforma.
2. **Integración nativa mínima** — foreground service Android propio +
   `MediaSessionCompat` vía MethodChannel, sin dependencias nuevas.
3. **Solo plugin de notificación** (p. ej. `flutter_local_notifications`) —
   no proporciona MediaSession ni survives-to-background real.

## Decisión
Adoptar **`audio_service`** como infraestructura de segundo plano, envuelto
detrás de los contratos existentes:

- `AudioEngine` sigue siendo el único contrato del dominio; `audio_service`
  vive en la capa `data`/infraestructura como adaptador.
- Los comandos de la notificación y lock screen llegan al
  `PlaybackController` por los mismos métodos que usa la UI (DR-002 de la
  SPEC background_audio).
- La dependencia se gestiona en `pubspec.yaml` del `frontend` y se inicializa
  en el bootstrap (`main.dart`), sin filtrar a dominio ni presentación.

Justificación frente a la alternativa nativa: `audio_service` resuelve
MediaSession, notificación adaptativa por versión de Android y reincidencia
del servicio; reimplementarlo nativamente duplica mantenimiento permanente
por un ahorro de dependencia marginal. Coincide además con la filosofía del
proyecto: contratos claros, implementaciones sustituibles.

## Consecuencias

### Positivas
- Foreground service, notificación y lock screen con esfuerzo acotado.
- Camino natural a iOS/macOS si se declara soporte más adelante.
- El dominio no cambia: sigue dependiendo de `AudioEngine`.

### Negativas / riesgos
- Nueva dependencia con ciclo de vida propio (mitigado: abstracción propia
  por encima).
- El callback handler de `audio_service` exige reestructurar el arranque
  (el motor debe existir dentro del servicio), lo que toca `main.dart` y el
  bootstrap de Riverpod; se planifica como tarea propia del Sprint 3 (S3-4).
- Posible duplicidad con `audio_session` (SPEC playback_interruptions): la
  gestión de foco se integrará en el mismo adaptador para no competir.

## Cumplimiento de la plantilla del proyecto
- Problema: sin segundo plano no hay reproductor móvil diario (P0).
- Capacidad nueva en dominio: ninguna (infraestructura); el contrato
  `AudioEngine` basta.
- Por qué la abstracción actual no basta: `AudioEngine` cubre control, no
  ciclo de vida de proceso ni integración con el sistema.
- Parte extensible: el adaptador de sistema; el resto permanece estable.
- Complejidad permanente: una dependencia y un adaptador de sistema con
  pruebas de integración propias.

## Referencias
- SPEC background_audio (`docs/specs/playback/background_audio.md`)
- SPEC playback_interruptions (`docs/specs/playback/playback_interruptions.md`)
- ADR-002 (media_kit como motor), ADR-003 (abstracción AudioEngine)
