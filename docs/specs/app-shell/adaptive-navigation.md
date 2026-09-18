# SPEC: Adaptive Navigation

## Status
Draft

## Context
The current navigation is a simple set of independent routes. As the application grows, users need a way to navigate between the main sections (Home/Playback, Library, Settings) without losing context or having to go back to a home screen.

## Goal
Provide a consistent and adaptive navigation shell that adapts to different screen sizes (mobile vs desktop/tablet).

## Scope
- Implementation of an AppShell.
- Bottom navigation for mobile.
- NavigationRail or Side Menu for wide screens.
- Persistent state for main sections.

## Non-goals
- Deep linking beyond basic routes.
- Complex animation between screens.

## User stories
- As a mobile user, I want a bottom navigation bar to quickly switch between Library and Settings.
- As a desktop user, I want a side navigation rail to utilize the available horizontal space.

## Domain rules
- DR-001: Navigation should not interrupt current audio playback.

## Functional requirements
- FR-001: The UI must adapt automatically based on screen width.
- FR-002: The active destination must be visually highlighted.
- FR-003: Switching destinations must preserve the state of the page (e.g., scroll position, search query).

## Non-functional requirements
- NFR-001: Navigation transitions should be smooth.

## Scenarios

### Scenario: Switch from Library to Settings on Mobile
Given the user is on the Library page
When the user taps the 'Settings' icon in the bottom navigation bar
Then the Settings page is displayed
And the Library page state is preserved

### Scenario: Switch from Library to Settings on Desktop
Given the user is on the Library page on a wide screen
When the user clicks 'Settings' in the NavigationRail
Then the Settings page is displayed
And the NavigationRail updates the active indicator

## Edge cases
- Very narrow screens: ensure bottom nav doesn't overlap content.
- Extremely wide screens: ensure content remains centered or appropriately bounded.

## Acceptance criteria
- [ ] AC-001: Application uses an adaptive shell for navigation.
- [ ] AC-002: Bottom navigation is visible on mobile (< 600px).
- [ ] AC-003: NavigationRail is visible on desktop (>= 600px).
- [ ] AC-004: Navigation between main sections does not stop audio playback.

## Testing strategy

### Widget
- Test that BottomNavigationBar is shown on small screens.
- Test that NavigationRail is shown on large screens.
- Test that tapping a destination changes the current route.

## Dependencies
- `go_router` (already in use).

## Related DDD
- Bounded context: `app`
- Use case: `NavigateBetweenSections`

## Related ADRs
- ADR-006-go-router-navigation.md
- (Proposed) ADR-008-adaptive-app-shell.md

## Verification

| Acceptance Criterion | Evidence / Test | Status |
|---|---|---|
| AC-001 | Visual check / Widget test | ⬜ |
| AC-002 | Widget test (screen size < 600) | ⬜ |
| AC-003 | Widget test (screen size >= 600) | ⬜ |
| AC-004 | Integration test (playback check) | ⬜ |

## Change history

| Date | Change | Reason |
|---|---|---|
| 2026-09-17 | Initial spec | Phase 0 Preparation |
