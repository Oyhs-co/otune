# DDD — Domain-Driven Design para Otune

## 1. Propósito

Este documento define cómo aplicar DDD de forma pragmática en Otune. No pretende convertir un reproductor en un sistema enterprise. DDD se utiliza para mantener estable el dominio mientras evolucionan reproducción, letras, karaoke, DJ, widgets y personalización.

## 2. Bounded Contexts iniciales

### Library

Responsable de la biblioteca musical local.

Conceptos principales:

- `Track`
- `Album`
- `Artist`
- `LibrarySource`
- `TrackIdentity`

Responsabilidades:

- descubrir pistas;
- indexarlas;
- buscar;
- mantener identidad local;
- detectar cambios de origen.

No es responsable de reproducir audio.

### Playback

Responsable de la sesión de reproducción.

Conceptos principales:

- `PlaybackSession`
- `Queue`
- `QueueItem`
- `PlaybackState`
- `PlaybackMode`
- `Position`

Responsabilidades:

- cargar pista;
- reproducir/pausar;
- seek;
- cola;
- shuffle;
- repeat;
- transición entre pistas.

No es responsable de leer metadata ni de decidir cómo se dibuja la UI.

### Lyrics

Responsable de letras y sincronización.

Conceptos:

- `Lyrics`
- `LyricLine`
- `LyricTimestamp`
- `LyricsSource`
- `LyricsSync`

Ejemplo conceptual:

```text
Lyrics
 ├── source
 ├── language?
 ├── lines[]
 │    ├── timestamp
 │    └── text
 └── synchronization
```

### Personalization

Responsable de preferencias visuales y futuras composiciones de workspace.

En MVP solo contiene configuración de tema y preferencias de UI.

Más adelante podrá crecer hacia:

```text
Workspace
 ├── Layout
 ├── Widgets
 ├── Theme
 └── Behavior
```

### Audio Engine

No es un bounded context de negocio puro. Es una capacidad de infraestructura detrás de una interfaz estable.

```text
Playback Application
        │
        ▼
   AudioEngine
        │
        ▼
    media_kit
```

Su objetivo es aislar el dominio de la biblioteca concreta.

## 3. Entidades

### Track

Una pista representa una obra reproducible identificada dentro de la biblioteca.

Campos iniciales sugeridos:

```text
id
source
title
artist
album
albumArtist
trackNumber
duration
fileFormat
```

La identidad de la aplicación no debe depender únicamente de la posición de un índice SQLite.

### Album

Agrupa pistas por información de álbum.

No almacenar información derivable en múltiples lugares salvo que exista una razón de rendimiento.

### PlaybackSession

Representa el estado actual de reproducción.

Debe abstraer el motor concreto.

## 4. Value Objects

Usar value objects cuando aporten invariantes o semántica.

Ejemplos:

```text
TrackId
DurationMs
TimestampMs
LyricLineIndex
PlaybackRate
Volume
```

No convertir cada `String` en una clase solo para demostrar DDD.

## 5. Aggregates

### PlaybackSession como agregado

La sesión puede tratarse como agregado raíz para operaciones que cambien coherentemente:

- pista actual;
- posición;
- estado;
- modo de repetición;
- cola activa.

La cola no debe exponer mutaciones arbitrarias desde la UI.

## 6. Domain Services

Usar servicios de dominio cuando una operación no pertenezca naturalmente a una entidad.

Ejemplos futuros:

```text
LyricsSynchronizer
QueueShuffler
TrackMatcher
```

Un servicio no debe convertirse en un "manager" gigante.

## 7. Application Services / Use Cases

Los casos de uso coordinan dominio y puertos.

Ejemplos MVP:

```text
ScanLibrary
SearchTracks
PlayTrack
PausePlayback
SeekPlayback
SkipToNextTrack
ToggleShuffle
ToggleRepeat
LoadLyrics
```

Futuro:

```text
CreateSyncedLyrics
EnterKaraokeMode
CreateDjSession
SaveWorkspace
InstallExtension
```

## 8. Ports and Adapters

### Ports

```text
AudioEngine
TrackRepository
LyricsRepository
LyricsProvider
LibraryScanner
PreferencesRepository
```

### Adapters

```text
MediaKitAudioEngine
DriftTrackRepository
LocalLyricsRepository
FileSystemLibraryScanner
SharedPreferencesRepository
```

La regla es:

> El dominio conoce capacidades; la infraestructura conoce tecnologías.

## 9. Dependencias

```text
Presentation
    ↓
Application
    ↓
Domain
    ↑
Infrastructure / Data
```

La infraestructura implementa contratos definidos por capas internas. La UI no debe saltarse la aplicación para manipular directamente Drift o `media_kit`.

## 10. Evolución hacia Karaoke

No crear un `KaraokeContext` hasta que exista una necesidad real.

Cuando aparezca, podría modelarse como una especialización de la experiencia de reproducción:

```text
PlaybackSession
       │
       ├── StandardMode
       └── KaraokeMode
             ├── LyricsTimeline
             ├── VocalPresentation
             └── UserControls
```

La letra sincronizada debe ser una capacidad reutilizable y no una propiedad exclusiva de una pantalla de karaoke.

## 11. Evolución hacia DJ

El modo DJ justifica un modelo de audio diferente al reproductor lineal.

Posible dominio futuro:

```text
DjSession
 ├── Deck A
 ├── Deck B
 ├── Mixer
 ├── Crossfader
 ├── Cue
 ├── Loop
 └── Effects
```

El error a evitar es contaminar `PlaybackSession` con docenas de campos DJ antes de que existan.

Cuando llegue ese punto, `AudioEngine` puede evolucionar hacia una capacidad más general:

```text
AudioGraph
 ├── Source
 ├── Processor
 ├── Mixer
 ├── Effect
 └── Output
```

## 12. Widgets como dominio de presentación

Un widget de Otune no debe ser una entidad de negocio.

Es preferible:

```text
WidgetDefinition
WidgetInstance
WidgetConfiguration
Workspace
```

La configuración puede persistirse como datos. La implementación del widget continúa siendo código compilado.

## 13. Eventos de dominio

Usar eventos solo cuando desacoplen una consecuencia real.

Ejemplos posibles:

```text
TrackStarted
TrackCompleted
QueueChanged
LyricsLoaded
PlaybackModeChanged
```

No crear un event bus global antes de necesitarlo.

## 14. Reglas de modelado

- Si una regla puede expresarse como función pura, preferirla a una jerarquía de clases.
- Si dos modelos tienen distinta razón de cambio, no fusionarlos.
- No compartir modelos de infraestructura con el dominio.
- No crear abstracciones pensando en plugins futuros sin un uso actual.
- Una interfaz debe representar una capacidad que el sistema realmente necesita intercambiar.

## 16. Relación con Spec-Driven Development

DDD y SDD se complementan:

```text
SDD
¿Qué comportamiento necesita el usuario?
          │
          ▼
DDD
¿En qué bounded context y agregado vive?
          │
          ▼
Application
¿Qué use case lo coordina?
          │
          ▼
Ports
¿Qué capacidades necesita?
          │
          ▼
Infrastructure
¿Cómo se implementan esas capacidades?
```

Una SPEC no debe imponer una clase concreta, salvo que la tecnología sea parte explícita del requisito.

Ejemplo:

```text
SPEC: reproducir una pista local
        ↓
Playback context
        ↓
PlayTrack use case
        ↓
AudioEngine port
        ↓
MediaKitAudioEngine adapter
```

Esto permite cambiar `media_kit` en el futuro sin cambiar el comportamiento de dominio descrito por la SPEC.

## 17. Cambios de dominio guiados por SPEC

Una nueva SPEC puede justificar la evolución del modelo.

Ejemplo:

```text
SPEC Karaoke
     ↓
Lyrics ya no solo necesita LyricLine
     ↓
se introduce WordTiming / KaraokeLine
     ↓
ADR si existe decisión arquitectónica importante
     ↓
DDD actualizado
```

No añadir conceptos como `DjSession`, `Workspace`, `EffectChain` o `PluginManifest` únicamente porque podrían ser necesarios algún día.

## 18. Regla de evolución

> Primero existe comportamiento real; después abstraemos la variación que ese comportamiento demuestra.

Una abstracción futura puede reservarse mediante una interfaz pequeña cuando tenga un beneficio inmediato, pero el agente debe evitar diseñar APIs completas para features que siguen en `Draft`.
