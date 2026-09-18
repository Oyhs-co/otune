# SPEC: Library Empty States

## Status
In Progress

## Context
When a user first opens Otune or clears their library, they are met with an empty screen. Without guidance, the user may not know how to start adding music.

## Goal
Communicate clearly when the library is empty and provide a direct path to resolve it.

## Scope
- Empty state for the main Library page.
- Empty state for search results.
- Call to Action (CTA) to start scanning.

## Non-goals
- Automatic scanning on first launch (should be user-triggered).
- Integration with cloud services.

## User stories
- As a new user, I want to be told that my library is empty and how to fill it so I can start listening to music.
- As a user searching for a track, I want to know when no results were found for my specific query.

## Domain rules
- DR-001: The empty state should only appear when the filtered track list is truly empty.

## Functional requirements
- FR-001: Show an illustration/icon, a descriptive message, and a 'Scan' button when the library is empty.
- FR-002: Show a 'No results found for [query]' message when a search yields no matches.
- FR-003: The 'Scan' button must trigger the `LibraryScanner`.

## Non-functional requirements
- NFR-001: The empty state should be visually appealing and centered.

## Scenarios

### Scenario: First launch empty library
Given the library contains no tracks
When the user navigates to the Library page
Then a message "Your library is empty" is displayed
And a "Scan for music" button is visible

### Scenario: Search with no results
Given the library has tracks
When the user searches for "NonExistentSong123"
Then a message "No results found for 'NonExistentSong123'" is displayed

## Edge cases
- Library becomes empty during a scan (should transition to empty state if no tracks found).
- Search query consists only of spaces.

## Acceptance criteria
- [ ] AC-001: Library page shows empty state when 0 tracks are present.
- [ ] AC-002: Search results show "no results" message when no tracks match the query.
- [ ] AC-003: The 'Scan' button in empty state correctly initiates the scanning process.

## Testing strategy

### Widget
- Mock `filteredTracksProvider` with empty list -> verify empty state widget is shown.
- Mock `filteredTracksProvider` with tracks but search query that matches nothing -> verify search empty state.
- Verify that clicking the scan button invokes the expected provider action.

## Dependencies
- `filteredTracksProvider`
- `libraryScanProvider`

## Related DDD
- Bounded context: `library`
- Use case: `ViewLibrary`

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-001 | `test/features/library/presentation/library_empty_state_test.dart` | ⬜ |
| AC-002 | `test/features/library/presentation/library_search_empty_test.dart` | ⬜ |
| AC-003 | `test/features/library/presentation/library_scan_trigger_test.dart` | ⬜ |

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-17 | Initial spec | Phase 0 Preparation |
| 2026-09-18 | Status changed to In Progress | Empty and search states are implemented; full widget coverage remains pending |
