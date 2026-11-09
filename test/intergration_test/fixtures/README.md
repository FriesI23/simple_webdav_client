# TLS test fixtures

The certificate and private key are public fixtures for local HTTPS and CONNECT
proxy tests. Tests trust the local CA and pin the leaf certificate when required
by native certificate validation. Use these fixtures only for tests.

`test/.pubignore` excludes this directory from published packages.
