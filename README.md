# Otune

Reproductor musical multiplataforma, offline-first y extensible, diseñado para usuarios que prefieren gestionar sus propias bibliotecas de audio locales.

Version: 0.4.0-alpha.1+19

## Caracteristicas del MVP

- Biblioteca Local: Escaneo recursivo de directorios, extracción de metadatos y persistencia eficiente con SQLite/Drift.
- Reproduccion Avanzada: Motor de audio desacoplado basado en media_kit para alta fidelidad y baja latencia.
- Letras Sincronizadas: Soporte nativo para archivos .lrc con resaltado de linea activa en tiempo real.
- Personalizacion: Sistema de temas dinamico (Claro/Oscuro/Sistema).

## Stack Tecnologico

- Framework: Flutter
- Estado y DI: Riverpod
- Persistencia: Drift (SQLite)
- Audio Engine: media_kit
- Navegacion: go_router
- Calidad: very_good_analysis & mocktail

## Arquitectura

Otune sigue una arquitectura modular basada en Domain-Driven Design (DDD) y Spec-Driven Development (SDD):

- Domain: Entidades y contratos puros.
- Application: Casos de uso y gestion de estado.
- Data: Implementaciones concretas y acceso a datos.
- Presentation: UI reactiva y componentes desacoplados.

Consulta la documentacion detallada en la carpeta docs/.

## Instalacion y Desarrollo

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```
