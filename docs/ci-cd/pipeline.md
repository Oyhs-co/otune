# CI/CD Pipeline - Otune

Este documento describe la implementación de la integración y entrega continua para el proyecto Otune.

## Flujo de Trabajo (Workflow)

El proyecto utiliza **GitHub Actions** para garantizar que cada cambio integrado en la rama `main` cumpla con los estándares de calidad definidos en `AGENTS.md`.

### Pipeline de Integración Continua (CI)
El archivo `.github/workflows/ci.yml` se dispara en cada `push` o `pull_request` a `main`. Los pasos ejecutados son:

1. **Entorno**: Configuración de Flutter (Stable Channel).
2. **Dependencias**: Ejecución de `flutter pub get` en el directorio `frontend/`.
3. **Generación**: Ejecución de `build_runner` para generar el código de Drift y otras dependencias.
4. **Calidad**: Ejecución de `flutter analyze` para validar el cumplimiento de las reglas de linting (`very_good_analysis`).
5. **Verificación**: Ejecución de `flutter test` para asegurar que ninguna regresión haya sido introducida.

## Criterios de Aceptación para Merge
Para que un cambio sea integrado a la rama principal, debe cumplir:
- ✅ Pipeline de CI exitoso (Analyze & Test).
- ✅ Registro del cambio en `CHANGELOG.md` bajo `[Unreleased]`.
- ✅ Cumplimiento de la arquitectura modular (Domain $\rightarrow$ Application $\rightarrow$ Data).
- ✅ Verificación de los criterios de aceptación de la SPEC correspondiente.

## Próximas Mejoras (CD)
- Implementación de despliegue automatizado para versiones `beta` y `rc`.
- Generación automática de artefactos `.apk` y `.exe`.
