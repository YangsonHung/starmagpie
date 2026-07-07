<p align="center">
  <img src="docs/assets/app-icon.png" width="128" alt="StarMagpie app icon">
</p>

<h1 align="center">⭐ StarMagpie</h1>

<p align="center">
  A native macOS app for turning GitHub Stars into a searchable, categorized, personal repository library.
</p>

<p align="center">
  <a href="README.md"><strong>English</strong></a>
  ·
  <a href="README.zh-CN.md">中文</a>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: GPL v3" src="https://img.shields.io/badge/License-GPLv3-blue.svg"></a>
  <a href="https://github.com/yangsonhung/starmagpie/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/yangsonhung/starmagpie/actions/workflows/ci.yml/badge.svg"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-lightgrey.svg">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-14%2B-black.svg">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5-orange.svg">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-blue.svg">
  <img alt="SwiftData" src="https://img.shields.io/badge/storage-SwiftData-purple.svg">
  <img alt="XcodeGen" src="https://img.shields.io/badge/project-XcodeGen-147EFB.svg">
</p>

<p align="center">
  <img src="interface.jpg" alt="StarMagpie interface screenshot">
</p>

## 🧭 Overview

StarMagpie syncs your GitHub starred repositories to your Mac and keeps them useful after the initial star. It stores repository metadata locally, lets you search across names, descriptions, languages, topics, and notes, and gives each repository a category so your Stars become easier to revisit.

The app is intentionally small and native. It uses SwiftUI, SwiftData, URLSession, and macOS Keychain. There is no backend service, no account sync server, and no token storage outside Keychain.

## ✨ Highlights

- Native macOS experience built with SwiftUI.
- GitHub Personal Access Token sign-in with secure Keychain storage.
- Paginated GitHub Stars sync using `application/vnd.github.star+json`, preserving `starred_at`.
- Local persistence with SwiftData.
- Fast search across repository name, full name, description, topics, language, and notes.
- Two-column repository browser with list and card view modes.
- Built-in keyword categories plus manual category overrides.
- Dedicated repository detail modal with README preview, notes, link copying, GitHub opening, and unstarring.
- JSON import and export for local repository data, categories, notes, and last viewed timestamps.
- English and Simplified Chinese localization with an in-app language picker.

## 📚 Contents

- [Requirements](#-requirements)
- [Install](#-install)
- [Usage](#-usage)
- [GitHub Token Permissions](#-github-token-permissions)
- [Privacy](#-privacy)
- [Development](#-development)
- [Release Builds](#-release-builds)
- [Localization](#-localization)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)

## 🖥️ Requirements

- macOS 14.0 or later
- Xcode 26 or later
- XcodeGen

Install XcodeGen with Homebrew:

```bash
brew install xcodegen
```

## 📦 Install

### ⬇️ Download a release

Download `StarMagpie-unsigned.dmg` from the GitHub Releases page once releases are published. Open the DMG and drag `StarMagpie.app` to Applications.

The project does not use an Apple Developer certificate yet, so release packages are not signed with Developer ID and are not notarized by Apple. macOS Gatekeeper will warn that the app is from an unidentified developer.

### 🛠️ Build from source

```bash
git clone https://github.com/yangsonhung/starmagpie.git
cd starmagpie
xcodegen generate
open StarMagpie.xcodeproj
```

Select the `StarMagpie` scheme in Xcode and run the app.

## 🚀 Usage

1. Create a classic GitHub Personal Access Token with access to your starred repositories.
2. Launch StarMagpie and sign in with the token.
3. Click Sync to load your starred repositories.
4. Browse repositories in list or card mode, then click a repository to open its detail modal.
5. View metadata, README, category, notes, and quick actions in the detail modal.
6. Use search, language filtering, sorting, categories, and notes to organize repositories.
7. Use the Data menu to export or import a StarMagpie JSON archive.

Import behavior is merge-based: repositories with the same GitHub repo `id` are updated, and local repositories missing from the archive are kept.

## 🔐 GitHub Token Permissions

StarMagpie stores your token only in macOS Keychain. It never writes the token to SwiftData, logs, or project files.

Recommended minimum permissions:

- Full sync and unstar support: use a classic personal access token with `public_repo`.
- Private starred repositories: use a classic personal access token with `repo`.

Create a classic token:

1. Open [GitHub classic token settings](https://github.com/settings/tokens/new).
2. Enter a token name and expiration.
3. Select one permission set:
   - Public starred repositories only: check `public_repo`.
   - Public and private starred repositories: check `repo`.
4. Do not enable unrelated scopes such as `workflow`, `write:packages`, `admin:org`, `gist`, `notifications`, `user`, `delete_repo`, `project`, or key-management scopes.
5. Generate the token, copy it once, and paste it into StarMagpie.
6. If you need to replace a token later, use StarMagpie's **Update GitHub Token** button. This only replaces the Keychain token and keeps local repositories, notes, and categories.

## 🛡️ Privacy

StarMagpie is local-first:

- No backend service.
- No remote analytics.
- No cross-device sync.
- GitHub tokens are stored in macOS Keychain only.
- Repository data, notes, categories, and import/export archives stay under your control.

## 🧑‍💻 Development

Generate the Xcode project:

```bash
xcodegen generate
```

Run tests:

```bash
xcodebuild test -scheme StarMagpie -destination 'platform=macOS'
```

Build the app:

```bash
xcodebuild build -scheme StarMagpie -destination 'platform=macOS'
```

Regenerate the app icon:

```bash
./scripts/generate-app-icon.swift
```

Build an unsigned release package:

```bash
./scripts/package-unsigned.sh
```

## 🏷️ Release Builds

Local unsigned packages are written to:

- `dist/StarMagpie-unsigned.dmg`
- `dist/StarMagpie-unsigned.dmg.sha256`
- `dist/StarMagpie-unsigned.zip`
- `dist/StarMagpie-unsigned.zip.sha256`

When a `v*` tag is pushed to GitHub, the `Release Unsigned Build` workflow builds the unsigned package and attaches it to the GitHub Release.

The build has no Apple TeamIdentifier. Xcode may still add an ad-hoc/linker signature to the executable, which is not a Developer ID signature.

## 🌐 Localization

The source code uses English strings as the base language. User-facing strings are localized through:

- `StarMagpie/en.lproj/Localizable.strings`
- `StarMagpie/zh-Hans.lproj/Localizable.strings`
- `StarMagpie/en.lproj/InfoPlist.strings`
- `StarMagpie/zh-Hans.lproj/InfoPlist.strings`

When adding UI text, update both English and Simplified Chinese localization files in the same change.

## 🗂️ Project Structure

```text
StarMagpie/
├── StarMagpie/                 # App source
│   ├── App/                    # App entry and root views
│   ├── Models/                 # SwiftData models and filtering logic
│   ├── Services/               # GitHub API, Keychain, archive, and sync services
│   ├── Utilities/              # Localization, documents, and global settings helpers
│   ├── ViewModels/             # Detail loading and presentation state
│   ├── Views/                  # SwiftUI views
│   ├── Assets.xcassets/        # App icon and assets
│   ├── en.lproj/               # English localization
│   └── zh-Hans.lproj/          # Simplified Chinese localization
├── StarMagpieTests/            # Unit tests
├── .github/                    # Issue templates, PR template, CI, and release workflow
├── docs/                       # Documentation assets
├── scripts/                    # Local maintenance scripts
├── AGENTS.md                   # Agent development instructions
├── CLAUDE.md -> AGENTS.md      # Claude-compatible symlink
├── CONTRIBUTING.md             # Contribution guide
├── CODE_OF_CONDUCT.md          # Code of conduct
├── SECURITY.md                 # Security policy
├── SUPPORT.md                  # Support policy
├── LICENSE                     # GNU GPL v3
├── README.zh-CN.md             # Simplified Chinese README
└── project.yml                 # XcodeGen config
```

## 🤝 Contributing

Issues and pull requests are welcome. Please read:

- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

Use the GitHub issue templates when reporting bugs, asking questions, or proposing features. Include macOS version, Xcode version, reproduction steps, and relevant logs when applicable.

## 📄 License

StarMagpie is licensed under the [GNU General Public License v3.0](LICENSE).
