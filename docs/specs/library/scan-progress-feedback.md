# SPEC: Scan Progress Feedback

## Status
In Progress

## Context
Scanning a local filesystem for music can take significant time. Currently, the user might not have enough feedback on whether the app is frozen or actively working, and how many files have been processed.

## Goal
Provide real-time, non-blocking feedback during the library scan process.

## Scope
- Progress banner/panel during scanning.
- Counter of processed files.
- Display of the current file being processed (with safe truncation).
- Summary of scan results upon completion, including skipped files.
- Error handling for individual files vs critical directory errors.

## Non-goals
- Implementation of a detailed log window (keep it a summary banner).
- Modification of the `LibraryScanner` core logic (only consuming its state).

## User stories
- As a user, I want to see how many songs have been found so far so I know the scan is progressing.
- As a user, I want to see which folder/file is being scanned so I know where the app is.
- As a user, I want to be notified when the scan is finished.

## Domain rules
- DR-001: The scan progress must be driven by the `libraryScanProvider`.
- DR-002: Errors in individual files should be logged but should not stop the overall scan.

## Functional requirements
- FR-001: Display a banner at the top of the library when scanning is active.
- FR-002: Show "Scanning: [X] files processed".
- FR-003: Show the current file path, truncated if it exceeds the available width.
- FR-004: Show a "Scan complete: [X] tracks added" summary that disappears after a few seconds or on user action.
- FR-005: Distinguish between a "File Error" (skipped) and a "Critical Error" (scan stopped).
- FR-006: A critical scan error exposes a retry action for the last selected directory.

## Non-functional requirements
- NFR-001: The progress banner should not block the user from browsing already indexed tracks.

## Scenarios

### Scenario: Start scanning
Given the user clicks the 'Scan' button
When the scan starts
Then a banner appears showing "Scanning: 0 files processed"
And the banner updates as files are found

### Scenario: Scan completion
Given a scan is in progress
When the scanner finishes
Then the banner changes to "Scan complete: 120 tracks added"
And the banner fades out after 5 seconds

### Scenario: Individual file error
Given a scan is in progress
When the scanner encounters a corrupt MP3 file
Then the scan continues to the next file
And a non-intrusive error indicator is shown (or logged)

## Edge cases
- Scan interrupted by user (if implemented) or app crash.
- Scanning a directory with millions of files (ensure UI doesn't lag).

## Acceptance criteria
- [ ] AC-001: Scan progress banner is visible during scanning.
- [ ] AC-002: File counter updates in real-time.
- [ ] AC-003: Current file path is displayed with safe truncation.
- [ ] AC-004: Completion summary is shown and then dismissed.
- [ ] AC-005: Critical errors show a retry action.

## Testing strategy

### Widget
- Mock `libraryScanProvider` state to `scanning` -> verify banner visibility.
- Mock state updates for file count -> verify text updates.
- Mock state to `completed` -> verify summary display.
- Mock state to `error` -> verify error display and retry button.

## Dependencies
- `libraryScanProvider`

## Related DDD
- Bounded context: `library`
- Use case: `ScanLibrary`

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-001 | `test/features/library/presentation/scan_banner_test.dart` | ⬜ |
| AC-002 | `test/features/library/presentation/scan_counter_test.dart` | ⬜ |
| AC-003 | `test/features/library/presentation/scan_path_test.dart` | ⬜ |
| AC-004 | `test/features/library/presentation/scan_summary_test.dart` | ⬜ |
| AC-005 | `test/features/library/presentation/scan_error_test.dart` | ⬜ |

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-17 | Initial spec | Phase 0 Preparation |
| 2026-09-18 | Status changed to In Progress | Partial implementation now distinguishes file and critical errors |
