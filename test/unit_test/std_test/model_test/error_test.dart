// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:test/test.dart';

void main() {
  group("test WebDavStdResError", () {
    test("constructor", () {
      final error = WebDavStdResError("test");
      expect(error.message, "test");
      expect(error.conditions, isEmpty);
      expect(error.toString(), "StdResErrorCond{test, cond=[]}");
    });
    test("constructor with condition", () {
      final error = WebDavStdResError("test", conditions: [
        StdResErrorCond.noConflictingLock,
        StdResErrorCond.cannotModifyProtectedProperty
      ]);
      expect(error.message, "test");
      expect(error.conditions, [
        StdResErrorCond.noConflictingLock,
        StdResErrorCond.cannotModifyProtectedProperty
      ]);
      expect(
          error.toString(),
          "StdResErrorCond{test, "
          "cond=[no-conflicting-lock,cannot-modify-protected-property]}");
    });
  });
}
