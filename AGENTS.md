# AGENTS.md

Repository guidance for `simple_webdav_client`, a pure Dart WebDAV package.

## Structure and API boundaries

- `lib/*.dart` are public export entrypoints. Consumers should import these
  rather than implementation files under `lib/src/`.
- `lib/src/` contains shared client/request/response interfaces, protocol
  definitions, common errors and utilities. `lib/src/dav/` contains DAV-level
  interfaces and shared definitions; `lib/src/codec/` contains reusable codecs.
  These directories are not restricted to interface declarations alone.
- `lib/src/_std/` owns the default implementation and its supporting parameter,
  configuration and value types. Keep implementation-specific features here;
  authentication configuration and its session belong together in
  `lib/src/_std/authentication.dart`.
- Put a type in the shared layer when it is a shared contract or foundation,
  not merely because it is public. Public concrete types may be exported from
  `_std` through the appropriate entrypoint. Use `show` when a file also contains
  internal helpers, and do not expose the authentication session.
- Do not introduce an interface, file or controller solely for abstraction.
  Keep related types together when they serve one implementation.
- When an interface needs a private default implementation, keep both in one
  file and construct the implementation through a factory on the interface.
  Document enum values and every interface constructor, getter and method.
  Keep API documentation on the interface; private and overriding implementation
  methods do not need repeated Dartdoc. Use ordinary comments for implementation
  details only when they help explain the logic.
- Use relative imports within the package. Route native/browser IO types through
  `lib/src/io.dart`; extend its explicit `universal_io` export when needed.

## Implementation and tests

- Prefer existing SDK, package and official Dart library capabilities before
  implementing protocol details. Use `http_parser` for authentication challenges
  and the existing PROPFIND parameter/XML builder for discovery payloads.
- Preserve the legacy constructors and SDK authentication APIs when changing
  managed authentication. Do not mix SDK site credentials with managed auth.
- Keep credentials scoped, out of logs, and protected from automatic redirect
  forwarding. Authentication discovery must remain read-only and bounded;
  do not add automatic replay of business request bodies.
- Unit tests live in `test/unit_test/`. Native HTTP integration tests live in
  `test/intergration_test/` (existing spelling). Reuse `server.dart` and its
  response callback for authentication cases. Package checks must not require
  Docker or an external service.
- Keep the original `example/server/bytemark_webdav/` Docker example.
  Application-level Compose fixtures and full sync acceptance belong to the
  consuming app's integration tests, with lifecycle managed by test hooks.
- Never edit generated `*.mocks.dart` files manually. Change their source
  annotations and regenerate them with `make gen`.

## Commands and Git workflow

- `.tool-versions` pins development/formatting to Dart 3.8.3; `pubspec.yaml`
  defines the supported SDK range. Use the pinned formatter rather than a newer
  SDK's formatting defaults.
- Prefer the existing Make entrypoints: `make bootstrap`, `make gen`,
  `make format`, `make analyze`, `make test`, and `make check`. Set `DART` to the
  intended SDK executable when it is not selected by the shell.
- Run `make check` for code changes. Use `make publish-dry-run` to validate a
  package artifact without publishing; it may warn about uncommitted changes.
- Preserve existing staged and unstaged work. Do not implicitly stage, commit,
  tag, push or publish. App path overrides and downstream verification belong
  to the consuming app repository; maintain each repository's Git boundaries.
