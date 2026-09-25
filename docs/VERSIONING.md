# VERSIONING.md — Política de Versionado y Tags de Otune

## 1. Propósito

Este documento define la política oficial de versionado, gestión de identificadores de compilación (_build numbers_) y sistema de tags Git para el proyecto Otune. El objetivo es garantizar coherencia, trazabilidad y reproducibilidad en todos los lanzamientos multiplataforma (Android, Windows, Linux, macOS, iOS y Web).

---

## 2. Esquema de Versionado

Otune adopta **Semantic Versioning 2.0.0 (SemVer)** adaptado al formato estándar de proyectos Flutter:

```text
MAJOR.MINOR.PATCH+BUILD
```

Ejemplo: `0.1.0+1`, `1.2.3+45`

### 2.1 Componentes de la Versión

| Componente | Cuándo se incrementa                                                                                                                                                                                                                                            | Ejemplo           |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| **MAJOR**  | Cambios incompatibles (breaking changes) en el dominio, migraciones destructivas de base de datos sin compatibilidad retroactiva, cambios radicales de arquitectura o rediseños completos de contratos públicos.                                                | `0.x.y` → `1.0.0` |
| **MINOR**  | Nuevas funcionalidades completas y estables que no rompen compatibilidad (ej. implementación de nueva SPEC como soporte de letras LRC, gestor de cola, escáner de biblioteca).                                                                                  | `0.1.0` → `0.2.0` |
| **PATCH**  | Correcciones de errores (_bug fixes_), mejoras internas de rendimiento, refactorizaciones que no alteran el comportamiento externo o ajustes de documentación/configuración.                                                                                    | `0.1.0` → `0.1.1` |
| **BUILD**  | Número entero estrictamente incremental (`1, 2, 3, ...`). Se incrementa en cada compilación para distribución o release interno. Requerido para tiendas y sistemas operativos (ej. Android `versionCode`, iOS `CFBundleVersion`). **Nunca debe decrementarse**. | `+1` → `+2`       |

### 2.2 Sufijos de Pre-lanzamiento (Pre-releases)

Para versiones en desarrollo activo, pruebas alfa/beta o candidatos a lanzamiento (_Release Candidates_), se añade un identificador alfanumérico antes del build number:

```text
MAJOR.MINOR.PATCH-<canal>.<iteracion>+BUILD
```

Canales permitidos:

- **`alpha`**: Versiones de trabajo en progreso con funcionalidades experimentales o parcialmente completadas (ej. `0.1.0-alpha.1+1`).
- **`beta`**: Versiones donde todas las funcionalidades planificadas para el hito están presentes pero requieren estabilización y pruebas (ej. `0.1.0-beta.1+4`).
- **`rc`** (_Release Candidate_): Versión congelada, candidata directa a convertirse en versión estable final si no se detectan fallos críticos (ej. `0.1.0-rc.1+8`).

---

## 3. Hoja de Ruta de Versionado (Fases del Ciclo de Vida)

### 3.1 Fase Pre-1.0 (MVP y Construcción Inicial)

Durante la fase `0.x.y`, la API y los contratos internos pueden sufrir cambios evolutivos frecuentes mientras se consolida el núcleo arquitectónico:

- `0.1.0`: Core de reproducción local (`AudioEngine` + `media_kit` básico).
- `0.2.0`: Control de cola (`Queue`), `shuffle` y `repeat`.
- `0.3.0`: Biblioteca local y persistencia con Drift/SQLite.
- `0.4.0`: Letras sincronizadas (`LRC`).
- `0.5.0`: Personalización básica (M3 Theming y colores dinámicos).
- `1.0.0`: Primer release público oficial con el MVP completo y estable.

### 3.2 Fase Post-1.0 (Estabilidad y Extensibilidad)

A partir de `1.0.0`, cualquier cambio incompatible requiere incremento de versión `MAJOR`. Las extensiones (karaoke, visualizadores, workspaces) se introducen como incrementos `MINOR` tras su respectivo ADR y SPEC aprobados.

---

## 4. Punto Único de Verdad (Single Source of Truth)

La fuente canónica de la versión es el archivo de manifiesto de la aplicación:

```text
frontend/pubspec.yaml
```

En la línea:

```yaml
version: 0.7.0-alpha.0+25
```

### 4.1 Sincronización con Plataformas Nativas

Flutter propaga automáticamente el valor `version` de `pubspec.yaml` a las distintas plataformas soportadas durante el build:

- **Android:**
  - `versionName` ← `0.1.0` (o `0.1.0-alpha.1`)
  - `versionCode` ← `1` (el entero tras el `+`)
- **Windows:**
  - Versión del ejecutable en `windows/runner/Runner.rc` (mapeada a cuádrupla numérica `0,1,0,1`).
- **iOS / macOS:**
  - `CFBundleShortVersionString` ← `0.1.0`
  - `CFBundleVersion` ← `1`
- **Linux:**
  - Definición en CMake / metadatos de la aplicación.

> [!IMPORTANT]
> Nunca modifiques manualmente las versiones en los archivos nativos de plataforma (`AndroidManifest.xml`, `Runner.rc`, `Info.plist`). La versión siempre debe actualizarse exclusivamente en `pubspec.yaml`.

---

## 5. Sistema de Tags Git

Todos los hitos, pre-lanzamientos y versiones estables deben etiquetarse en Git siguiendo un estándar estricto.

### 5.1 Nomenclatura de Tags

Los tags deben utilizar el prefijo `v` minúscula seguido de la versión SemVer completa:

```text
vMAJOR.MINOR.PATCH[-PRERELEASE]
```

Ejemplos:

- Versión estable: `v1.0.0`
- Versión de desarrollo inicial: `v0.1.0`
- Patch fix: `v0.1.1`
- Pre-release: `v0.1.0-alpha.1`, `v0.2.0-rc.1`

> [!WARNING]
> No incluir el número de compilación (`+BUILD`) dentro del nombre del tag Git. El formato correcto es `v0.1.0`, **no** `v0.1.0+1`. El build number pertenece al commit y al artefacto de compilación.

### 5.2 Reglas de Etiquetado

1. **Solo Tags Anotados (`annotated tags`):**
   Nunca usar tags ligeros (_lightweight_). Los tags deben crearse siempre con `-a` para incluir autor, fecha y mensaje descriptivo de la versión.,

   ```bash
   git tag -a v0.1.0 -m "Release v0.1.0: Reproducción de audio local y AudioEngine base"
   ```

2. **Criterios para crear un Tag:**
   Un tag solo puede crearse si se cumplen TODAS las siguientes condiciones:
   - Los tests relevantes pasan sin errores (`flutter test`).
   - El analizador estático no reporta fallos (`flutter analyze`).
   - La sección `[Unreleased]` de `CHANGELOG.md` ha sido cerrada con el número de versión y fecha correspondiente.
   - El archivo `pubspec.yaml` tiene asignada la misma versión exacta.
   - El commit de preparación de release (`chore(release): bump version to vX.Y.Z`) ha sido integrado a `main`.

---

## 6. Integración con CHANGELOG y Flujo de Trabajo

Cada versión etiquetada debe contar con su correspondiente bloque en `CHANGELOG.md` siguiendo el estándar _Keep a Changelog_.

### 6.1 Secuencia para Lanzar una Versión (Release Flow)

```text
1. Cierre de funcionalidades: Todas las SPECs planificadas están completadas y verificadas.
2. Verificación de calidad: `flutter analyze` y `flutter test` aprobados.
3. Actualización de CHANGELOG: Mover las entradas de [Unreleased] a [X.Y.Z] - YYYY-MM-DD.
4. Actualización de pubspec.yaml: Incrementar versión y build number.
5. Commit de Release: `git commit -m "chore(release): prepare release vX.Y.Z"`
6. Creación de Tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z: <resumen>"`
7. Push de rama y tags: `git push origin main --tags`
```
