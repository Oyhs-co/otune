# SPEC: Integrated Lyrics Experience

## Context
The application has a functional lyrics synchronization system and a `NowPlayingPage`, but the lyrics are not integrated into the user interface. The goal is to make lyrics a first-class citizen of the playback experience.

## Problem
Users cannot see the lyrics of the currently playing track while in the `NowPlayingPage`, and the existing `LyricsWidget` lacks essential playback features like auto-scrolling and interaction.

## Observable Goal
The user should be able to switch between the track artwork and the synchronized lyrics in the `NowPlayingPage`. The lyrics should automatically scroll to follow the music and allow the user to jump to specific parts of the song by tapping a line.

## Scope
- Integration of `LyricsWidget` into `NowPlayingPage`.
- Implementation of auto-scrolling in `LyricsWidget`.
- Implementation of "tap to seek" functionality in `LyricsWidget`.
- Improvement of the "No lyrics available" state.

## Non-Scope
- Remote lyrics fetching.
- Editing lyrics.
- Embedding lyrics in files.

## User Stories
- **As a user**, I want to switch to a lyrics view from the `NowPlayingPage` so I can follow the song.
- **As a user**, I want the lyrics to automatically scroll so I don't have to manually scroll while listening.
- **As a user**, I want to tap on a line of lyrics to jump the playback to that specific timestamp.

## Functional Requirements
1. **Navigation:** The `NowPlayingPage` must provide a way to toggle between the Artwork view and the Lyrics view.
2. **Synchronization:** The `LyricsWidget` must observe the `lyricsSyncProvider` and the current playback position.
3. **Auto-scroll:** The list of lyrics must automatically scroll to keep the active line centered or visible.
4. **Interactive Lyrics:** Tapping a lyric line must invoke the `seek` method of the `PlaybackController`.
5. **Empty State:** If no lyrics are found, a visually pleasant "No lyrics available" state must be shown.

## Scenarios

### Scenario: Switching to lyrics
- **Given** a track is playing in `NowPlayingPage`
- **When** the user switches to the lyrics view
- **Then** the `LyricsWidget` is displayed
- **And** the current active line is highlighted.

### Scenario: Auto-scrolling
- **Given** lyrics are being displayed
- **When** the playback position changes and a new line becomes active
- **Then** the list scrolls automatically to bring the new active line into view.

### Scenario: Jump to timestamp
- **Given** lyrics are being displayed
- **When** the user taps on a line with timestamp `01:30`
- **Then** the player seeks to `01:30`
- **And** that line becomes the active line.

## Acceptance Criteria
- [ ] User can switch between artwork and lyrics in `NowPlayingPage`.
- [ ] Active lyric line is visually distinct.
- [ ] List scrolls automatically as the song progresses.
- [ ] Tapping a line seeks the player to the correct position.
- [ ] "No lyrics" state is displayed when no LRC is found.
- [ ] The transition between views is smooth.

## Dependencies and Risks
- **Dependency:** `playbackControllerProvider` for seeking.
- **Dependency:** `lyricsSyncProvider` for state.
- **Risk:** Performance issues with `ListView` and frequent scrolling updates.
