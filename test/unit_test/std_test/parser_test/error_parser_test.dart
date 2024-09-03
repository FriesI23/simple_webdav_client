// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group("test BaseErrorElementParser", () {
    late BaseErrorElementParser parser;

    setUp(() {
      parser = BaseErrorElementParser();
    });

    test("convert", () {
      final input = XmlDocument.parse("""
<error>
  <lock-token-matches-request-uri/>
  <lock-token-submitted/>
  <no-conflicting-lock/>
  <no-external-entities/>
  <preserved-live-properties/>
  <propfind-finite-depth/>
  <cannot-modify-protected-property/>
  <unknown-condition/>
</error>
"""
          .trim());
      final result = parser.convert(input.rootElement);
      expect(result, equals(TypeMatcher<WebDavStdResError>()));
      expect(result.message, isEmpty);
      expect(
          result.conditions, unorderedEquals(StdResErrorCond.values.toList()));
      expect(result.conditions.map((e) => e.name).contains("unknown-condition"),
          isFalse);
    });
  });
}
