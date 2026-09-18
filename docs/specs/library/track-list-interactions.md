# SPEC: Track List Interactions

## Status
Implemented

## Goal
Make common track actions available directly from list, detailed and grid views.

## Scope
- Play a track by tapping it.
- Add to queue.
- Play next.
- Active-track visual and semantic distinction.
- Artwork fallback in every view.

## Acceptance criteria
- [x] All library view modes expose track selection.
- [x] Contextual track actions use the playback controller.
- [x] The active track is distinguishable by icon, weight and color.
- [x] Missing artwork keeps stable layout dimensions.

## Testing strategy
- Widget tests for all view modes.
- Playback controller tests for queue actions.
