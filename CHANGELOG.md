<!-- markdownlint-disable MD041 -->

## Unreleased

- Add scoped Basic and MD5 Digest authentication with read-only discovery,
  mixed Basic challenge support and an explicit Basic mode on native platforms.
- Support HTTP Digest over direct and proxy connections, including custom
  connection factories.
- Disable automatic redirects for authenticated clients and keep CONNECT proxy
  credentials out of requests to the origin.
- Preserve transport exceptions and caller-configured proxy authentication.
- Support UTF-8 credentials, challenge-directed NFC normalization, and Digest
  extended usernames (`username*`) and username hashing (`userhash=true`).
- Exclude tests and TLS fixtures from published archives.

- Require Dart 3.8 or later and update WebDAV/XML and development dependencies.
- Adopt a stricter pure Dart style baseline and Dart 3.8.3 formatting.
- Add local quality commands and CI checks for SDK and dependency compatibility.
- Gate tag publishing on all checks and use Dart directly for OIDC publishing.

## 0.2.0

- Add support for web apps.
- Add publish github action.

## 0.1.0

- Add new release, see [README.md](README.md) for more information.
