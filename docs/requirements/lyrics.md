# Requirements: Lyrics

## Functional Requirements (RF)

### LRC Synchronization
- **RF-LYRICS-001**: The system shall search for a `.lrc` file matching the currently playing track's name in the same folder.
- **RF-LYRICS-002**: The system shall parse the LRC file into a list of `LyricLine` objects (timestamp + text).
- **RF-LYRICS-003**: The system shall provide a stream of the current active lyric line based on the playback position.
- **RF-LYRICS-004**: The system shall handle LRC files with multiple timestamps per line (selecting the first one for MVP).

## Non-Functional Requirements (NRF)
- **NFR-LYRICS-001**: Parsing an LRC file should be near-instantaneous (< 50ms).
- **NFR-LYRICS-002**: The lyric update should happen with low latency relative to the audio position.
