<!-- markdownlint-disable MD041 -->

## Unreleased

- Prevent Digest business-request retries and empty-body replay; bound discovery
  to parent traversal and one authenticated probe. Reject managed authentication
  on the Web, where redirect credential scoping cannot be guaranteed.
- Add managed Basic discovery for mixed WWW-Authenticate challenges, explicit
  Basic authentication, scoped credentials and bounded Digest discovery.
- Reuse the existing native HTTP test server for authentication regressions.
- Use the official `http_parser` challenge parser and existing PROPFIND builders
  for authentication discovery; document unsupported token68 headers.

- Require Dart 3.8 or later and update WebDAV/XML and development dependencies.
- Adopt a stricter pure Dart style baseline and Dart 3.8.3 formatting.
- Add local quality commands and CI checks for SDK and dependency compatibility.
- Gate tag publishing on all checks and use Dart directly for OIDC publishing.

## 0.2.0

- Add support for web apps.
- Add publish github action.

## 0.1.0

- Add new release, see [README.md](README.md) for more information.
