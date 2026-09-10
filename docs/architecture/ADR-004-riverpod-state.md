# ADR-004: Riverpod 3 for State Management

## Status
Accepted

## Context
Otune needs a reactive state management system that handles dependency injection, supports asynchronous data streams (from Drift and AudioEngine), and is easily testable.

## Decision
We will use `flutter_riverpod` (version 3.x) as the primary state management and DI solution.

## Rationale
- **Composition**: Allows breaking the app into small, focused providers.
- **Reactivity**: Excellent integration with Dart Streams and FutureProviders.
- **Testability**: Providers can be easily overridden in tests.
- **Architecture**: Aligns well with the Application/Domain separation.

## Consequences
- Requirement to wrap the app in a `ProviderScope`.
- Learning curve for developers unfamiliar with the Riverpod paradigm.
