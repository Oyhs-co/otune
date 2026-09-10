# Otune — Propuesta de proyecto

## 1. Resumen

Otune será un reproductor musical multiplataforma, offline-first y orientado a bibliotecas locales. El proyecto comienza con un producto pequeño y utilizable, pero se diseña desde el inicio para poder evolucionar hacia experiencias de reproducción no convencionales.

La primera versión no intenta competir por cantidad de funciones. Su objetivo es establecer un núcleo sólido alrededor de tres elementos:

```text
Biblioteca local
      +
Reproducción
      +
Letras sincronizadas
```

Sobre este núcleo podrán aparecer posteriormente modos como karaoke, DJ, visualización avanzada, layouts configurables y widgets personalizados.

## 2. Problema

Los reproductores tradicionales suelen tratar la reproducción como una única experiencia fija. Otune busca que la reproducción sea una capacidad reutilizable sobre la que distintas experiencias puedan construirse.

Ejemplos futuros:

- reproducción convencional;
- karaoke;
- DJ;
- visualización musical;
- interfaces minimalistas o inmersivas;
- workspaces configurables;
- widgets experimentales.

## 3. Objetivo general

Diseñar y desarrollar un reproductor musical multiplataforma basado en una arquitectura modular y extensible, capaz de funcionar localmente y que pueda evolucionar hacia diferentes experiencias de interacción con el audio sin acoplar el dominio a una tecnología específica de reproducción.

## 4. Objetivos específicos

- Implementar una biblioteca local multiplataforma.
- Implementar reproducción con `media_kit`.
- Mantener una abstracción propia `AudioEngine`.
- Implementar cola, búsqueda, shuffle, repeat y control de reproducción.
- Implementar lectura y presentación de letras LRC.
- Persistir biblioteca, preferencias y estado relevante de forma local.
- Diseñar una base de UI basada en widgets reutilizables.
- Separar Theme, Layout, Widget y Behavior.
- Documentar las decisiones arquitectónicas.
- Mantener puntos de extensión sin implementar todavía un sistema de plugins dinámicos.

## 5. Alcance inicial

### MVP — Reproductor

Plataformas prioritarias:

1. Android.
2. Windows.
3. Linux/macOS como plataformas posteriores del mismo código base.
4. iOS posteriormente.
5. Web únicamente para capacidades compatibles con sus restricciones.

Funciones:

- escaneo/importación de biblioteca;
- álbumes, artistas y pistas;
- búsqueda;
- reproductor;
- cola;
- shuffle;
- repeat;
- seek;
- progreso;
- carátula;
- letras LRC;
- preferencias de interfaz.

## 6. Fuera del MVP

- karaoke completo;
- DJ;
- mezclador avanzado;
- procesamiento DSP propio;
- plugins descargables;
- sincronización en nube;
- cuentas;
- streaming de servicios externos;
- servidor multimedia.

## 7. Arquitectura propuesta

```text
                         Otune
                            │
                ┌───────────┴───────────┐
                │                       │
          Flutter Presentation     Application
                │                       │
                └───────────┬───────────┘
                            │
                          Domain
             ┌──────────────┼──────────────┐
             │              │              │
          Library        Playback        Lyrics
             │              │              │
             └──────────────┼──────────────┘
                            │
                     Infrastructure
                 ┌──────────┼──────────┐
                 │          │          │
               Drift    AudioEngine  Files/OS
                            │
                            ▼
                        media_kit
```

## 8. Estructura de proyecto

```text
Otune/
├── lib/
│   ├── app/
│   ├── core/
│   │   ├── error/
│   │   ├── logging/
│   │   └── routing/
│   └── features/
│       ├── library/
│       ├── playback/
│       ├── lyrics/
│       └── settings/
├── test/
├── integration_test/
├── docs/
├── assets/
└── AGENTS.md
```

## 9. Stack recomendado

| Área | Elección | Motivo |
|---|---|---|
| UI | Flutter | código compartido y gran capacidad de personalización |
| SDK | Flutter 3.47.x | rama estable vigente al momento de la propuesta |
| Audio | `media_kit` | reproducción multiplataforma basada en FFI, modular y con soporte amplio |
| Estado | Riverpod 3 | estado reactivo, composición y testing |
| DB | Drift + SQLite | SQL, migraciones, queries reactivas y FTS5 |
| Routing | `go_router` | routing declarativo, deep links y múltiples plataformas |
| Theme | Flutter Material 3 + `dynamic_color` | integración con color dinámico del sistema |
| Theme avanzado | `flex_color_scheme` opcional | generación y personalización avanzada de ColorScheme |
| Modelos | Freezed opcional | value objects/data classes inmutables cuando sean útiles |
| JSON | `json_serializable` | serialización declarativa |
| Generación | `build_runner` | generación controlada |
| Filesystem | `path_provider` | rutas de app/temp/documentos |
| File picker | `file_picker` | selección/importación/exportación multiplataforma |
| Permisos | `permission_handler` | permisos de plataforma cuando sean necesarios |
| Android MediaStore | `media_store_plus` | acceso específico a MediaStore |
| Secure storage | `flutter_secure_storage` | secretos/preferencias sensibles futuras |
| Testing mocks | `mocktail` | mocks sin generación de código |
| Lint | `very_good_analysis` | reglas modernas para Dart/Flutter |
| Logging | `logger` | logging centralizado y extensible |
| IDs | `uuid` | IDs independientes de índices locales |

## 10. Dependencias iniciales sugeridas

Las versiones deben resolverse y actualizarse mediante `flutter pub outdated` al inicializar el repositorio. Como referencia verificable en septiembre de 2026, las versiones publicadas consultadas son:

```yaml
dependencies:
  flutter:
    sdk: flutter
  media_kit: ^1.2.6
  media_kit_libs_audio: ^1.0.7
  flutter_riverpod: ^3.4.3
  drift: ^2.35.0
  go_router: ^18.0.1
  dynamic_color: ^2.1.0
  flex_color_scheme: ^8.4.0
  path_provider: ^2.1.6
  file_picker: ^12.2.0
  permission_handler: ^13.0.2
  flutter_secure_storage: ^11.0.0
  logger: ^2.8.0
  uuid: ^4.6.0
  freezed_annotation: ^3.1.0
  json_annotation: ^4.12.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.16.1
  freezed: ^3.2.1
  json_serializable: ^6.14.1
  mocktail: ^1.0.5
  very_good_analysis: ^11.0.0
```

> Las versiones de Freezed/json_serializable no se fijan como autoridad de arquitectura en este documento: deben resolverse en el momento de crear el proyecto y validarse contra la versión estable de Flutter/Dart seleccionada.

## 11. Decisiones clave

### D1 — Flutter como UI común

La aplicación requiere alta personalización visual, múltiples plataformas y una gran cantidad de componentes interactivos. Flutter permite compartir gran parte del código y, a la vez, acceder a capacidades de plataforma cuando sea necesario.

### D2 — `media_kit` como motor inicial

`media_kit` soporta Android, iOS, Windows, macOS, Linux y web y está diseñado como reproductor de audio/video multiplataforma. Su implementación comparte una gran parte del código mediante Dart/FFI. Eso reduce el acoplamiento inicial con plataformas específicas.

### D3 — `AudioEngine` propio

Aunque `media_kit` sea el motor inicial, el dominio no debe depender de su API.

```text
Playback → AudioEngine → MediaKitAudioEngine → media_kit
```

Esto mantiene abierta la posibilidad de introducir otro motor o uno propio para capacidades avanzadas.

### D4 — No construir todavía un motor Rust

Karaoke avanzado, DJ, mezcla y DSP pueden justificar un motor especializado en el futuro. No existe suficiente evidencia en el MVP para asumir ese coste desde el primer commit.

### D5 — No construir plugins todavía

La extensibilidad se obtiene mediante interfaces y límites de dominio. Los plugins reales se diseñarán cuando existan capacidades que deban ser extendidas en ejecución.

## 12. Evolución prevista

### Fase 1 — Player

```text
Library
Playback
Lyrics LRC
Settings
```

### Fase 2 — Lyrics Studio

```text
LRC editor
Synchronization
Lyrics sources
Lyrics history
```

### Fase 3 — Personalization

```text
Themes
Layouts
Workspaces
Widget configuration
```

### Fase 4 — Audio experiences

```text
Karaoke
Visualizers
Waveform analysis
```

### Fase 5 — DJ

```text
Decks
Mixer
Crossfader
Cue
Loops
Effects
```

### Fase 6 — Extensibility

Solo si las necesidades reales lo justifican:

```text
Providers
Extensions
Widgets
Automation
External integrations
```

## 13. Diseño de personalización

La UI futura se plantea como:

```text
Workspace
 ├── Theme
 ├── Layout
 ├── Widgets
 └── Behavior
```

Ejemplos de widgets:

```text
PlayerWidget
LyricsWidget
QueueWidget
AlbumArtWidget
WaveformWidget
SpectrumWidget
StatsWidget
DjDeckWidget
MixerWidget
```

En MVP estos son componentes internos. No se permite cargar código Dart arbitrario desde archivos externos.

## 14. Criterios de éxito del MVP

El MVP está terminado cuando puede:

- indexar una biblioteca musical local;
- reproducir pistas con `media_kit`;
- mantener una cola funcional;
- continuar reproduciendo mientras la UI cambia;
- buscar pistas;
- cargar y sincronizar un LRC;
- recuperar estado básico de la aplicación;
- funcionar sin servidor externo;
- ejecutar pruebas automatizadas del dominio y casos de uso principales.

## 15. Primer incremento de implementación

El primer objetivo práctico debe ser todavía menor:

```text
Flutter app
   ↓
MediaKit inicializado
   ↓
Archivo local elegido
   ↓
Play / Pause
   ↓
Seek
   ↓
Estado observable
```

Después se añade la biblioteca y finalmente las letras.

La idea es validar el pipeline de audio y las restricciones de plataforma antes de construir navegación, base de datos y personalización en exceso.

## 20. Método de desarrollo — SDD + DDD

El proyecto se desarrollará siguiendo Spec-Driven Development apoyado por DDD.

```text
Idea / problema
      ↓
SPEC
      ↓
DDD / contexto
      ↓
Caso de uso
      ↓
Implementación
      ↓
Tests
      ↓
Verificación
```

### Primera tanda de especificaciones

El MVP debería comenzar con specs pequeñas:

```text
docs/specs/
├── library/
│   ├── scan-library.md
│   └── search-library.md
├── playback/
│   ├── play-track.md
│   ├── queue.md
│   ├── shuffle.md
│   └── repeat.md
├── lyrics/
│   └── read-lrc.md
└── personalization/
    └── basic-theme.md
```

No es necesario crear todas de una vez. Se crean conforme se prioricen las features.

### Definition of Ready

Una feature entra a desarrollo cuando tiene:

- objetivo claro;
- alcance y no-goals;
- comportamiento esperado;
- escenarios principales;
- casos límite relevantes;
- criterios de aceptación;
- estrategia de pruebas;
- dependencias conocidas.

### Definition of Done

Una feature se considera terminada cuando sus criterios de aceptación están cubiertos por evidencia, las pruebas relevantes pasan, el análisis estático pasa y la documentación representa el comportamiento real.

## 21. Roadmap inicial orientado por specs

### Iteración 0 — Foundation

```text
Flutter project
media_kit
AudioEngine interface
logging
linting
basic routing
```

Objetivo: reproducir un archivo local mediante el primer adaptador `MediaKitAudioEngine`.

### Iteración 1 — Library

```text
ScanLibrary
Track
basic search
library screens
```

### Iteración 2 — Playback

```text
Queue
shuffle
repeat
persistent playback preferences
```

### Iteración 3 — Lyrics

```text
LRC parser
lyrics display
synchronization against playback position
```

### Iteración 4 — Personalization

```text
Theme
basic layout preferences
reusable widgets
```

### Después del MVP

Cada feature avanzada debe nacer como SPEC independiente:

```text
Karaoke
DJ Mode
Visualizer
Workspace
Widget System
Metadata Editor
Lyrics Studio
```

Una SPEC futura puede permanecer en `Draft` durante meses. Eso no genera obligación de implementarla.

## 22. Criterio de evolución tecnológica

Una tecnología adicional solo se incorpora cuando una SPEC aprobada la necesita.

Ejemplos:

```text
SPEC exige DSP de baja latencia
        ↓
evaluar Rust/native engine

SPEC exige escritura remota de metadata
        ↓
evaluar Core externo

SPEC exige extensiones de terceros
        ↓
diseñar plugin protocol
```

De esta forma, la hoja de ruta evita que las posibilidades futuras se conviertan en infraestructura prematura.
