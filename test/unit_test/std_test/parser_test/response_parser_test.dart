// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/resource.dart';
import 'package:simple_webdav_client/src/error.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  WebDavStdResource,
  HrefElementParser,
  HttpStatusElementParser,
  PropstatElementParser,
  ErrorElementParser,
])
import 'response_parser_test.mocks.dart';

void main() {
  group("test BaseResponseElementParser", () {
    late ResponseElementParser parser;
    late HrefElementParser hrefParser;
    late HttpStatusElementParser statusParser;
    late PropstatElementParser propstatParser;
    late ErrorElementParser errorParser;

    setUp(() {
      hrefParser = MockHrefElementParser();
      statusParser = MockHttpStatusElementParser();
      propstatParser = MockPropstatElementParser();
      errorParser = MockErrorElementParser();
      parser = BaseResponseElementParser(
          hrefParser: hrefParser,
          statusParser: statusParser,
          propstatParser: propstatParser,
          errorParser: errorParser,
          locationParser: hrefParser);
    });
    test("convert no path", () {
      final input = XmlDocument.parse("""
<response xmlns:D="CUSTOM:">
  <D:href>/invalid/namespace/</D:href>
</response>
"""
          .trim());
      expect(() => parser.convert(input.rootElement),
          throwsA(TypeMatcher<WebDavParserDataError>()));
    });
    test("convert status is null", () {
      final input = XmlDocument.parse("""
<response>
  <href>/resource1</href>
  <status>test</status>
</response>
"""
          .trim());
      when((statusParser as MockHttpStatusElementParser).convert(any))
          .thenReturn(null);
      expect(parser.convert(input.rootElement), isEmpty);
      verify((statusParser as MockHttpStatusElementParser).convert(any))
          .called(1);
    });
    test("convert with bnf:(href*, status)", () {
      final input = XmlDocument.parse("""
<response>
  <href>/resource1</href>
  <href>/resource2</href>
  <href>/resource3</href>
  <status>HTTP/1.1 200 OK</status>
  <!-- propstat element should ignored in this case -->
  <propstat/>
</response>
"""
          .trim());
      when((statusParser as MockHttpStatusElementParser).convert(any))
          .thenReturn(HttpStatus.accepted);
      when(hrefParser.convert(input.findAllElements("href").toList()[0]))
          .thenReturn(Uri.parse("/resource1"));
      when(hrefParser.convert(input.findAllElements("href").toList()[1]))
          .thenReturn(Uri.parse("/resource2"));
      when(hrefParser.convert(input.findAllElements("href").toList()[2]))
          .thenReturn(Uri.parse("/resource3"));
      final result = parser.convert(input.rootElement);
      expect(result.length, 3);
      expect(result.where((e) => e.path == Uri.parse("/resource1")).length, 1);
      expect(
          result.where((e) => e.path == Uri.parse("/resource1")).first.status,
          HttpStatus.accepted);
      expect(result.where((e) => e.path == Uri.parse("/resource2")).length, 1);
      expect(
          result.where((e) => e.path == Uri.parse("/resource2")).first.status,
          HttpStatus.accepted);
      expect(result.where((e) => e.path == Uri.parse("/resource3")).length, 1);
      expect(
          result.where((e) => e.path == Uri.parse("/resource3")).first.status,
          HttpStatus.accepted);
    });
    test("convert with bnf:(href*, status), full case", () {
      final input = XmlDocument.parse("""
<response>
  <href>/resource1</href>
  <href>/resource2</href>
  <status>HTTP/1.1 200 OK</status>
  <error/>
  <location/>
  <!-- propstat element should ignored in this case -->
  <propstat/>
</response>
"""
          .trim());
      when((statusParser as MockHttpStatusElementParser).convert(any))
          .thenReturn(HttpStatus.accepted);
      when(hrefParser.convert(input.findAllElements("href").toList()[0]))
          .thenReturn(Uri.parse("/resource1"));
      when(hrefParser.convert(input.findAllElements("href").toList()[1]))
          .thenReturn(Uri.parse("/resource2"));
      when((errorParser as MockErrorElementParser)
              .convert(input.rootElement.getElement("error")!))
          .thenReturn(WebDavStdResError("mock"));
      when((hrefParser as MockHrefElementParser)
              .convert(input.rootElement.getElement("location")!))
          .thenReturn(Uri.base);
      final result = parser.convert(input.rootElement);
      expect(result.length, 2);
      expect(result.where((e) => e.path == Uri.parse("/resource1")).length, 1);
      final r1 = result.where((e) => e.path == Uri.parse("/resource1")).first;
      expect(r1.status, HttpStatus.accepted);
      expect(r1.error, equals(TypeMatcher<WebDavStdResError>()));
      expect(r1.redirect, equals(Uri.base));
      expect(result.where((e) => e.path == Uri.parse("/resource2")).length, 1);
      final r2 = result.where((e) => e.path == Uri.parse("/resource2")).first;
      expect(r2.status, HttpStatus.accepted);
      expect(r2.error, equals(TypeMatcher<WebDavStdResError>()));
      expect(r2.redirect, equals(Uri.base));
    });
    test("convert with bnf:(propstat+)", () {
      final input = XmlDocument.parse("""
<response>
  <href>/resource</href>
  <!-- other hrefs will be ignored -->
  <href>/resource2</href>
  <href>/resource3</href>
  <propstat>
    <!-- state 1 -->
  </propstat>
  <propstat>
    <!-- state 2 -->
  </propstat>
</response>
"""
          .trim());
      when((hrefParser as MockHrefElementParser)
              .convert(input.rootElement.getElement("href")!))
          .thenReturn(Uri.parse("/resource"));
      int index = 1;
      when((propstatParser as MockPropstatElementParser).convert(any))
          .thenAnswer((_) {
        final result = [
          WebDavStdResourceProp<int>(
              name: "prop$index", status: HttpStatus.accepted, value: index),
          WebDavStdResourceProp<String>(
              name: "prop${index + 1}",
              status: HttpStatus.accepted,
              value: (index + 1).toString()),
        ];
        index += 2;
        return result;
      });
      final result = parser.convert(input.rootElement);
      expect(result.length, 1);
      final resource = result.first;
      expect(resource.path, Uri.parse("/resource"));
      expect(resource.status, HttpStatus.multiStatus);
      expect(resource.error, isNull);
      expect(resource.desc, isNull);
      expect(resource.redirect, isNull);
      expect(resource.props.length, 4);
      // prop1
      expect(resource.props.where((e) => e.name == 'prop1').length, 1);
      expect(resource.props.where((e) => e.name == 'prop1').first.value, 1);
      // prop2
      expect(resource.props.where((e) => e.name == 'prop2').length, 1);
      expect(resource.props.where((e) => e.name == 'prop2').first.value, "2");
      // prop3
      expect(resource.props.where((e) => e.name == 'prop3').length, 1);
      expect(resource.props.where((e) => e.name == 'prop3').first.value, 3);
      // prop4
      expect(resource.props.where((e) => e.name == 'prop4').length, 1);
      expect(resource.props.where((e) => e.name == 'prop4').first.value, "4");
    });
    test("convert with bnf:(propstat+), full case", () {
      final input = XmlDocument.parse("""
<response>
  <href>/resource</href>
  <!-- other hrefs will be ignored -->
  <href>/resource2</href>
  <href>/resource3</href>
  <propstat>
    <!-- state 1 -->
  </propstat>
  <propstat>
    <!-- state 2 -->
  </propstat>
  <error/>
  <location/>
</response>
"""
          .trim());
      when((hrefParser as MockHrefElementParser)
              .convert(input.rootElement.getElement("href")!))
          .thenReturn(Uri.parse("/resource"));
      int index = 0;
      when((propstatParser as MockPropstatElementParser).convert(any))
          .thenAnswer((_) {
        index += 1;
        return [
          WebDavStdResourceProp<int>(
              name: "prop$index", status: HttpStatus.accepted, value: index),
        ];
      });
      when((errorParser as MockErrorElementParser)
              .convert(input.rootElement.getElement("error")!))
          .thenReturn(WebDavStdResError("mock"));
      when((hrefParser as MockHrefElementParser)
              .convert(input.rootElement.getElement("location")!))
          .thenReturn(Uri.base);
      final result = parser.convert(input.rootElement);
      expect(result.length, 1);
      final resource = result.first;
      expect(resource.path, Uri.parse("/resource"));
      expect(resource.status, HttpStatus.multiStatus);
      expect(resource.error!.message, "mock");
      expect(resource.desc, isNull);
      expect(resource.redirect, equals(Uri.base));
      expect(resource.props.length, 2);
      // prop1
      expect(resource.props.where((e) => e.name == 'prop1').length, 1);
      expect(resource.props.where((e) => e.name == 'prop1').first.value, 1);
      // prop2
      expect(resource.props.where((e) => e.name == 'prop2').length, 1);
      expect(resource.props.where((e) => e.name == 'prop2').first.value, 2);
    });
    test("convert with bnf:(propstat+) and no path", () {
      final input = XmlDocument.parse("""
<response>
  <href>/resource</href>
  <propstat>
    <!-- state 1 -->
  </propstat>
  <propstat>
    <!-- state 2 -->
  </propstat>
</response>
"""
          .trim());
      when((hrefParser as MockHrefElementParser).convert(any)).thenReturn(null);
      final result = parser.convert(input.rootElement);
      expect(result, isEmpty);
    });
  });
}
