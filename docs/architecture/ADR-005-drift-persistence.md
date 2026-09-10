# ADR-005: Drift/SQLite for Local Persistence

## Status
Accepted

## Context
The application is "offline-first" and needs to store a potentially large library of tracks, albums, and artists with complex relationships and fast search capabilities.

## Decision
We will use `drift` (formerly moor) as the persistence layer over SQLite.

## Rationale
- **Type Safety**: Provides a type-safe Dart API for SQL queries.
- **Reactivity**: Supports streams of queries, allowing the UI to update automatically when the DB changes.
- **Features**: Supports migrations, indices, and FTS5 (Full Text Search) for library searching.
- **Multiplatform**: SQLite is industry-standard and supported across all target platforms.

## Consequences
- Need to run `build_runner` for code generation.
- Requirement to manage SQL migrations as the schema evolves.
