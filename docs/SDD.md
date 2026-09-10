# SDD.md — Spec-Driven Development para Otune

## 1. Propósito

Otune utilizará **Spec-Driven Development (SDD)** como mecanismo de trabajo para humanos y agentes de IA.

La especificación será el contrato previo a la implementación: define qué comportamiento se espera, qué queda fuera, cuáles son los criterios verificables y cómo se comprobará que la implementación cumple lo solicitado.

SDD no reemplaza DDD ni las decisiones arquitectónicas:

```text
DDD              → ¿Dónde pertenece el comportamiento?
Architecture     → ¿Cómo se organiza el sistema?
SDD              → ¿Qué debe hacer exactamente?
Tests            → ¿Cómo demostramos que funciona?
Code             → Implementación concreta
```

## 2. Principio central

> No pedirle a un agente que "implemente una feature". Pedirle que implemente una especificación verificable.

Una tarea bien formada debe poder responder antes de programar:

```text
Contexto
Problema
Objetivo
Alcance
No alcance
Comportamiento esperado
Reglas
Casos límite
Criterios de aceptación
Pruebas requeridas
Dependencias
```

## 3. Fuente de verdad

Para cada feature, la fuente de verdad sigue esta prioridad:

```text
ADR / decisión arquitectónica
        ↓
Feature specification
        ↓
Domain model / use cases
        ↓
Implementation
        ↓
Tests
```

Los tests verifican la especificación; no deben convertirse por sí solos en la única documentación del comportamiento.

Cuando exista contradicción entre código y especificación, el agente debe **detenerse y señalar la contradicción** en lugar de elegir silenciosamente una interpretación.

## 4. Estructura documental

Se recomienda:

```text
docs/
├── architecture/
│   ├── ADR-001-....md
│   └── ...
├── specs/
│   ├── library/
│   ├── playback/
│   ├── lyrics/
│   ├── personalization/
│   └── future/
├── decisions/
├── testing/
└── templates/
    ├── SPEC.md
    └── ADR.md
```

Para features grandes puede usarse un directorio propio:

```text
docs/specs/playback/queue-management/
├── SPEC.md
├── scenarios.md
└── decisions.md
```

No crear documentación duplicada en varios lugares.

## 5. Ciclo SDD

Toda feature importante sigue este ciclo:

```text
1. Define
   ↓
2. Specify
   ↓
3. Review
   ↓
4. Plan
   ↓
5. Implement
   ↓
6. Verify
   ↓
7. Record
```

### 5.1 Define

Describir el problema real y por qué existe.

Ejemplo:

> El usuario necesita iniciar una pista desde la biblioteca sin abrir una vista intermedia.

No comenzar describiendo clases o widgets.

### 5.2 Specify

Crear `SPEC.md` con comportamiento observable.

Debe ser independiente de la implementación en la medida de lo posible.

### 5.3 Review

Antes de programar, revisar:

- alcance;
- contradicciones;
- casos límite;
- impacto sobre otros contextos;
- viabilidad multiplataforma;
- dependencia de APIs externas;
- criterios de aceptación.

### 5.4 Plan

El agente convierte la especificación en tareas pequeñas.

Preferir:

```text
SPEC
 ↓
Use case
 ↓
Port
 ↓
Adapter
 ↓
UI
 ↓
Tests
```

No permitir que el plan derive inmediatamente en una refactorización general del proyecto.

### 5.5 Implement

Implementar únicamente lo necesario para satisfacer la especificación aprobada.

### 5.6 Verify

Verificar cada criterio de aceptación con tests o comprobaciones reproducibles.

### 5.7 Record

Actualizar documentación solo cuando la realidad del sistema haya cambiado:

- SPEC si cambió el comportamiento;
- ADR si cambió una decisión arquitectónica;
- DDD si cambió el modelo o bounded context;
- AGENTS.md si cambió una regla de trabajo;
- README si cambió el uso público del proyecto.

## 6. Plantilla de SPEC

```markdown
# SPEC: <nombre de feature>

## Status
Draft | Proposed | Accepted | Implemented | Deprecated

## Context
¿Qué problema resuelve?

## Goal
¿Qué resultado observable se quiere obtener?

## Scope
¿Qué incluye?

## Non-goals
¿Qué no incluye?

## User stories
- Como <usuario>, quiero <acción> para <beneficio>.

## Domain rules
- Regla 1.
- Regla 2.

## Functional requirements
- FR-001: ...
- FR-002: ...

## Non-functional requirements
- NFR-001: ...

## Scenarios
### Scenario: <nombre>
Given ...
When ...
Then ...

## Edge cases
- ...

## Acceptance criteria
- [ ] AC-001: ...
- [ ] AC-002: ...

## Testing strategy
- Unit:
- Widget:
- Integration:

## Dependencies
- ...

## Related architecture decisions
- ADR-...

## Open questions
- ...
```

## 7. Requisitos funcionales y escenarios

Para agentes de IA es preferible combinar requisitos identificables con escenarios concretos.

Ejemplo:

```text
FR-PLAYBACK-001
El usuario puede pausar la pista actual.
```

Y:

```gherkin
Scenario: Pausar reproducción
Given una pista cargada y reproduciéndose
When el usuario pulsa pause
Then el estado de reproducción pasa a paused
And la posición actual se conserva
```

Los escenarios deben describir resultados observables, no clases internas.

## 8. Criterios de aceptación

Un criterio debe ser:

- específico;
- observable;
- verificable;
- independiente cuando sea posible;
- pequeño enough para una prueba.

Evitar:

```text
"La UI debe ser buena"
"Debe funcionar correctamente"
```

Preferir:

```text
AC-PLAYBACK-003:
Al pausar una pista, una llamada posterior a play reanuda desde una
posición equivalente a la última posición conocida por el engine.
```

## 9. Matriz de trazabilidad

Para features importantes:

| ID | Spec | Use Case | Código | Test | Estado |
|---|---|---|---|---|---|
| FR-001 | playback/basic | PlayTrack | playback/application/... | play_track_test.dart | ✅ |
| FR-002 | playback/basic | PausePlayback | playback/application/... | pause_test.dart | ✅ |

La trazabilidad puede mantenerse en la misma SPEC para features pequeñas. No crear una base de datos de trazabilidad para features triviales.

## 10. SDD y DDD

La especificación define comportamiento; DDD define el lugar conceptual donde ese comportamiento vive.

Ejemplo:

```text
SPEC: "Añadir una pista a la cola"
            │
            ▼
Playback bounded context
            │
            ▼
Queue aggregate
            │
            ▼
AddToQueue use case
            │
            ▼
AudioEngine / repository
```

Si una SPEC propone modificar directamente un `Widget` para resolver una regla del dominio, el agente debe cuestionarla.

## 11. SDD y agentes de IA

Un agente debe comenzar por:

```text
1. Leer AGENTS.md
2. Leer SDD.md
3. Leer DDD.md si toca dominio
4. Buscar SPEC relacionada
5. Leer ADR relacionados
6. Inspeccionar código existente
7. Proponer plan mínimo
8. Implementar
9. Ejecutar verificación
10. Reportar trazabilidad y desviaciones
```

### 11.1 Regla de contexto

No cargar todo el repositorio en el contexto del agente sin necesidad.

El contexto mínimo recomendado es:

```text
AGENTS.md
+ SPEC objetivo
+ DDD relevante
+ ADR relevantes
+ archivos directamente relacionados
```

Esto reduce ruido y disminuye la probabilidad de cambios accidentales.

### 11.2 Regla de no-invención

Si la SPEC no define algo importante, el agente debe marcarlo como pregunta abierta o usar una decisión explícitamente justificada.

No inventar:

- comportamiento de UX;
- contratos de API;
- formatos de persistencia;
- permisos de plataforma;
- dependencias;
- requisitos de seguridad.

## 12. Estados de una SPEC

```text
Draft
  ↓
Proposed
  ↓
Accepted
  ↓
In Progress
  ↓
Implemented
  ↓
Verified
  ↓
Deprecated (si aplica)
```

Una SPEC `Draft` no debe tratarse como contrato estable.

Una SPEC `Accepted` es implementable.

Una SPEC `Verified` tiene evidencia de que sus criterios principales están cubiertos.

## 13. Cambios durante la implementación

Si el agente descubre que la especificación no es viable:

```text
Implementation problem
        ↓
Pause implementation
        ↓
Explain discrepancy
        ↓
Propose SPEC change / ADR
        ↓
Update accepted contract
        ↓
Continue
```

No reescribir silenciosamente la especificación para que el código parezca correcto.

## 14. Feature slices

Preferir especificaciones verticales que puedan producir funcionalidad ejecutable.

Ejemplo:

```text
SPEC-001: Reproducir una pista
SPEC-002: Cola básica
SPEC-003: Letras LRC
SPEC-004: Búsqueda
```

Evitar una única SPEC gigantesca llamada `MusicPlayer.md`.

## 15. Manejo de futuras features

Las features futuras pueden tener una SPEC en estado `Draft` o `Proposed` sin obligar a implementarlas.

Ejemplo:

```text
docs/specs/future/
├── karaoke.md       # Proposed
├── dj-mode.md       # Draft
└── widget-system.md # Draft
```

Estas especificaciones sirven para registrar intención, no para crear deuda de implementación.

## 16. Definition of Ready

Una SPEC está lista para implementación cuando:

- el problema está claro;
- el alcance está delimitado;
- no-goals están explícitos;
- los casos principales están definidos;
- casos límite relevantes están identificados;
- existen criterios de aceptación;
- las dependencias conocidas están identificadas;
- no existen contradicciones conocidas con ADR/DDD.

## 17. Definition of Done

Una feature está terminada cuando:

- cumple los criterios de aceptación;
- las pruebas relevantes pasan;
- formatter y analyzer pasan;
- no viola límites DDD;
- no introduce acoplamiento innecesario;
- la SPEC refleja el comportamiento real;
- las decisiones arquitectónicas nuevas tienen ADR cuando corresponde.

## 18. Regla de simplicidad

SDD no significa documentar cada getter.

Usar SPEC para comportamiento que tenga valor, riesgo, interacción multiplataforma o posibilidad de evolución.

Para una corrección trivial, issue o task pequeña puede ser suficiente un criterio de aceptación en el issue.

La documentación debe ayudar a construir el producto, no convertirse en el producto.
