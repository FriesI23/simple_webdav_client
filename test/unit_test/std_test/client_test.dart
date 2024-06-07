// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:simple_webdav_client/src/_std/client.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

@GenerateMocks([
  HttpClient,
])
import 'client_test.mocks.dart';

class MockHttpOverrides extends HttpOverrides {
  static late MockHttpClient client;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    client = MockHttpClient();
    return client;
  }
}

void main() {
  group("test WebDavStdClient", () {
    setUpAll(() {
      HttpOverrides.global = MockHttpOverrides();
    });
    tearDownAll(() {
      HttpOverrides.global = null;
    });
    test("test constructor", () {
      final client = WebDavStdClient();
      expect(client.client, same(MockHttpOverrides.client));
      expect(client.closed, isFalse);
    });
  });
}
