# STACK.md — Guía tecnológica de Otune

## Estado de referencia

Investigado el 10 de septiembre de 2026.

Flutter estable vigente consultado: 3.47.x; Flutter publica sus releases estables y marca 3.47 como release de agosto de 2026. La documentación de arquitectura oficial recomienda separar responsabilidades para mejorar mantenibilidad, escalabilidad y testing.

## Recomendación principal

```text
Flutter 3.47.x
Dart 3.12.x
        │
        ├── Riverpod 3
        ├── Drift / SQLite
        ├── go_router
        ├── media_kit
        ├── Material 3
        ├── dynamic_color
        └── very_good_analysis
```

## Audio

### `media_kit`

Elegido para el MVP.

Ventajas:

- Android, iOS, Windows, macOS, Linux y web.
- arquitectura modular;
- FFI y gran parte del comportamiento compartido;
- codecs y reproducción amplia;
- API relativamente compacta.

Paquetes base para audio:

```yaml
dependencies:
  media_kit: ^1.2.6
  media_kit_libs_audio: ^1.0.7
```

No incluir `media_kit_video` mientras Otune sea solo audio.

### `just_audio`

No se considera la opción primaria. Sigue siendo un paquete de audio muy maduro, pero su soporte oficial de plataformas es distinto al de `media_kit`, y la visión de Otune favorece desde temprano un stack multiplataforma más uniforme.

## Estado

`flutter_riverpod` 3.4.x.

Regla: no poner estado mutable global dentro de widgets.

Preferir:

```dart
final playbackControllerProvider = ...;
```

sobre controladores singleton manuales.

## Base de datos

`drift` 2.35.x.

Es adecuada porque Otune necesita:

- relaciones entre artistas, álbumes y pistas;
- consultas complejas;
- índices;
- migraciones;
- streams reactivos;
- eventualmente FTS5.

No utilizar una base documental solo por simplicidad percibida.

## Routing

`go_router` 18.x.

Es paquete oficial del ecosistema Flutter y soporta routing declarativo y deep linking en plataformas múltiples.

La navegación debe estar centralizada en `app/routing`.

## Theming

### Base

Material 3 nativo de Flutter.

### `dynamic_color`

Usarlo para integrar colores dinámicos de Android y las capacidades equivalentes soportadas en desktop.

### `flex_color_scheme`

Opcional. Introducirlo solamente cuando el sistema de temas necesite generación y configuración más avanzada que `ColorScheme` de Flutter.

No introducir ambas bibliotecas para resolver el mismo problema sin una razón documentada.

## Modelos y serialización

### Freezed

Útil para:

- estados inmutables;
- sealed unions;
- value objects sencillos;
- modelos de configuración.

No usarlo para cada clase del dominio automáticamente.

### json_serializable

Usarlo en fronteras de datos:

- persistencia JSON;
- configuración de workspaces;
- contratos externos;
- import/export.

### build_runner

Solo como herramienta de generación de código.

## Sistema de archivos

`path_provider` para rutas conocidas de la app.

`file_picker` para selección de archivos y carpetas donde la plataforma lo soporte.

`media_store_plus` solo detrás de un adaptador Android. La lógica de dominio no debe importar Android MediaStore.

`permission_handler` solo cuando realmente exista un permiso requerido; evitar pedir permisos de almacenamiento innecesarios.

## Seguridad

`flutter_secure_storage` queda disponible para tokens, credenciales locales o secretos futuros.

No introducir almacenamiento seguro en el MVP si no hay secretos que proteger.

## Testing

### Unit tests

Flutter/Dart test runner.

### Mocks

`mocktail` cuando un double simplifique la prueba.

### Integration

`integration_test` solo en flujos importantes de plataforma:

- selección de archivo;
- reproducción real;
- integración de MediaStore;
- background/audio focus cuando corresponda.

## Linting

`very_good_analysis` 11.x como base.

El lint debe ser una herramienta, no una religión. Una regla puede desactivarse localmente si existe una razón técnica clara y se documenta cuando el impacto sea importante.

## Logging

`logger` centralizado.

Reglas:

- no `print()` para logging permanente;
- niveles coherentes;
- no registrar contenido sensible;
- logs suficientemente contextuales para identificar feature/operación.

## Identidad

`uuid` puede utilizarse para identificadores persistentes independientes de la DB local.

Para entidades puramente internas con identidad autoincremental y sin export/import no es obligatorio.

## Lo que NO instalaría de inicio

- Dio si no existe backend HTTP.
- Retrofit solo para unas pocas llamadas.
- GetIt si Riverpod ya cubre composición.
- Bloc junto a Riverpod.
- Freezed en todas las entidades por defecto.
- Isar/Hive además de Drift.
- un framework de plugins.
- un motor DSP propio.
- Rust/FFI antes de tener un benchmark o feature que lo exija.

## Estrategia de actualización

No perseguir cada release automáticamente.

Antes de actualizar Flutter:

```bash
flutter channel stable
flutter upgrade
flutter pub outdated
flutter analyze
flutter test
```

Las actualizaciones mayores deben ser un cambio deliberado y revisado.

## Spec-Driven Development

El stack no debe determinar el comportamiento antes de que exista una necesidad especificada.

Para cada dependencia nueva:

```text
SPEC
 ↓
Necesidad concreta
 ↓
Evaluación de alternativas
 ↓
Decisión
 ↓
Dependencia
```

No agregar una librería simplemente porque podría resultar útil en una feature futura.

Una SPEC debe expresar primero:

```text
"La aplicación debe hacer X"
```

y posteriormente la arquitectura decide:

```text
"Para hacerlo utilizaremos Y"
```

### Ejemplo: audio

La SPEC define:

```text
El usuario puede reproducir, pausar, buscar y cambiar de pista.
```

La arquitectura define:

```text
Playback → AudioEngine → MediaKitAudioEngine → media_kit
```

Así `media_kit` puede sustituirse posteriormente sin alterar el contrato del dominio.

## Dependencias y SDD

Las siguientes dependencias solo deben activarse cuando una SPEC las justifique:

- `file_picker`: importación/exportación explícita.
- `permission_handler`: permisos de plataforma realmente necesarios.
- `media_store_plus`: capacidades Android que no puedan resolverse con abstracciones multiplataforma.
- `flutter_secure_storage`: secretos o credenciales reales.
- `flex_color_scheme`: necesidades de theming que superen Material 3 + `dynamic_color`.
- `freezed` / `json_serializable`: cuando la generación aporte valor claro.

Este criterio evita que el proyecto acumule dependencias sin necesidad funcional.
