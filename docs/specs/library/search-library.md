# SPEC: Search Library

## Status
Proposed

## Context
As the local library grows, users need a fast way to find specific tracks, artists, or albums without scrolling through long lists.

## Goal
Implement a responsive search mechanism that filters the indexed library in real-time.

## Scope
- Search use case in the `Library` application layer.
- Database queries for partial string matching (LIKE or FTS5).
- UI integration for a search bar.
- Filtering by category (All, Artist, Album, Track).

## Non-goals
- Advanced Boolean search operators (AND, OR, NOT).
- Fuzzy search (approximate matching) in the first version.
- Search in external services.

## User stories
- As a user, I want to type "Queen" and see all songs by the band Queen.
- As a user, I want to search for a specific song title to play it quickly.

## Domain rules
- Search should be case-insensitive.
- Search results should be returned as a stream or list of `Track` entities.
- Empty search queries should return all tracks or no tracks (based on UI preference).

## Functional requirements
- FR-SEARCH-001: The system shall provide a search interface to enter a query string.
- FR-SEARCH-002: The system shall filter tracks where the title contains the query string.
- FR-SEARCH-003: The system shall filter tracks where the artist contains the query string.
- FR-SEARCH-004: The system shall filter tracks where the album contains the query string.
- FR-SEARCH-005: The system shall update results in real-time as the user types (debounced).

## Non-functional requirements
- NFR-SEARCH-001: Search results should be returned in < 100ms for libraries up to 5,000 tracks.
- NFR-SEARCH-002: The UI should not lag while typing (use debouncing).

## Scenarios

### Scenario: Basic track search
Given a library with a song titled "Bohemian Rhapsody"
When the user types "Bohemian" in the search bar
Then the list is filtered to show only "Bohemian Rhapsody"

### Scenario: Artist search
Given a library with several songs by "Daft Punk"
When the user types "Daft"
Then all songs by "Daft Punk" are displayed

### Scenario: No results
Given a library with no songs by "The Beatles"
When the user types "Beatles"
Then the system displays a "No results found" message

## Edge cases
- Special characters in search query: System should handle them without crashing.
- Very long query strings: System should handle them gracefully.
- Searching while a library scan is in progress: Search should reflect the current state of the database.

## Acceptance criteria
- [ ] AC-SEARCH-001: User can search by title, artist, and album.
- [ ] AC-SEARCH-002: Results update dynamically as the user types.
- [ ] AC-SEARCH-003: Search is case-insensitive.
- [ ] AC-SEARCH-004: "No results" state is handled correctly in the UI.

## Testing strategy
- **Unit**: Test the database query logic with various keywords.
- **Widget**: Test the search bar integration and result filtering.

## Dependencies
- `SPEC: Scan Library`
- `drift`

## Related architecture decisions
- DDD: `Library` Bounded Context.

## Open questions
- Should we use SQLite FTS5 for full-text search immediately or start with simple `LIKE` queries? (Recommended: `LIKE` for MVP, FTS5 as an optimization).
