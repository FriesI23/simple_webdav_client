// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('test BaseHrefElementParser', () {
    test("convert", () {
      const parser = BaseHrefElementParser();
      final result = parser.convert(
        XmlDocument.parse("<root>http://example.com</root>").rootElement,
      );
      expect(result, equals(Uri.parse("http://example.com")));
    });
    test("convert nested", () {
      const parser = BaseHrefElementParser();
      final result = parser.convert(
        XmlDocument.parse("<h><p>http://example.com</p></h>").rootElement,
      );
      expect(result, equals(Uri.parse("http://example.com")));
    });
  });
  group("test NestedHrefElementParser", () {
    test("convert", () {
      const parser = NestedHrefElementParser(
        hrefParser: BaseHrefElementParser(),
      );
      final result = parser.convert(
        XmlDocument.parse(
          "<root><href>http://example.com</href></root>",
        ).rootElement,
      );
      expect(result, equals(Uri.parse("http://example.com")));
    });
    test("convert not href element", () {
      const parser = NestedHrefElementParser(
        hrefParser: BaseHrefElementParser(),
      );
      final result = parser.convert(
        XmlDocument.parse("<p>http://example.com</p>").rootElement,
      );
      expect(result, isNull);
    });
  });
}
