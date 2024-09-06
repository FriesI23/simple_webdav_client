// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/client.dart';
import 'package:simple_webdav_client/src/client.dart';
import 'package:test/test.dart';

void main() {
  test("test std", () {
    final client = WebDavClient.std();
    expect(client, TypeMatcher<WebDavClient>());
    expect(client, TypeMatcher<WebDavStdClient>());
  });
}
