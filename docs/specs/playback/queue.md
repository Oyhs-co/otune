# SPEC: Queue Management

## Status
Implemented

## Context
A music player needs to handle a sequence of tracks to be played, allowing the user to organize their listening experience without manual selection for every song.

## Goal
Implement a robust queue system that manages the order of tracks, supports additions/removals, and coordinates with the `AudioEngine` for seamless transitions.

## Scope
- `Queue` aggregate and `QueueItem` entity.
- Use cases for:
    - Adding tracks to the queue.
    - Removing tracks from the queue.
    - Moving tracks within the queue.
    - Clearing the queue.
- Logic for "Next" and "Previous" track navigation.
- Coordination between the `Queue` and `PlaybackSession`.

## Non-goals
- Smart playlists based on AI.
- Collaborative queues.
- Complex sorting (e.g., by BPM).

## User stories
- As a user, I want to add a song to the end of my current queue.
- As a user, I want to skip to the next song in the list.
- As a user, I want to remove a song I no longer want to hear from the queue.

## Domain rules
- The queue must maintain a pointer to the `currentIndex`.
- Moving to "Next" from the last item depends on the `RepeatMode` (Repeat All vs Repeat Off).
- Adding a track must not interrupt current playback unless specified (e.g., "Play Next").

## Functional requirements
- FR-QUEUE-001: The system shall allow adding a single track or a list of tracks to the end of the queue.
- FR-QUEUE-002: The system shall allow adding a track to the "Play Next" position.
- FR-QUEUE-003: The system shall allow removing a specific track by ID.
- FR-QUEUE-004: The system shall provide a "Skip Next" function that loads the next `QueueItem`.
- FR-QUEUE-005: The system shall provide a "Skip Previous" function.
- FR-QUEUE-006: The system shall allow clearing all items from the queue.

## Non-functional requirements
- NFR-QUEUE-001: Queue operations (add/remove) should be near-instantaneous (< 100ms).
- NFR-QUEUE-002: The queue state should be persistable (optional for MVP, but recommended).

## Scenarios

### Scenario: Add to end
Given a queue with 3 songs
When the user adds a new song to the queue
Then the queue now contains 4 songs
And the new song is at the last position

### Scenario: Skip to next
Given a queue with 2 songs and the first is playing
When the user clicks "Next"
Then the first song stops
And the second song starts playing
And the `currentIndex` increments to 1

### Scenario: Play Next
Given a queue with 3 songs and song 0 is playing
When the user adds song X to "Play Next"
Then song X is inserted at position 1
And song 1 is moved to position 2

## Edge cases
- Skipping next when the queue is empty: System should do nothing or show an error.
- Skipping next when at the end of the queue: Handle based on `RepeatMode`.
- Removing the currently playing track: System should either stop or automatically move to the next track.

## Acceptance criteria
- [ ] AC-QUEUE-001: Tracks can be added to the end and "Play Next".
- [ ] AC-QUEUE-002: "Next" and "Previous" correctly navigate the queue.
- [ ] AC-QUEUE-003: Tracks can be removed without breaking the queue index.
- [ ] AC-QUEUE-004: The queue correctly triggers the `AudioEngine` to load the new track.

## Testing strategy
- **Unit**: Extensive tests for the `Queue` aggregate (adding, removing, indexing).
- **Integration**: Test the flow from `Queue` $\rightarrow$ `PlaybackSession` $\rightarrow$ `AudioEngine`.

## Dependencies
- `SPEC: Play Track`

## Related architecture decisions
- DDD: `Playback` Bounded Context, `Queue` Aggregate.

## Open questions
- Should we support "Queue as a Playlist" (saved) or only volatile session queues?

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-QUEUE-001 | `test/features/playback/domain/queue_test.dart` | ✅ |
| AC-QUEUE-002 | `test/features/playback/domain/queue_test.dart` and `playback_controller_test.dart` | ✅ |
| AC-QUEUE-003 | `test/features/playback/domain/queue_test.dart` | ✅ |
| AC-QUEUE-004 | `test/features/playback/application/playback_controller_test.dart` | ✅ |
