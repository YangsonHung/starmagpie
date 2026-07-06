# Contributing Guide

Thank you for contributing to StarMagpie. This project prioritizes a clear, stable, and maintainable native macOS experience.

## Before You Start

- Read [README.md](README.md) to understand the project goal and structure.
- Read the [Code of Conduct](CODE_OF_CONDUCT.md).
- Report security issues through the [Security Policy](SECURITY.md). Do not disclose details publicly.

## Development Environment

Requirements:

- macOS 14.0 or later
- Xcode 26 or later
- XcodeGen

Common commands:

```bash
xcodegen generate
xcodebuild test -scheme StarMagpie -destination 'platform=macOS'
xcodebuild build -scheme StarMagpie -destination 'platform=macOS'
./scripts/generate-app-icon.swift
./scripts/package-unsigned.sh
```

## Contribution Workflow

1. Fork the repository.
2. Create a branch from `main`.
3. Keep changes focused. One pull request should solve one problem.
4. Run `xcodegen generate` after changing `project.yml`.
5. Update both English and Simplified Chinese localization files when adding user-facing text.
6. Run tests and build checks.
7. Open a pull request and fill in the PR template.

## Code Guidelines

- Keep SwiftUI views small and clear. Move complex logic into models or services.
- Store tokens only in Keychain. Never write them to SwiftData, logs, or plain files.
- GitHub Stars API requests must keep `Accept: application/vnd.github.star+json`.
- Sync merge uses GitHub repo `id` as the primary key and preserves local fields: `manualCategoryId`, `notes`, and `lastViewedAt`.
- Repository import/export uses StarMagpie JSON archives. Imports merge by GitHub repo `id` and do not delete local repositories missing from the archive.
- Dynamic strings, error messages, category names, and sort names should use `AppLocalizer`.

## Testing

At minimum, pull requests must pass:

```bash
xcodebuild test -scheme StarMagpie -destination 'platform=macOS'
```

Add or update tests when changing UI text, localization, GitHub API behavior, sync merge behavior, Keychain handling, filtering, or sorting.

Unsigned release packages are generated with:

```bash
./scripts/package-unsigned.sh
```

The project does not use an Apple Developer certificate yet. Do not commit signing certificates, provisioning profiles, or notarization credentials. Xcode-generated ad-hoc/linker signatures are not Developer ID signatures.

## Issue Guidelines

Use the issue templates and include:

- macOS version
- Xcode version
- App version or commit hash
- Reproduction steps
- Expected behavior and actual behavior
- Logs or screenshots with sensitive data removed
