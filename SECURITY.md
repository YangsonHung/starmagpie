# Security Policy

## Supported Versions

The project currently supports the latest version on the `main` branch.

## Reporting Security Issues

Do not disclose vulnerability details, tokens, log secrets, or exploitable steps in public issues.

Recommended reporting paths:

1. Use GitHub private vulnerability reporting.
2. If the repository has not enabled that feature, contact the maintainer through the maintainer's GitHub profile.
3. If a public issue is the only available channel, describe only the impact scope and omit exploit details or sensitive information.

Include as much of the following as safely possible:

- Affected version or commit hash
- macOS version
- Impact scope
- Reproduction conditions
- Redacted logs that do not expose sensitive data

## Token Handling

StarMagpie GitHub tokens must be stored only in macOS Keychain. Writing tokens to SwiftData, logs, crash reports, screenshots, or plain files is treated as a security defect.
