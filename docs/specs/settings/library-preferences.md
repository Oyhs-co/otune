# SPEC: Library Preferences

## Status
Implemented

## Goal
Expose only preferences that have an immediate functional effect in the current application.

## Scope
- System, light and dark theme selection.
- Theme application through `MaterialApp`.
- Settings surface with an About entry.

## Non-goals
- Persisting preferences between launches until a settings store is approved.
- Folder management without a supported library source contract.

## Acceptance criteria
- [x] The theme preference changes the active Material theme.
- [x] System theme remains available.
- [x] No inactive preference is presented as configurable.

## Testing strategy
- Settings notifier unit tests.
- Settings widget tests.
