# SPEC: Interrupciones del Sistema y Audio Focus

## Status
Proposed

## Context
El motor reproduce sin negociar el foco de audio con el sistema: una llamada,
una alarma u otro reproductor puede solaparse con Otune, y al desconectar los
auriculares el audio continúa por el altavoz. Estos comportamientos hacen la
aplicación inaceptable para uso diario.

## Goal
Otune negocia el foco de audio con el sistema y responde a las interrupciones
de forma predecible: pausar cuando corresponde, reanudar cuando el sistema lo
permite y nunca continuar por el altavoz al desconectar auriculares.

## Scope
- Gestión de audio focus en Android (vía `audio_session`).
- Pausa y reanudación tras interrupciones (llamadas, alarmas, otros players).
- Pausa al desconectar auriculares (wired y Bluetooth).
- Continuidad al bloquear y desbloquear el dispositivo.

## Non-goals
- Reanudación automática tras interrupciones largas (llamadas): decisión
  conservadora, el usuario decide.
- Ducking automático (bajar volumen en lugar de pausar).
- Integración con asistentes de voz o comandos de "quién está reproduciendo".
- Multiplataforma completa en esta iteración: Android primero, el contrato se
  diseña para extender a escritorio.

## User stories
- Como usuario, quiero que la música se pause cuando me llaman, para no
  dejar de escuchar la llamada.
- Como usuario, quiero que la música se pause al desconectar los auriculares,
  para no reproducir audio inesperado por el altavoz.

## Domain rules
- DR-001: el foco de audio se adquiere antes de iniciar la reproducción y se
  libera al detener.
- DR-002: ante una interrupción transitoria (alarma, navegación), la
  reproducción se pausa y se reanuda automáticamente cuando el sistema
  devuelve el foco.
- DR-003: ante una interrupción no transitoria (llamada), la reproducción se
  pausa y NO se reanuda automáticamente.
- DR-004: al desconectar auriculares, la reproducción se pausa siempre.
- DR-005: la respuesta a interrupciones pasa por el `PlaybackController`; no
  se manipula el motor directamente desde la infraestructura.

## Functional requirements
- FR-INT-001: al recibir una pérdida de foco transitoria, Otune pausa en
  menos de 500 ms.
- FR-INT-002: al recuperar el foco tras una interrupción transitoria, la
  reproducción se reanuda en la posición en que se pausó.
- FR-INT-003: la desconexión de auriculares pausa la reproducción en menos
  de 500 ms.
- FR-INT-004: bloquear y desbloquear el dispositivo durante la reproducción
  no altera el estado ni la posición.

## Scenarios

### Scenario: Llamada entrante durante la reproducción
Given una pista en reproducción
When el sistema emite una pérdida de foco no transitoria
Then la reproducción se pausa
And no se reanuda automáticamente al finalizar la llamada

### Scenario: Alarma durante la reproducción
Given una pista en reproducción
When el sistema emite una pérdida de foco transitoria
Then la reproducción se pausa
And se reanuda automáticamente cuando el foco regresa

### Scenario: Desconectar auriculares Bluetooth
Given una pista en reproducción por auriculares Bluetooth
When el usuario desconecta los auriculares
Then la reproducción se pausa inmediatamente
And el audio no continúa por el altavoz

### Scenario: Bloqueo y desbloqueo
Given una pista en reproducción
When el usuario bloquea y desbloquea el dispositivo sin interrupciones
Then la reproducción continúa en la misma posición

## Edge cases
- Interrupción durante una transición automática de pista: la reanudación
  aplica a la pista nueva.
- Permisos de Bluetooth denegados para detectar desconexión: se documenta la
  limitación; la pausa por foco sigue funcionando.
- Interrupción con la app en segundo plano: misma política (complementa a la
  SPEC background_audio).

## Acceptance criteria
- [ ] AC-001: llamada entrante pausa la reproducción sin reanudación
  automática.
- [ ] AC-002: alarma transitoria pausa y reanuda en la posición original.
- [ ] AC-003: desconectar auriculares pausa en menos de 500 ms.
- [ ] AC-004: lock/unlock no altera estado ni posición.

## Testing strategy
### Unit
- Mapeo de eventos de `audio_session` a comandos del controller (fake de
  eventos de foco).

### Integration (dispositivo)
- Llamada simulada, alarma, desconexión de auriculares en dispositivo físico.

## Dependencies
- Nueva dependencia `audio_session` (a evaluar junto con la decisión de
  ADR-009 para no duplicar gestión de MediaSession).
- SPEC background_audio (el comportamiento en segundo plano complementa este).

## Related DDD
- Bounded context: `playback`
- Use case: respuesta a interrupciones del sistema

## Related ADRs
- ADR-009 (estrategia background audio y sesión de audio)

## Open questions
- ¿Integrar la gestión de foco dentro del adaptador de `audio_service` o como
  capa independiente con `audio_session`? A resolver al aprobar el ADR-009.

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-23 | Initial spec | Sprint 3 S3-5 |
