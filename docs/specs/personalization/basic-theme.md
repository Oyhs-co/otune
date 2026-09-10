# SPEC: Basic Theme

## Status
Proposed

## Context
The application needs a consistent visual identity that is pleasing to the eye and adaptable to system preferences (like Dark/Light mode).

## Goal
Implement a basic theming system based on Material 3 that allows for primary/secondary color customization.

## Scope
- Integration of `Material 3` ColorScheme.
- Implementation of `dynamic_color` for system-aware theming.
- a `ThemeRepository` to persist user theme preferences.
- Basic Light and Dark mode support.

## Non-goals
- Advanced "Skinning" or custom CSS-like styles.
- Dynamic layout changes based on theme.
- User-created custom themes (only a few presets for MVP).

## User stories
- As a user, I want the app to follow my system's dark/light mode preference.
- As a user, I want the app colors to match my Android wallpaper (via Material You).

## Domain rules
- Theme state is global and observable.
- `dynamic_color` takes precedence if enabled.
- If `dynamic_color` is disabled, the app falls back to a predefined `OtuneColorScheme`.

## Functional requirements
- FR-THEME-001: The system shall support Light and Dark modes.
- FR-THEME-002: The system shall integrate `dynamic_color` to extract colors from the OS.
- FR-THEME-003: The system shall allow the user to toggle between Light, Dark, and System default.
- FR-THEME-004: Theme preferences shall be persisted locally.

## Non-functional requirements
- NFR-THEME-001: Theme switching should happen instantly without app restart.
- NFR-THEME-002: Contrast ratios must meet accessibility standards (WCAG AA).

## Scenarios

### Scenario: System Theme Sync
Given the system is set to "Dark Mode"
When the app is launched with "System Default" theme
Then the app applies the Dark ColorScheme

### Scenario: Dynamic Color Activation
Given the app is running on Android 12+ with `dynamic_color` enabled
When the app starts
Then the primary colors are derived from the user's wallpaper

### Scenario: Manual Override
Given the system is in "Light Mode"
When the user selects "Dark" in app settings
Then the app applies the Dark ColorScheme regardless of system settings

## Edge cases
- Platforms not supporting `dynamic_color` (e.g., older Windows versions): System falls back to default `OtuneColorScheme`.
- Rapidly toggling theme: Ensure no flickering or memory leaks in the provider.

## Acceptance criteria
- [ ] AC-THEME-001: App correctly switches between Light and Dark modes.
- [ ] AC-THEME-002: `dynamic_color` works on supported platforms.
- [ ] AC-THEME-003: Theme preference is remembered after app restart.

## Testing strategy
- **Widget**: Test that changing the theme provider updates the colors of a sample page.
- **Integration**: Test the persistence of theme settings.

## Dependencies
- `dynamic_color`
- `flutter_riverpod`

## Related architecture decisions
- DDD: `Personalization` Bounded Context.
- ADR: Flutter as UI framework.

## Open questions
- Should we introduce `flex_color_scheme` now or wait for a more complex theme requirement? (Recommended: Wait).
