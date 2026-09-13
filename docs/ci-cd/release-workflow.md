# Workflow de Release - Android

Este documento describe la configuración y el funcionamiento del pipeline de despliegue definido en `.github/workflows/release.yml`.

## Funcionamiento del Pipeline

El workflow de release es de tipo **manual** (`workflow_dispatch`), lo que permite al equipo de desarrollo controlar exactamente cuándo se genera un artefacto de distribución.

### Entornos de Compilacion

Al ejecutar el workflow, el usuario debe seleccionar uno de los siguientes entornos:

1. **Debug**:
   - Compila la aplicación en modo debug.
   - No requiere firma digital.
   - Ideal para pruebas rápidas en dispositivos físicos.

2. **Staging**:
   - Compila la aplicación en modo release.
   - Utiliza la firma digital configurada en los Secrets de GitHub.
   - Destinado a pruebas de QA y validacion del MVP.

3. **Prod**:
   - Compila la aplicación en modo release.
   - Utiliza la firma digital de produccion.
   - Versión final destinada al usuario final.

## Proceso Tecnico de Ejecucion

El pipeline sigue estos pasos secuenciales:

1. **Preparacion**: Instalacion de Flutter y dependencias (`flutter pub get`).
2. **Generacion**: Ejecucion de `build_runner` para asegurar que los modelos de Drift estan actualizados.
3. **Firma (Solo Staging/Prod)**: 
   - Decodifica el secret `KEYSTORE_BASE64` y lo escribe como un archivo `.jks` en el sistema de archivos temporal del runner.
   - Inyecta las contraseñas de la llave mediante variables de entorno.
4. **Compilacion**: Ejecucion de `flutter build apk --release` (o `--debug`).
5. **Entrega**: El APK generado se sube como un artefacto de GitHub Actions bajo el nombre `otune-apk-[entorno]`.

## Requisitos de Seguridad

Para que este pipeline funcione, el repositorio debe tener configurados los siguientes **GitHub Secrets**:

- `KEYSTORE_BASE64`: El archivo `.jks` convertido a cadena Base64.
- `KEYSTORE_PASSWORD`: Contraseña del almacen de llaves.
- `KEY_ALIAS`: Alias de la llave de firma.
- `KEY_PASSWORD`: Contraseña de la llave privada.

## Relacion con el Versionado
Antes de ejecutar este workflow para un release de Prod, es obligatorio:
1. Actualizar la version en `frontend/pubspec.yaml`.
2. Cerrar la seccion `[Unreleased]` en el `CHANGELOG.md`.
3. Hacer commit y push de los cambios.
