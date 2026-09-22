# SPEC: Adaptive Queue

## Status
Implemented

## Goal
Make the playback queue usable on narrow and wide screens while keeping all mutations in `PlaybackController`.

## Scope
- Bottom sheet on narrow screens.
- Bounded dialog surface on wide screens.
- Empty queue action back to Library.
- Current-track and upcoming-queue labels.
- Reordering, removal and clearing with undo feedback.

## Non-goals
- Persisting the queue between launches.
- Saved playlists or collaborative queues.

## Scenarios

### Scenario: Open queue on a wide screen
Given a track is playing on a wide screen
When the user opens the queue
Then a bounded queue surface is displayed
And playback continues

### Scenario: Undo removal
Given the queue contains a track
When the user removes that track
Then the track disappears
And an undo action restores it at its previous position

### Scenario: Empty queue
Given the queue has no items
When the user opens the queue
Then an empty state is shown
And the user can return to the library

## Acceptance criteria
- [x] Mobile uses a draggable bottom sheet.
- [x] Wide layouts use a bounded dialog surface.
- [x] Removing an item exposes undo.
- [x] Clearing the queue exposes undo.
- [x] Queue mutations preserve the current playback source of truth.

## Testing strategy
- Unit tests for queue insertion after removal.
- Widget tests for empty and populated queue surfaces.
- Controller tests for queue restoration.

## Related architecture decisions
- ADR-008-adaptive-app-shell.md
