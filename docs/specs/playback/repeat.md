# SPEC: Repeat Playback

## Status
Proposed

## Context
Users want control over what happens when the end of the queue is reached or if they want to hear a specific song multiple times.

## Goal
Implement repeat modes (Off, All, One) to control the playback loop behavior.

## Scope
- Repeat mode logic in the `Playback` application layer.
- Integration with the `Queue` and `AudioEngine` (for track end notification).
- Toggle for Repeat mode (Off $\rightarrow$ All $\rightarrow$ One $\rightarrow$ Off).
- Coordination with the "Next" and "Previous" actions.

## Non-goals
- A-B repeat (looping a specific segment of a song).
- Complex looping scripts.

## User stories
- As a user, I want to repeat a single song indefinitely.
- As a user, I want the entire album/queue to start over once it finishes.
- As a user, I want the music to stop after the last song in the queue.

## Domain rules
- `RepeatMode` can have three states: `Off`, `All`, and `One`.
- If `RepeatMode` is `One`, the "Next" action (or the end of the track) triggers the same track again.
- If `RepeatMode` is `All`, the "Next" action at the end of the queue triggers the first track of the queue.
- If `RepeatMode` is `Off`, the "Next" action at the end of the queue stops playback.

## Functional requirements
- FR-REPEAT-001: The system shall allow the user to cycle through Repeat modes.
- FR-REPEAT-002: When mode is `One`, the system shall restart the current track upon completion.
- FR-REPEAT-003: When mode is `All`, the system shall restart the queue from the beginning upon reaching the end.
- FR-REPEAT-004: When mode is `Off`, the system shall stop playback after the last track.

## Non-functional requirements
- NFR-REPEAT-001: The transition between repeated tracks should be seamless.

## Scenarios

### Scenario: Repeat One
Given a track is playing and `RepeatMode` is set to `One`
When the track finishes
Then the `AudioEngine` loads the same track again
And playback starts from the beginning

### Scenario: Repeat All
Given a queue of 3 songs and song 2 (the last one) is playing, with `RepeatMode` set to `All`
When the track finishes
Then the `AudioEngine` loads song 0
And playback starts

### Scenario: Repeat Off
Given a queue of 3 songs and song 2 is playing, with `RepeatMode` set to `Off`
When the track finishes
Then the playback state changes to `stopped`
And the audio stops

## Edge cases
- Queue with only one song: `Repeat All` and `Repeat One` behave identically.
- Empty queue: Repeat mode remains set but has no effect.

## Acceptance criteria
- [ ] AC-REPEAT-001: Repeat mode can be toggled between Off, All, and One.
- [ ] AC-REPEAT-002: `Repeat One` correctly loops the current track.
- [ ] AC-REPEAT-003: `Repeat All` correctly loops the entire queue.
- [ ] AC-REPEAT-004: `Repeat Off` correctly stops playback at the end of the queue.

## Testing strategy
- **Unit**: Test the `PlaybackSession` logic for track transition based on `RepeatMode`.
- **Integration**: Test the `AudioEngine` "Track Ended" event triggering the correct repeat behavior.

## Dependencies
- `SPEC: Queue Management`
- `SPEC: Play Track`

## Related architecture decisions
- DDD: `Playback` Bounded Context.

## Open questions
- Should we implement "Repeat Folder" (subset of queue)? (Recommended: Not for MVP).
