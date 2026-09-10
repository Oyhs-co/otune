# ADR-006: Use of go_router for Navigation

## Status
Accepted

## Context
The application needs a declarative routing system that supports deep linking and works consistently across mobile and desktop platforms.

## Decision
We will use `go_router` as the routing solution.

## Rationale
- **Declarative**: Routing is defined as a configuration, making it easier to reason about the app's structure.
- **Deep Linking**: Native support for URL-based navigation, which is critical for desktop and web.
- **Integration**: Official package within the Flutter ecosystem.

## Consequences
- Adoption of a specific routing pattern (Navigator 2.0 based).
- Centralization of routes in the `app/routing` layer.
