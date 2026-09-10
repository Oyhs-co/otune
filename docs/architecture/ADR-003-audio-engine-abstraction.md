# ADR-003: Abstraction of Audio Engine via AudioEngine Interface

## Status
Accepted

## Context
To avoid vendor lock-in with `media_kit` and to allow for future specialized audio engines (e.g., a Rust-based engine for DJ/DSP features), the domain must not depend on a specific library's API.

## Decision
Define a stable `AudioEngine` interface (port) in the Domain layer. All specific playback libraries (like `media_kit`) will be implemented as adapters.

## Rationale
- **Decoupling**: The application and domain layers remain agnostic of the underlying audio technology.
- **Extensibility**: Allows swapping or augmenting the audio engine without modifying business logic.
- **Testability**: Simplifies mocking audio playback in unit tests.

## Consequences
- Slight increase in boilerplate due to the introduction of an abstraction layer.
- Requirement to map `media_kit` specific states/errors to domain-specific types.
