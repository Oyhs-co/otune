# ADR-001: Flutter as the UI Framework

## Status
Accepted

## Context
Otune requires a high degree of visual customization, support for multiple platforms (Android, Windows, Linux, macOS), and a consistent user experience across them.

## Decision
We will use Flutter 3.47.x as the primary framework for the presentation layer.

## Rationale
- **Code Sharing**: Allows sharing almost 100% of the UI and application logic across platforms.
- **Customization**: Flutter's rendering engine allows for the highly customized, "non-conventional" interfaces planned for future phases (Karaoke, DJ mode).
- **Ecosystem**: Strong support for the required libraries (media_kit, Drift, Riverpod).

## Consequences
- Dependence on the Flutter SDK and Dart language.
- Necessity to handle platform-specific permissions (via `permission_handler`).
