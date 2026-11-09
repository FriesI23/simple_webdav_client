// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/const.dart';
import 'package:simple_webdav_client/src/io.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group("test DateTimePropParser", () {
    test("convert", () {
      const parser = DateTimePropParser();
      final result = parser.convert((
        desc: null,
        error: null,
        node: XmlDocument.parse("<prop1></prop1>").rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, isNull);
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.lang, isNull);
      expect(result.value, isNull);
    });
    test("convert, full case", () {
      const parser = DateTimePropParser();
      final result = parser.convert((
        desc: 'test',
        error: WebDavStdResError("mock"),
        node: XmlDocument.parse(
          """
<D:prop1 xml:lang=en-us xmlns:D=DAV:>
  2024-09-03T15:27:04Z
</D:prop1>
"""
              .trim(),
        ).rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, 'test');
      expect(result.error!.message, "mock");
      expect(result.lang, 'en-us');
      expect(result.value, equals(DateTime.utc(2024, 9, 3, 15, 27, 4)));
    });
  });
  group("test HttpDatePropParser", () {
    test("convert", () {
      const parser = HttpDatePropParser();
      final result = parser.convert((
        desc: null,
        error: null,
        node: XmlDocument.parse("<prop1></prop1>").rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, isNull);
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.lang, isNull);
      expect(result.value, isNull);
    });
    test("convert, full case", () {
      const parser = HttpDatePropParser();
      final result = parser.convert((
        desc: 'test',
        error: WebDavStdResError("mock"),
        node: XmlDocument.parse(
          """
<D:prop1 xml:lang=en-us xmlns:D=DAV:>
  Tue, 03 Sep 2024 07:27:04 GMT
</D:prop1>
"""
              .trim(),
        ).rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, 'test');
      expect(result.error!.message, "mock");
      expect(result.lang, 'en-us');
      expect(result.value, equals(DateTime.utc(2024, 9, 3, 7, 27, 4)));
    });
    group("test StringPropParser", () {
      test("convert", () {
        const parser = StringPropParser();
        final result = parser.convert((
          desc: null,
          error: null,
          node: XmlDocument.parse("<prop1></prop1>").rootElement,
          status: HttpStatus.accepted,
        ));
        expect(result.name, "prop1");
        expect(result.namespace, isNull);
        expect(result.status, HttpStatus.accepted);
        expect(result.desc, isNull);
        expect(result.error, isNull);
        expect(result.lang, isNull);
        expect(result.value, "");
      });
      test("convert, full case", () {
        const parser = StringPropParser();
        final result = parser.convert((
          desc: 'test',
          error: WebDavStdResError("mock"),
          node: XmlDocument.parse(
            """
<D:prop1 xml:lang=en-us xmlns:D=DAV:>
  qwertyuiop
</D:prop1>
"""
                .trim(),
          ).rootElement,
          status: HttpStatus.accepted,
        ));
        expect(result.name, "prop1");
        expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
        expect(result.status, HttpStatus.accepted);
        expect(result.desc, 'test');
        expect(result.error!.message, "mock");
        expect(result.lang, 'en-us');
        expect(result.value, equals("qwertyuiop"));
      });
    });
    group("test NumPropParser", () {
      test("convert", () {
        const parser = NumPropParser();
        final result = parser.convert((
          desc: null,
          error: null,
          node: XmlDocument.parse("<prop1></prop1>").rootElement,
          status: HttpStatus.accepted,
        ));
        expect(result.name, "prop1");
        expect(result.namespace, isNull);
        expect(result.status, HttpStatus.accepted);
        expect(result.desc, isNull);
        expect(result.error, isNull);
        expect(result.lang, isNull);
        expect(result.value, isNull);
      });
      test("convert, full case", () {
        const parser = NumPropParser();
        final result = parser.convert((
          desc: 'test',
          error: WebDavStdResError("mock"),
          node: XmlDocument.parse(
            """
<D:prop1 xml:lang=en-us xmlns:D=DAV:>
  1234.45
</D:prop1>
"""
                .trim(),
          ).rootElement,
          status: HttpStatus.accepted,
        ));
        expect(result.name, "prop1");
        expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
        expect(result.status, HttpStatus.accepted);
        expect(result.desc, 'test');
        expect(result.error!.message, "mock");
        expect(result.lang, 'en-us');
        expect(result.value, equals(1234.45));
      });
    });
    group("test ContentTypePropParser", () {
      test("convert", () {
        const parser = ContentTypePropParser();
        final result = parser.convert((
          desc: null,
          error: null,
          node: XmlDocument.parse("<prop1></prop1>").rootElement,
          status: HttpStatus.accepted,
        ));
        expect(result.name, "prop1");
        expect(result.namespace, isNull);
        expect(result.status, HttpStatus.accepted);
        expect(result.desc, isNull);
        expect(result.error, isNull);
        expect(result.lang, isNull);
        expect(result.value, isNull);
      });
      test("convert, full case", () {
        const parser = ContentTypePropParser();
        final result = parser.convert((
          desc: 'test',
          error: WebDavStdResError("mock"),
          node: XmlDocument.parse(
            """
<D:prop1 xml:lang=en-us xmlns:D=DAV:>
  text/html; charset=utf-8
</D:prop1>
"""
                .trim(),
          ).rootElement,
          status: HttpStatus.accepted,
        ));
        expect(result.name, "prop1");
        expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
        expect(result.status, HttpStatus.accepted);
        expect(result.desc, 'test');
        expect(result.error!.message, "mock");
        expect(result.lang, 'en-us');
        expect(result.value.toString(), equals(ContentType.html.toString()));
      });
    });
    group("test ResourceTypePropParser", () {
      test("convert", () {
        const parser = ResourceTypePropParser();
        final result = parser.convert((
          desc: null,
          error: null,
          node: XmlDocument.parse("<prop1></prop1>").rootElement,
          status: HttpStatus.accepted,
        ));
        expect(result.name, "prop1");
        expect(result.namespace, isNull);
        expect(result.status, HttpStatus.accepted);
        expect(result.desc, isNull);
        expect(result.error, isNull);
        expect(result.lang, isNull);
        expect(result.value, isEmpty);
      });
      test("convert, full case", () {
        const parser = ResourceTypePropParser();
        final result = parser.convert((
          desc: 'test',
          error: WebDavStdResError("mock"),
          node: XmlDocument.parse(
            """
<D:prop1 xml:lang=en-us xmlns:D=DAV: xmlns:X=CUSTOM:>
  <D:collection/>
  <X:custom1/>
  <X:custom2> 1234 </X:custom2>
</D:prop1>
"""
                .trim(),
          ).rootElement,
          status: HttpStatus.accepted,
        ));
        expect(result.name, "prop1");
        expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
        expect(result.status, HttpStatus.accepted);
        expect(result.desc, 'test');
        expect(result.error!.message, "mock");
        expect(result.lang, 'en-us');
        expect(
          result.value,
          unorderedEquals([
            (name: "collection", ns: "DAV:"),
            (name: "custom1", ns: "CUSTOM:"),
            (name: "custom2", ns: "CUSTOM:"),
          ]),
        );
      });
    });
  });
}
