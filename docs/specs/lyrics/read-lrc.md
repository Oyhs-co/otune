# SPEC: Read LRC Lyrics

## Status
Proposed

## Context
The application needs to support synchronized lyrics using the LRC format, allowing users to follow the words of a song in real-time.

## Goal
Implement a system to locate, parse, and synchronize LRC files with the current playback position.

## Scope
- `LyricsRepository` port and `LocalLyricsRepository` adapter.
- LRC parser (converting timestamps and text into a structured list).
- Synchronization logic that matches the `AudioEngine` current position to the nearest lyric line.
- Mapping between `Track` and its associated `.lrc` file.

## Non-goals
- Editing LRC files (handled in `Lyrics Studio` phase).
- Fetching lyrics from online APIs (handled in future phases).
- Word-by-word synchronization (only line-by-line for MVP).

## User stories
- As a user, I want to see the lyrics of a song change as the music plays.
- As a user, I want the app to automatically find the `.lrc` file if it has the same name as the audio file.

## Domain rules
- An LRC file consists of timestamps `[mm:ss.xx]` followed by the lyric text.
- Timestamps must be sorted chronologically.
- Lyrics are associated with a `Track` via a file naming convention or a database link.
- The "active" lyric line is the one whose timestamp is the largest value less than or equal to the current playback position.

## Functional requirements
- FR-LYRICS-001: The system shall search for a `.lrc` file matching the currently playing track's name in the same folder.
- FR-LYRICS-002: The system shall parse the LRC file into a list of `LyricLine` objects (timestamp + text).
- FR-LYRICS-003: The system shall provide a stream of the current active lyric line based on the playback position.
- FR-LYRICS-004: The system shall handle LRC files with multiple timestamps per line (selecting the first one for MVP).

## Non-functional requirements
- NFR-LYRICS-001: Parsing an LRC file should be near-instantaneous (< 50ms).
- NFR-LYRICS-002: The lyric update should happen with low latency relative to the audio position.

## Scenarios

### Scenario: Auto-load lyrics
Given a track "Song.mp3" is playing
And a file "Song.lrc" exists in the same directory
When the track starts
Then the system loads "Song.lrc"
And the lyrics are ready for display

### Scenario: Synchronized display
Given lyrics are loaded and the current playback position is 00:15.50
When the LRC contains a line at `[00:12.00] Hello` and `[00:18.00] World`
Then the active lyric line is "Hello"

### Scenario: No lyrics found
Given a track is playing but no matching `.lrc` file exists
When the lyrics system attempts to load
Then it returns a "No lyrics available" state
And the UI displays a placeholder or nothing

## Edge cases
- LRC file with malformed timestamps: Parser should skip the line or use a default.
- LRC file larger than the audio track: The system should simply stop displaying lines once the audio ends.
- Empty LRC file: Handle as "No lyrics available".

## Acceptance criteria
- [ ] AC-LYRICS-001: `.lrc` files are correctly located and parsed.
- [ ] AC-LYRICS-002: The active lyric line updates accurately as the song progresses.
- [ ] AC-LYRICS-003: The system gracefully handles missing or corrupt lyric files.

## Testing strategy
- **Unit**: Test the LRC parser with various valid and invalid LRC files.
- **Integration**: Test the synchronization loop between `AudioEngine.position` and `LyricsSync`.

## Dependencies
- `SPEC: Play Track` (for position stream)
- `path_provider`

## Related architecture decisions
- DDD: `Lyrics` Bounded Context.

## Open questions
- Should we support embedded lyrics (ID3 unsynchronized)? (Recommended: Not for MVP, but consider for future).
