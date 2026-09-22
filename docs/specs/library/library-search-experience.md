# SPEC: Library Search Experience

## Status
Implemented

## Goal
Allow users to find local tracks quickly and reset the query without leaving the Library.

## Scope
- Case-preserving search input with real-time filtering.
- Whitespace normalization.
- Clear action.
- Contextual actions to play next or add to queue.
- Explicit no-results state.

## Non-goals
- Remote search.
- Fuzzy search or Boolean operators.
- Album and artist navigation without domain support.

## Scenarios

### Scenario: Clear a search
Given the user has entered a search query
When the user activates clear
Then the query becomes empty
And the complete library is shown again

### Scenario: Search with surrounding spaces
Given the user enters a query with surrounding spaces
When the query changes
Then filtering uses the trimmed query

## Acceptance criteria
- [x] Search updates as the user types.
- [x] Empty and whitespace-only queries show the unfiltered library.
- [x] A clear action is visible when the query is non-empty.
- [x] No-results state includes the active query.
- [x] Track actions expose play-next and add-to-queue.

## Testing strategy
- Provider tests for empty and non-empty queries.
- Widget tests for empty states and track actions.
