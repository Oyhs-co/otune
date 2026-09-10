# SPEC: Scan Library

## Status
Proposed

## Context
The user has music files scattered in local directories. To play them, the application must first find them, extract their metadata, and index them in a local database for fast access.

## Goal
Implement a system that scans local directories, identifies supported audio files, and populates the library database.

## Scope
- `LibraryScanner` port and `FileSystemLibraryScanner` adapter.
- Metadata extraction (Title, Artist, Album, etc.) from files.
- Persistence of discovered tracks using `Drift`.
- Handling of folder permissions.
- Basic deduplication based on file path.

## Non-goals
- Automatic tagging/correction of metadata using online APIs (e.g., MusicBrainz).
- Support for non-audio files in the scan.
- Cloud-based scanning.

## User stories
- As a user, I want to select a folder and have all my songs added to the library.
- As a user, I want the app to remember my songs so I don't have to scan every time.

## Domain rules
- A track is uniquely identified by its local path (or a generated `TrackIdentity`).
- Scanning should be non-blocking (asynchronous).
- Only supported file extensions (e.g., .mp3, .flac, .wav, .m4a) are indexed.

## Functional requirements
- FR-LIB-001: The system shall allow the user to select one or more directories for scanning.
- FR-LIB-002: The system shall recursively scan selected directories for audio files.
- FR-LIB-003: The system shall extract metadata (ID3, Vorbis, etc.) from each file.
- FR-LIB-004: The system shall store discovered tracks, albums, and artists in the local database.
- FR-LIB-005: The system shall notify the user of the scanning progress (e.g., "Scanning file 10/100").
- FR-LIB-006: The system shall avoid creating duplicate entries for the same file path.

## Non-functional requirements
- NFR-LIB-001: Scanning should not freeze the UI.
- NFR-LIB-002: Database inserts should be batched to optimize performance during large scans.

## Scenarios

### Scenario: Successful scan
Given a folder containing 10 MP3 files with valid tags
When the user starts a scan of that folder
Then the system finds 10 files
And 10 tracks are inserted into the database
And the user sees a "Scan Complete" message

### Scenario: Unsupported files
Given a folder containing 5 MP3s and 2 TXT files
When the user starts a scan
Then the system indexes only the 5 MP3s
And ignores the TXT files

### Scenario: Re-scanning a folder
Given a library that already contains tracks from folder A
When the user scans folder A again
Then the system updates metadata for existing files
And adds any new files found
And does not create duplicates

## Edge cases
- Folders with no read permissions: System should log a warning and skip the folder.
- Corrupt audio files: System should skip the file and log the error.
- Extremely large libraries (10k+ songs): Ensure the scanner doesn't crash the app or exceed memory limits.

## Acceptance criteria
- [ ] AC-LIB-001: Local folders can be selected and scanned.
- [ ] AC-LIB-002: Audio files are correctly identified and filtered.
- [ ] AC-LIB-003: Metadata is correctly extracted and persisted in Drift.
- [ ] AC-LIB-004: No duplicate tracks are created for the same path.

## Testing strategy
- **Unit**: Test metadata parser with various file samples.
- **Integration**: Test the `FileSystemLibraryScanner` with a mock directory structure.
- **Database**: Verify that Drift inserts the correct number of records.

## Dependencies
- `drift`
- `path_provider`
- `file_picker`

## Related architecture decisions
- DDD: `Library` Bounded Context.
- Infrastructure: `Drift` as the primary persistence layer.

## Open questions
- Should we implement "Watch Folder" (automatic scan on change)? (Recommended: Not for MVP).
