# AGENTS.md — Otune

## Propósito

Otune es una aplicación de reproducción musical multiplataforma, offline-first y extensible. La primera versión debe ser deliberadamente simple: biblioteca local, reproducción y letras sincronizadas. Las capacidades avanzadas (karaoke, DJ, visualizadores, layouts configurables, widgets y extensiones) deben poder crecer sin obligar a reescribir el dominio.

## Objetivo de los agentes

Los agentes deben producir código mantenible y pequeño, priorizando funcionalidad real sobre infraestructura especulativa.

Regla principal:

> No implementar una extensión futura hasta que exista un caso de uso actual que la justifique.

## Stack objetivo

- Flutter 3.47.x / Dart 3.12.x como base de desarrollo.
- `media_kit` como motor de reproducción inicial.
- Riverpod 3 para estado e inyección de dependencias.
- Drift/SQLite para persistencia local.
- `go_router` para navegación.
- Material 3 como base visual.
- `dynamic_color` y/o `flex_color_scheme` para theming avanzado.
- `freezed` + `json_serializable` + `build_runner` solo donde la generación de código reduzca boilerplate real.
- `mocktail` para pruebas de unidades que necesiten dobles.
- `very_good_analysis` como base de linting.
- `logger` para logging centralizado.
- `path_provider` para rutas persistentes del sistema.
- `file_picker` para importación/exportación de archivos en plataformas con filesystem accesible.
- `permission_handler` solamente donde una plataforma requiera permisos explícitos.
- `media_store_plus` solo en la capa Android donde sea necesario trabajar con MediaStore.

## Arquitectura

La arquitectura debe seguir separación por dominio/feature, no por tipo global de archivo.

Preferencia:

```text
lib/
  app/
  core/
  features/
    library/
      domain/
      application/
      data/
      presentation/
    playback/
      domain/
      application/
      data/
      presentation/
    lyrics/
      domain/
      application/
      data/
      presentation/
    settings/
      domain/
      application/
      data/
      presentation/
```

No crear un `utils/` genérico como cajón de sastre.

## Reglas de dominio

1. El dominio no debe importar Flutter.
2. El dominio no debe conocer `media_kit`, Drift, Riverpod ni APIs de plataforma.
3. Las interfaces deben vivir en el dominio o en la aplicación cuando representan una capacidad requerida por el caso de uso.
4. Las implementaciones concretas viven en `data` o infraestructura.
5. La UI consume estados/casos de uso; no contiene reglas de negocio.
6. No crear entidades para cada DTO de infraestructura.
7. No introducir un repositorio si el acceso no necesita una abstracción útil.
8. Evitar agregados artificiales solo para "cumplir DDD".

## Media Engine

La aplicación debe depender de una abstracción propia:

```dart
abstract interface class AudioEngine {
  Future<void> load(TrackRef track);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();

  Stream<PlaybackState> get state;
}
```

`media_kit` es una implementación, no el contrato de negocio.

No usar `Player` de `media_kit` directamente desde widgets de pantalla.

## Estado

Usar Riverpod para:

- estado de aplicación;
- casos de uso;
- repositorios;
- sesiones de reproducción;
- configuración;
- streams derivados.

No introducir Bloc, Provider o GetX junto a Riverpod salvo una razón documentada.

Preferir providers pequeños y composición sobre un `AppState` gigante.

## Persistencia

Drift es la persistencia local de referencia.

Reglas:

- las tablas representan necesidades de la aplicación;
- los modelos de dominio no deben ser las filas de Drift;
- migraciones desde la primera versión;
- índices solo para consultas reales;
- evitar guardar datos derivables si no existe una razón de rendimiento/caché;
- cualquier operación que pueda afectar múltiples filas debe usar transacción.

## Letras

El MVP soportará:

1. LRC por línea.
2. lectura de letras disponibles localmente.
3. asociación de una letra con una pista.

La representación de dominio debe permitir evolucionar hacia:

- timestamp por palabra;
- lyrics embebidas;
- múltiples fuentes;
- letras editables;
- karaoke.

Pero el MVP no debe implementar esas extensiones antes de necesitarlas.

## Widgets y personalización

No construir un sistema de plugins de UI dinámicos en la primera versión.

Desde el inicio, los componentes deben tener límites claros:

```text
PlayerWidget
LyricsWidget
QueueWidget
AlbumWidget
WaveformWidget
```

Más adelante se podrá introducir un `Workspace` compuesto por widgets configurables.

La personalización debe separar:

```text
Theme = apariencia
Layout = composición
Widget = capacidad visual
Behavior = comportamiento
```

## Código

- PEP 8 no aplica a Dart; seguir Dart formatter y lint configurado.
- Nombres descriptivos.
- Preferir clases pequeñas y cohesivas.
- Evitar métodos de cientos de líneas.
- `try/catch` solo donde se pueda manejar o traducir el error.
- Errores de infraestructura deben convertirse en tipos de fallo útiles para el dominio/aplicación.
- No ocultar excepciones con `catch (_) {}` sin razón.
- Documentar decisiones no obvias.

## Testing

Cada feature nueva debe intentar incluir:

- pruebas unitarias del dominio/casos de uso;
- pruebas de repositorio cuando haya lógica no trivial;
- widget tests para comportamientos importantes;
- tests de integración solo para flujos críticos entre plataforma y aplicación.

No usar mocks cuando un fake simple sea más claro.

## Agentes y cambios

Antes de modificar una parte sensible:

1. leer `AGENTS.md`;
2. localizar el feature afectado;
3. identificar el caso de uso;
4. revisar interfaces existentes;
5. implementar el mínimo cambio necesario;
6. ejecutar formatter, analyzer y tests relevantes;
7. revisar que no se haya acoplado infraestructura al dominio.

## Comandos esperados

```bash
flutter pub get

dart format .

flutter analyze

flutter test
```

Cuando haya generación:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Regla para features futuras

Antes de crear karaoke, DJ, visualizador, widgets configurables o plugins, exigir un mini-ADR que responda:

- qué problema resuelve;
- qué nueva capacidad introduce en el dominio;
- por qué la abstracción actual no basta;
- qué parte debe ser extensible;
- qué complejidad permanente introduce.

## No-goals iniciales

No implementar todavía:

- cuentas;
- nube;
- sincronización entre dispositivos;
- servidor multimedia;
- plugins de código descargables;
- streaming externo;
- sistema DJ completo;
- editor de audio avanzado;
- microservicios.

## Filosofía

El agente debe optimizar por:

`valor real > simplicidad > extensibilidad necesaria > abstracciones elegantes > infraestructura futura`

La extensibilidad se consigue mediante límites y contratos claros, no mediante construir desde el primer commit un sistema de plugins.

## Spec-Driven Development

Otune utiliza SDD para que los agentes trabajen sobre contratos verificables en lugar de instrucciones ambiguas.

Antes de implementar una feature no trivial:

1. leer `docs/SDD.md`;
2. localizar o crear la SPEC correspondiente;
3. revisar ADR y DDD relacionados;
4. comprobar criterios de aceptación y casos límite;
5. hacer un plan mínimo;
6. implementar;
7. ejecutar pruebas y verificaciones;
8. reportar cualquier desviación de la SPEC.

Reglas:

- una SPEC aprobada define el comportamiento, no la tecnología;
- el agente no debe alterar silenciosamente una SPEC para acomodar una implementación;
- las decisiones nuevas que cambien arquitectura requieren ADR;
- las reglas de dominio deben reflejarse en DDD/use cases, no esconderse en widgets;
- las pruebas deben poder relacionarse con criterios de aceptación;
- las futuras features pueden documentarse como `Draft`/`Proposed` sin implementarse.

### Artefactos mínimos

```text
docs/
├── SDD.md
├── DDD.md
├── architecture/
│   └── ADR-*.md
└── specs/
    ├── library/
    ├── playback/
    ├── lyrics/
    └── personalization/
```

### Prompt operativo para agentes

Cuando una tarea corresponda a una feature no trivial, el agente debe trabajar con esta secuencia:

```text
SPEC → Review → Plan → Code → Test → Verify → Document
```

No comenzar por crear archivos o clases sin localizar primero el comportamiento que debe cumplirse.
