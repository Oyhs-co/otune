# Otune

Otune es un reproductor musical local, offline-first y multiplataforma. Está
orientado a personas que prefieren conservar y reproducir sus propias
bibliotecas de audio sin depender de servicios de streaming.

Versión actual: `0.6.0-alpha.0+23`

El proyecto se encuentra en desarrollo activo. La versión actual prioriza un
núcleo funcional de biblioteca local, reproducción, cola y letras LRC antes de
incorporar funciones avanzadas.

## Funcionalidades disponibles

### Biblioteca local

- Escaneo recursivo de carpetas seleccionadas por el usuario.
- Soporte para archivos de audio y vídeo compatibles con el motor, incluidos
  MP3, FLAC, WAV, M4A, OGG, OPUS, AAC, MP4, MKV, MOV, WEBM y WMA.
- Lectura de título, artista, álbum, número de pista, duración y formato.
- Persistencia local de pistas mediante Drift/SQLite.
- Búsqueda por título, artista o álbum.
- Vistas de biblioteca en lista, cuadrícula y modo detallado.
- Visualización de carátulas cuando están disponibles en los metadatos.

### Reproducción

- Selección de archivos locales desde el explorador del sistema.
- Reproducción, pausa, parada, avance, retroceso y búsqueda por posición.
- Control de volumen y silencio.
- Pista anterior y siguiente.
- Cola de reproducción con reproducción inmediata, reproducción siguiente,
  adición, eliminación y vaciado.
- Modos de reproducción normal, repetición y repetición de una pista.
- Reproducción aleatoria.
- Vistas de cola en lista y modo detallado.
- Motor de audio basado en `media_kit`, aislado detrás de la abstracción propia
  `AudioEngine`.

### Letras sincronizadas

- Lectura de archivos `.lrc` locales con el mismo nombre que la pista.
- Parseo de timestamps por línea.
- Resaltado de la línea activa según la posición de reproducción.
- Manejo tolerante cuando no existe un archivo de letras asociado.

### Aplicación y configuración

- Pantalla splash inicial.
- Navegación entre reproductor, biblioteca y ajustes.
- Tema claro, oscuro o dependiente del sistema.
- Colores dinámicos cuando la plataforma los proporciona.
- Pantalla de información con versión, icono de la aplicación y firma
  `By Oyhs-Co`.

## Estado actual y limitaciones

- La aplicación funciona principalmente con archivos locales; no ofrece
  streaming externo, cuentas ni sincronización en la nube.
- Las preferencias de tema se mantienen en el estado de la sesión actual; la
  persistencia de preferencias todavía está pendiente.
- La asociación de letras utiliza la convención de nombre de archivo. La
  asociación manual todavía no modifica una relación persistente.
- El soporte de letras actual es por línea; no incluye letras embebidas ni
  sincronización por palabra.
- La experiencia de biblioteca y reproducción sigue siendo un MVP y puede
	cambiar durante la etapa alfa.

## Roadmap

Las siguientes capacidades pertenecen a fases posteriores y no forman parte
de la versión actual:

- Persistencia de preferencias y configuración de usuario.
- Mejoras de organización por álbumes y artistas.
- Edición o asociación persistente de letras.
- Karaoke, visualizadores y experiencias de DJ.
- Layouts configurables, widgets personalizados y extensiones.
- Sincronización entre dispositivos, cuentas, streaming externo y servidor
	multimedia.

## Stack tecnológico

- **Framework:** Flutter y Dart.
- **UI:** Material 3 y `dynamic_color`.
- **Estado e inyección:** Riverpod 3.
- **Persistencia:** Drift sobre SQLite.
- **Reproducción:** `media_kit` y `media_kit_libs_audio`.
- **Navegación:** `go_router`.
- **Archivos:** `file_picker` y APIs locales de plataforma.
- **Calidad:** `very_good_analysis`, `flutter_test` y `mocktail`.

## Arquitectura

El código está organizado por feature y separa dominio, aplicación, datos y
presentación:

```text
frontend/lib/
├── app/                 # Arranque, rutas y tema
├── core/                # Persistencia y servicios compartidos
└── features/
    ├── library/         # Escaneo, búsqueda y biblioteca local
    ├── lyrics/          # Parser LRC y sincronización
    ├── playback/        # Motor, reproducción y cola
    └── settings/        # Preferencias y pantalla de ajustes
```

El dominio no depende de Flutter, Drift ni `media_kit`. La documentación de
arquitectura, especificaciones y decisiones se encuentra en [`docs/`](docs/).

## Requisitos

- Flutter estable compatible con el SDK indicado en
  [`frontend/pubspec.yaml`](frontend/pubspec.yaml).
- Dart incluido con Flutter.
- Un dispositivo o emulador compatible con la plataforma que se quiera
	ejecutar.

## Instalación y desarrollo

Desde la raíz del repositorio:

```bash
cd frontend
flutter pub get
```

Para ejecutar la aplicación:

```bash
flutter run
```

Para comprobar el proyecto:

```bash
flutter analyze
flutter test
```

Si se modifican modelos que requieren generación de código:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Documentación

- [`docs/PROJECT_PROPOSAL.md`](docs/PROJECT_PROPOSAL.md): propósito y alcance
  del producto.
- [`docs/DDD.md`](docs/DDD.md): límites del dominio y arquitectura.
- [`docs/SDD.md`](docs/SDD.md): proceso de especificación y verificación.
- [`docs/specs/`](docs/specs/): contratos funcionales por feature.
- [`CHANGELOG.md`](CHANGELOG.md): historial de versiones.

## Licencia

Consulta [`LICENSE`](LICENSE) para conocer los términos de uso del proyecto.
