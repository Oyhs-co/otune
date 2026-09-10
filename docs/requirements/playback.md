# Requirements: Playback

## Functional Requirements (RF)

### Playback Control
- **RF-PLAY-001**: The system shall load an audio file from a local path.
- **RF-PLAY-002**: The system shall start playback from the current position.
- **RF-PLAY-003**: The system shall pause current playback.
- **RF-PLAY-004**: The system shall seek to a specific duration within the track.
- **RF-PLAY-005**: The system shall provide a stream of the current playback position.
- **RF-PLAY-006**: The system shall notify when a track has finished playing.

### Queue Management
- **RF-QUEUE-001**: The system shall allow adding a single track or a list of tracks to the end of the queue.
- **RF-QUEUE-002**: The system shall allow adding a track to the "Play Next" position.
- **RF-QUEUE-003**: The system shall allow removing a specific track by ID.
- **RF-QUEUE-004**: The system shall provide a "Skip Next" function that loads the next `QueueItem`.
- **RF-QUEUE-005**: The system shall provide a "Skip Previous" function.
- **RF-QUEUE-006**: The system shall allow clearing all items from the queue.

### Shuffle Logic
- **RF-SHUFFLE-001**: The system shall allow the user to toggle shuffle mode.
- **RF-SHUFFLE-002**: When shuffle is ON, the "Next" action shall select a random track from the queue that has not yet been played in the current shuffle cycle.
- **RF-SHUFFLE-003**: When shuffle is OFF, the "Next" action shall select the track immediately following the current one in the queue.
- **RF-SHUFFLE-004**: The system shall maintain the shuffle state across session restarts.

### Repeat Logic
- **RF-REPEAT-001**: The system shall allow the user to cycle through Repeat modes (Off, All, One).
- **RF-REPEAT-002**: When mode is `One`, the system shall restart the current track upon completion.
- **RF-REPEAT-003**: When mode is `All`, the system shall restart the queue from the beginning upon reaching the end.
- **RF-REPEAT-004**: When mode is `Off`, the system shall stop playback after the last track.

## Non-Functional Requirements (NRF)
- **NFR-PLAY-001**: Audio playback should start within < 500ms of the request.
- **NFR-PLAY-002**: The `AudioEngine` interface must allow swapping the playback library without changing the application layer.
- **NFR-QUEUE-001**: Queue operations (add/remove) should be near-instantaneous (< 100ms).
- **NFR-QUEUE-002**: The queue state should be persistable.
- **NFR-SHUFFLE-001**: The randomization process must be computationally efficient (< 10ms).
- **NFR-REPEAT-001**: The transition between repeated tracks should be seamless.
