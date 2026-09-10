# Requirements: Library

## Functional Requirements (RF)

### Library Scanning
- **RF-LIB-001**: The system shall allow the user to select one or more directories for scanning.
- **RF-LIB-002**: The system shall recursively scan selected directories for audio files.
- **RF-LIB-003**: The system shall extract metadata (Title, Artist, Album, etc.) from each file.
- **RF-LIB-004**: The system shall store discovered tracks, albums, and artists in the local database.
- **RF-LIB-005**: The system shall notify the user of the scanning progress.
- **RF-LIB-006**: The system shall avoid creating duplicate entries for the same file path.

### Library Search
- **RF-SEARCH-001**: The system shall provide a search interface to enter a query string.
- **RF-SEARCH-002**: The system shall filter tracks where the title contains the query string.
- **RF-SEARCH-003**: The system shall filter tracks where the artist contains the query string.
- **RF-SEARCH-004**: The system shall filter tracks where the album contains the query string.
- **RF-SEARCH-005**: The system shall update results in real-time as the user types (debounced).

## Non-Functional Requirements (NRF)
- **NFR-LIB-001**: Scanning should not freeze the UI (Asynchronous).
- **NFR-LIB-002**: Database inserts should be batched to optimize performance during large scans.
- **NFR-SEARCH-001**: Search results should be returned in < 100ms for libraries up to 5,000 tracks.
- **NFR-SEARCH-002**: The UI should not lag while typing.
