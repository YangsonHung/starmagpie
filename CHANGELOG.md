# Changelog

This project keeps a user-facing changelog. After releases, append changes by version.

## Unreleased

## v0.4.0 - 2026-07-08

### Added

- Added manual app appearance switching for Follow System, Light, and Dark modes.
- Added ascending and descending sorting for repository lists.

### Changed

- Reworked the sort control into a single menu that shows the active sort field and order.

## v0.3.1 - 2026-07-07

### Fixed

- Improved GitHub 403 handling so missing token permissions recommend the classic personal access token scopes needed for sync and unstar.
- Updated token guidance with step-by-step classic personal access token setup for full unstar support.

## v0.3.0 - 2026-07-07

### Added

- README interface screenshot.

### Changed

- Reworked the main window into a two-column browser to remove the inline detail pane and its nested scrolling.
- Added list and card view modes for repository browsing.
- Moved repository details, notes, actions, and README preview into a dedicated modal detail view.

### Fixed

- Fixed relative README images and raw README links from GitHub repositories in the preview.

## v0.2.0 - 2026-07-07

### Added

- Repository README preview in the detail pane.
- Larger README reading area with better media fitting in the detail pane.

### Changed

- Reduced in-app language switching work by localizing lightweight subviews instead of refreshing the whole window tree.
- Improved Simplified Chinese localization coverage for app chrome, repository metadata, login, and language menu labels.

## v0.1.0

### Added

- Native macOS GitHub Stars manager.
- StarMagpie app icon and AppIcon asset catalog.
- English-first README with Simplified Chinese translation.
- Repository import and export.
- Unsigned macOS DMG and ZIP package script and GitHub Release workflow.
- GPL v3 license.
- Contributing guide, code of conduct, security policy, and support policy.
- GitHub issue templates, PR template, and CI workflow.
