# ADR-002: Use of media_kit as the Initial Audio Engine

## Status
Accepted

## Context
The application needs a cross-platform audio playback engine that is efficient and supports a wide range of formats and platforms.

## Decision
We will use `media_kit` as the initial implementation for audio playback.

## Rationale
- **Platform Support**: Native support for Android, iOS, Windows, macOS, Linux, and Web.
- **Performance**: Based on MPV, providing high-performance playback and wide codec support.
- **Modular Architecture**: Its design allows for a clean separation between the player and the UI.

## Consequences
- Reliance on the `media_kit` and `media_kit_libs_audio` packages.
- Introduction of FFI (Foreign Function Interface) dependencies.
