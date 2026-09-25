# SPEC: Background Audio y Controles del Sistema

## Status
Proposed

## Context
Hoy la reproducción vive dentro del proceso de la UI: al enviar la app a
segundo plano, Android puede congelar el proceso y cortar el audio; no existe
notificación multimedia ni controles en pantalla de bloqueo. Para un
reproductor móvil esto es bloqueante (P0 en el ROADMAP): el producto no sirve
como reproductor diario sin reproducción en segundo plano.

## Goal
La sesión de escucha continúa con la app en segundo plano y el usuario puede
controlarla desde la notificación del sistema y la pantalla de bloqueo.

## Scope
- Foreground service de reproducción en Android.
- Notificación multimedia con play/pausa, siguiente, anterior y seek.
- Controles en pantalla de bloqueo vía MediaSession.
- Supervivencia al back button y al cambiador de aplicaciones.

## Non-goals
- Soporte iOS/macOS en esta iteración (se declarará soporte tras validar).
- Widgets de escritorio o integración con asistentes de voz.
- Visualización de artwork en notificación con descarga remota (sólo arte
  local embebido).
- Un sistema de plugins o extensibilidad de la notificación.

## User stories
- Como usuario, quiero que la música siga sonando al bloquear el teléfono o
  cambiar de aplicación, para usar Otune como reproductor diario.
- Como usuario, quiero pausar o cambiar de pista desde la notificación, sin
  volver a abrir la app.

## Domain rules
- DR-001: el contrato de negocio sigue siendo `AudioEngine`; el servicio de
  segundo plano es infraestructura y no introduce un segundo motor.
- DR-002: los comandos del sistema (notificación/lock screen) entran por el
  mismo `PlaybackController` que la UI; no hay rutas de control paralelas.
- DR-003: si el sistema mata el servicio, la restauración de sesión existente
  (SPEC session-persistence) permite recuperar la sesión sin autoplay.

## Functional requirements
- FR-BG-001: con la app en segundo plano y la pantalla bloqueada, el audio
  continúa sin interrupciones durante una sesión de escucha normal.
- FR-BG-002: la notificación muestra título, artista, artwork si existe, y
  botones de play/pausa, siguiente y anterior; refleja el estado real en
  menos de un segundo tras cada cambio.
- FR-BG-003: los botones de la notificación y de la pantalla de bloqueo
  producen el mismo efecto que los de la UI.
- FR-BG-004: al cerrar la app desde el cambiador, la sesión queda persistida
  para la siguiente apertura (ya cubierto por session-persistence; se
  verifica en este contexto).
- FR-BG-005: el back button no destruye la sesión de reproducción.

## Scenarios

### Scenario: Bloquear el teléfono durante la reproducción
Given una pista en reproducción
When el usuario bloquea la pantalla durante 30 minutos
Then el audio continúa sin interrupciones
And el estado mostrado al desbloquear coincide con el real

### Scenario: Control desde la notificación
Given una pista en reproducción con la app en segundo plano
When el usuario pulsa pausa en la notificación
Then la reproducción se pausa
And la notificación refleja el nuevo estado con el icono de play

### Scenario: App cerrada desde el cambiador
Given una sesión activa con cola y posición
When el usuario cierra la app desde el cambiador
Then la siguiente apertura restaura la sesión en pausa sin autoplay
(comportamiento ya definido en session-persistence)

## Edge cases
- Modo batería optimizada / restricciones de fabricante (Xiaomi, Huawei):
  documentar limitaciones conocidas y guía para excluir la app de ahorro de
  batería.
- Pista con artwork ausente: la notificación usa el placeholder.
- Comandos de notificación durante una transición automática de pista: se
  aplican sobre la pista nueva, sin colas de comandos.

## Acceptance criteria
- [ ] AC-001: el audio continúa 30 minutos con pantalla bloqueada.
- [ ] AC-002: la notificación refleja cada cambio de estado en menos de 1 s.
- [ ] AC-003: los comandos de notificación/lock screen equivalen a los de UI.
- [ ] AC-004: el back button conserva la sesión y no cierra el reproductor.
- [ ] AC-005: al cerrar y reabrir, la sesión se restaura en pausa.

## Testing strategy
### Unit
- Mapeo de comandos de MediaSession a métodos del controller.

### Integration (dispositivo)
- Sesión larga en segundo plano en dispositivo físico Android.
- Verificación de notificación con `adb` / inspección manual documentada.

## Dependencies
- ADR-009: estrategia de servicio en segundo plano (`audio_service` frente a
  integración nativa con `media_kit`).
- SPEC session-persistence (restauración tras muerte del proceso).

## Related DDD
- Bounded context: `playback`
- Use case: comandos de sistema hacia la sesión de reproducción

## Related ADRs
- ADR-009 (estrategia background audio, pendiente de aprobar)

## Open questions
- ¿Exponer seek en la notificación compacta o sólo en la expandida?
- ¿Priorizar `audio_service` (madurez, multiplataforma futura) sobre una
  integración nativa mínima que evite una dependencia nueva? El ADR-009
  inicial recomienda `audio_service`.

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-23 | Initial spec | Sprint 3 S3-4 |
