// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/depth.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group("test DepthElementParser", () {
    test("convert", () {
      final parser = DepthElementParser();
      expect(parser.convert(XmlDocument.parse("<r>infinity</r>").rootElement),
          Depth.all);
      expect(parser.convert(XmlDocument.parse("<r>1</r>").rootElement),
          Depth.members);
      expect(parser.convert(XmlDocument.parse("<r>0</r>").rootElement),
          Depth.resource);
      expect(parser.convert(XmlDocument.parse("<r>x</r>").rootElement), isNull);
      expect(parser.convert(XmlDocument.parse("<r></r>").rootElement), isNull);
    });
  });
}
