// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group("test TimeoutElementParser", () {
    test("convert", () {
      final parser = TimeoutElementParser();
      expect(
          parser.convert(XmlDocument.parse("<r>Second-1234</r>").rootElement),
          1234.0);
      expect(parser.convert(XmlDocument.parse("<r>Second-0</r>").rootElement),
          0.0);
      expect(parser.convert(XmlDocument.parse("<r>Infinite</r>").rootElement),
          double.infinity);
      expect(parser.convert(XmlDocument.parse("<r>Minute-123</r>").rootElement),
          isNull);
      expect(parser.convert(XmlDocument.parse("<r>1</r>").rootElement), isNull);
      expect(parser.convert(XmlDocument.parse("<r></r>").rootElement), isNull);
    });
  });
}
