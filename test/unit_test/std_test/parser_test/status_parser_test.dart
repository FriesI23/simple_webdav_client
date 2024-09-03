// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group("test BaseHttpStatusElementParser", () {
    late BaseHttpStatusElementParser parser;

    setUp(() {
      parser = BaseHttpStatusElementParser();
    });

    test("convert", () {
      expect(
          parser.convert(
              XmlDocument.parse("<r>HTTP/1.1 500 Internal Server Error</r>")
                  .rootElement),
          HttpStatus.internalServerError);
      expect(
          parser
              .convert(XmlDocument.parse("<p>HTTP/1.1 200 OK</p>").rootElement),
          HttpStatus.ok);
    });
    test("convert error", () {
      expect(
          parser.convert(
              XmlDocument.parse("<r>HTTP/1.1 xxx Internal Server Error</r>")
                  .rootElement),
          isNull);
      expect(
          parser.convert(
              XmlDocument.parse("<r>HTTP/1.1 500.0 Internal Server Error</r>")
                  .rootElement),
          isNull);
      expect(() => parser.convert(XmlDocument.parse("<r>500</r>").rootElement),
          throwsA(TypeMatcher<RangeError>()));
    });
  });
}
