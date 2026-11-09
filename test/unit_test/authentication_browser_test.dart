// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

@TestOn('browser')
library;

import 'package:simple_webdav_client/client.dart';
import 'package:test/test.dart';

void main() {
  for (final mode in WebDavAuthenticationMode.values) {
    test('managed $mode rejects Web before opening any request', () {
      expect(
        () => WebDavStdClient.authenticated(
          authentication: WebDavAuthenticationConfig(
            scope: Uri.parse('https://example.test/dav/'),
            username: 'user',
            password: 'password',
            mode: mode,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  }

  test('legacy client remains available on Web', () {
    final client = WebDavStdClient();
    expect(client.closed, isFalse);
    client.close();
    expect(client.closed, isTrue);
  });
}
