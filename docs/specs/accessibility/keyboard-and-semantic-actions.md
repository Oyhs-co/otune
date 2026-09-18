# SPEC: Keyboard and Semantic Actions

## Status
Implemented

## Goal
Ensure important actions remain discoverable and operable with semantic labels across touch, mouse and keyboard-oriented desktop use.

## Scope
- Labels and tooltips for icon-only playback, queue and search actions.
- Visible labels for navigation destinations.
- Stable touch targets and text truncation.
- Current playback state communicated by icon, text and emphasis.

## Non-goals
- Global shortcut map before a product need is defined.
- Screen-reader certification for every platform.

## Acceptance criteria
- [x] Important icon buttons expose tooltips.
- [x] Navigation destinations expose visible labels.
- [x] Queue removal, search clear and playback controls have named actions.
- [x] State is not communicated by color alone.

## Testing strategy
- Widget tests for action labels.
- Manual verification at narrow and wide constraints.
