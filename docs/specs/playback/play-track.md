# SPEC: Play Track

## Status
Implemented

## Context
The user needs to be able to load a local audio file and control its playback (play, pause, seek) within the application. This is the fundamental capability of the entire music player.

## Goal
Provide a reliable mechanism to trigger audio playback of a local file and manage its state.

## Scope
- Interface for audio engine (`AudioEngine`).
- Concrete implementation using `media_kit` (`MediaKitAudioEngine`).
- Use case for playing a track.
- Basic playback controls (Play, Pause, Seek).
- Observable playback state (Playing, Paused, Stopped, Position).

## Non-goals
- Playlists or complex queue management (handled in `SPEC: Queue`).
- Audio effects or EQ.
- Network streaming.
- Advanced metadata extraction (handled in `SPEC: Scan Library`).

## User stories
- As a user, I want to select a song and hear it playing.
- As a user, I want to pause the music so I can resume it later.
- As a user, I want to move to a specific part of the song.

## Domain rules
- A track must have a valid local URI/path to be played.
- Only one track can be active in the `PlaybackSession` at a time.
- The `AudioEngine` must be agnostic of the UI.

## Functional requirements
- FR-PLAY-001: The system shall load an audio file from a local path.
- FR-PLAY-002: The system shall start playback from the current position.
- FR-PLAY-003: The system shall pause current playback.
- FR-PLAY-004: The system shall seek to a specific duration within the track.
- FR-PLAY-005: The system shall provide a stream of the current playback position.
- FR-PLAY-006: The system shall notify when a track has finished playing.

## Non-functional requirements
- NFR-PLAY-001: Audio playback should start within < 500ms of the request.
- NFR-PLAY-002: The `AudioEngine` interface must allow swapping `media_kit` for another engine without changing the application layer.

## Scenarios

### Scenario: Start playback
Given a valid local audio file path
When the user triggers the "Play" action
Then the `AudioEngine` loads the file
And the audio starts playing
And the state changes to `playing`

### Scenario: Pause playback
Given a track is currently playing
When the user triggers the "Pause" action
Then the `AudioEngine` pauses the stream
And the state changes to `paused`

### Scenario: Seek to position
Given a track is loaded
When the user moves the seek bar to 01:30
Then the `AudioEngine` updates the playback position to 90 seconds
And playback continues (if it was playing)

## Edge cases
- File not found or inaccessible: System should return a `PlaybackError`.
- Unsupported audio format: System should return an `UnsupportedFormatException`.
- Interrupted playback (e.g., system call): Engine should update state to `paused` or `stopped`.

## Acceptance criteria
- [x] AC-PLAY-001: A local file can be loaded and played successfully.
- [x] AC-PLAY-002: Pause and Play functions correctly toggle the audio stream.
- [x] AC-PLAY-003: Seeking changes the playback position accurately.
- [x] AC-PLAY-004: The UI can observe and reflect the current position and state.

## Testing strategy
- **Unit**: Test `PlaybackSession` logic and `AudioEngine` interface mocks.
- **Integration**: Test `MediaKitAudioEngine` with real local files on target platforms.
- **Widget**: Test that the Play/Pause buttons trigger the correct application services.

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-PLAY-001 | `test/features/playback/application/playback_controller_test.dart` | ✅ |
| AC-PLAY-002 | `test/features/playback/presentation/player_widget_test.dart` | ✅ |
| AC-PLAY-003 | `test/features/playback/domain/audio_engine_test.dart` | ✅ |
| AC-PLAY-004 | `test/features/playback/presentation/player_widget_test.dart`, `test/widget_test.dart` | ✅ |

## Dependencies
- `media_kit`
- `media_kit_libs_audio`

## Related architecture decisions
- ADR: Use of `AudioEngine` as an abstraction layer.
- DDD: `Playback` Bounded Context.

## Open questions
- Should the engine handle audio focus (e.g., pausing when another app plays)? (Recommended: Yes, but may be a separate spec).
