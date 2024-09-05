// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/timeout.dart';
import 'package:test/test.dart';

void main() {
  group("test DavTimeout", () {
    test("constructor", () {
      final timeout = DavTimeout([]);
      expect(timeout, isEmpty);
      expect(timeout.toString(), "");
    });
    test("constructor with timeouts", () {
      final timeout = DavTimeout([double.infinity, 1234, 23, 12.3, 8.7, 0]);
      expect(timeout, isNotEmpty);
      expect(timeout.toString(),
          "Infinite, Second-1234, Second-23, Second-12, Second-9, Second-0");
    });
    test("reset length", () {
      final timeout = DavTimeout([double.infinity, 1234, 23, 12.3, 8.7, 0]);
      expect(() => timeout.length = 190,
          throwsA(TypeMatcher<UnimplementedError>()));
    });
    test("operators", () {
      final timeout = DavTimeout([]);
      expect(timeout.length, 0);
      expect(timeout.isEmpty, isTrue);
      timeout.add(double.infinity);
      expect(timeout.length, 1);
      expect(timeout.isNotEmpty, isTrue);
      expect(timeout[0], double.infinity);
      timeout[0] = 12.3;
      expect(timeout.length, 1);
      expect(timeout.isNotEmpty, isTrue);
      expect(timeout[0], 12.3);
    });
  });
}
