# SPEC: Shuffle Playback

## Status
Proposed

## Context
Users expect to be able to play their music in a random order to avoid the predictability of a fixed queue.

## Goal
Implement a shuffle mechanism that reorders the playback sequence without permanently altering the user's library or the original queue order.

## Scope
- Shuffle logic within the `Playback` application layer.
- Integration with the `Queue` aggregate.
- Toggle for Shuffle mode (On/Off).
- Logic for "Next" track when shuffle is active.

## Non-goals
- Complex randomization algorithms (e.g., avoiding playing the same artist twice in a row).
- Permanent reordering of the physical library.

## User stories
- As a user, I want to enable shuffle mode so that songs are played in a random order.
- As a user, I want to disable shuffle mode to return to the sequential order of my queue.

## Domain rules
- Shuffle should operate on a virtual copy of the queue or a randomized index map to preserve the original order.
- When shuffle is disabled, playback should either continue from the current track in sequential order or return to the original position in the queue.
- Toggling shuffle should not interrupt the currently playing track.

## Functional requirements
- FR-SHUFFLE-001: The system shall allow the user to toggle shuffle mode.
- FR-SHUFFLE-002: When shuffle is ON, the "Next" action shall select a random track from the queue that has not yet been played in the current shuffle cycle.
- FR-SHUFFLE-003: When shuffle is OFF, the "Next" action shall select the track immediately following the current one in the queue.
- FR-SHUFFLE-004: The system shall maintain the shuffle state across session restarts (optional for MVP).

## Non-functional requirements
- NFR-SHUFFLE-001: The randomization process must be computationally efficient (< 10ms).

## Scenarios

### Scenario: Enable Shuffle
Given a queue of 5 songs and song 0 is playing
When the user enables shuffle mode
Then the current song continues playing
And the next song selected will be a random one from the remaining 4

### Scenario: Disable Shuffle
Given shuffle mode is active and song 3 is playing
When the user disables shuffle mode
Then the current song continues playing
And the next song selected will be song 4 (the sequential successor)

## Edge cases
- Queue with only one song: Shuffle has no observable effect.
- Queue with two songs: Shuffle only toggles between the two.
- Empty queue: Shuffle mode remains in its current state but has no tracks to randomize.

## Acceptance criteria
- [ ] AC-SHUFFLE-001: Shuffle mode can be toggled on and off.
- [ ] AC-SHUFFLE-002: With shuffle ON, "Next" selects a random track.
- [ ] AC-SHUFFLE-003: With shuffle OFF, "Next" selects the sequential track.

## Testing strategy
- **Unit**: Test the shuffle algorithm to ensure all tracks in a queue are eventually played before repeating.
- **Integration**: Test the interaction between `ShuffleMode` $\rightarrow$ `Queue` $\rightarrow$ `PlaybackSession`.

## Dependencies
- `SPEC: Queue Management`
- `SPEC: Play Track`

## Related architecture decisions
- DDD: `Playback` Bounded Context.

## Open questions
- Should we use a "true random" or a "shuffled list" approach? (Recommended: Shuffled list to ensure all tracks play once).
