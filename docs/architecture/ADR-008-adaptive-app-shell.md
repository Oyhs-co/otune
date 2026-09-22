# ADR-008: Adaptive App Shell and Persistent Navigation

## Status
Accepted

## Context
The current navigation uses independent routes. When users navigate between the library and settings, the current playback context is lost from the UI, and the user must manually go back. To create a "music player" experience, we need a persistent shell that hosts a mini-player and allows quick switching between main sections without resetting the state of those sections.

## Decision
We will implement an `AppShell` using `go_router`'s `StatefulShellRoute`. 

1. **Shell Structure**: A top-level widget (`AppShell`) will contain the navigation elements and the `MiniPlayer`.
2. **Adaptive Navigation**: 
   - For screen widths < 600px: `BottomNavigationBar`.
   - For screen widths >= 600px: `NavigationRail`.
3. **State Persistence**: `StatefulShellRoute` will be used to ensure that switching between Library and Settings preserves the state (scroll position, search query, etc.) of each branch.
4. **Mini-Player**: The `MiniPlayer` will be a persistent child of the `AppShell`, sitting above the bottom navigation or at the bottom of the screen, ensuring the user always has playback control.
5. **Detail routes**: `Now Playing` remains a dedicated detail route outside the shell. The queue uses the adaptive surface defined in `docs/specs/playback/adaptive-queue.md`: a bottom sheet on narrow screens and a bounded dialog on wide screens.

## Alternatives considered
- **Independent Routes**: Current implementation. Too disruptive for a media app.
- **Simple Tabs (without state persistence)**: Easier to implement but loses user context (e.g., search results in the library) when switching tabs.

## Consequences
- **Benefits**: Improved UX, persistent playback control, professional adaptive layout.
- **Costs**: Increased complexity in the router configuration.
- **Risks**: Potential for routing bugs if deep links are not handled carefully.

## Scope
- This ADR covers the shell structure and navigation. It does not cover the internal logic of the `NowPlayingPage` or `MiniPlayer`, which are detailed in their respective SPECS.

## Verification
- Verify that switching tabs does not reset the scroll position of the Library.
- Verify that the `MiniPlayer` remains visible when navigating.
- Verify that the layout switches from BottomNav to NavRail at 600px.
- Verify that opening `Now Playing` preserves the active playback session.
