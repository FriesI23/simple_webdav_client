// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/parser_mgr.dart';
import 'package:simple_webdav_client/src/_std/resource.dart';
import 'package:simple_webdav_client/src/error.dart';
import 'package:simple_webdav_client/src/io.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  HttpStatusElementParser,
  ErrorElementParser,
  PropElementParser,
  WebDavResposneDataParserManger,
  WebDavStdResourceProp,
])
import "propstat_parser_test.mocks.dart";

void main() {
  group("test BasePropstatElementParser", () {
    late BasePropstatElementParser parser;
    late HttpStatusElementParser statusParser;
    late ErrorElementParser errorParser;
    late WebDavResposneDataParserManger parserManager;

    setUp(() {
      statusParser = MockHttpStatusElementParser();
      errorParser = MockErrorElementParser();
      parserManager = MockWebDavResposneDataParserManger();
      parser = BasePropstatElementParser(
          parserManger: parserManager,
          statusParser: statusParser,
          errorParser: errorParser);
    });

    test("convert ", () {
      final input = XmlDocument.parse("""
<propstat>
  <status/>
  <prop>
    <data1></data1>
    <D:data2 xmlns:D="DAV:"></D:data2>
    <D:data3 xmlns:D="CUSTOM:"></D:data3>
    <data4/>
  </prop>
</propstat>
"""
          .trim());
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.multiStatus);
      when((statusParser as MockHttpStatusElementParser).convert(any))
          .thenReturn(HttpStatus.ok);
      final data1PropParser = MockPropElementParser();
      when(data1PropParser.convert(any))
          .thenReturn(MockWebDavStdResourceProp());
      when(parserManager.fetchPropParser("data1", null))
          .thenReturn(data1PropParser);
      final data2PropParser = MockPropElementParser();
      when(data2PropParser.convert(any))
          .thenReturn(MockWebDavStdResourceProp());
      when(parserManager.fetchPropParser("data2", "DAV:"))
          .thenReturn(data2PropParser);
      final data3PropParser = MockPropElementParser();
      when(data3PropParser.convert(any)).thenReturn(null);
      when(parserManager.fetchPropParser("data3", "CUSTOM:"))
          .thenReturn(data3PropParser);
      when(parserManager.fetchPropParser("data4", null)).thenReturn(null);
      final result = parser
          .convert((node: input.rootElement, resource: resource)).toList();
      expect(result.length, 2);
      verify(data1PropParser.convert((
        node: input.findAllElements("data1").first,
        status: HttpStatus.ok,
        error: null,
        desc: null
      ))).called(1);
      verify(data2PropParser.convert((
        node: input.findAllElements("data2", namespace: "*").first,
        status: HttpStatus.ok,
        error: null,
        desc: null
      ))).called(1);
      verify(data3PropParser.convert((
        node: input.findAllElements("data3", namespace: "*").first,
        status: HttpStatus.ok,
        error: null,
        desc: null
      ))).called(1);
      verify(parserManager.fetchPropParser("data4", any)).called(1);
    });
    test("convert, full case ", () {
      final input = XmlDocument.parse("""
<propstat>
  <status/>
  <error/>
  <responsedescription>testtest</responsedescription>
  <prop>
    <data/>
  </prop>
</propstat>
"""
          .trim());
      final error = WebDavStdResError('mock');
      when((errorParser as MockErrorElementParser).convert(any))
          .thenReturn(error);
      when((statusParser as MockHttpStatusElementParser).convert(any))
          .thenReturn(HttpStatus.ok);
      final dataPropParser = MockPropElementParser();
      when(dataPropParser.convert(any)).thenReturn(MockWebDavStdResourceProp());
      when(parserManager.fetchPropParser("data", null))
          .thenReturn(dataPropParser);
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.multiStatus);
      final result = parser
          .convert((node: input.rootElement, resource: resource)).toList();
      expect(result.length, 1);
      verify(dataPropParser.convert((
        node: input.findAllElements("data").first,
        status: HttpStatus.ok,
        error: error,
        desc: "testtest"
      ))).called(1);
      verify((errorParser as MockErrorElementParser).convert(any)).called(1);
    });
    test("convert, full case with no status element ", () {
      final input = XmlDocument.parse("""
<propstat>
  <error/>
  <responsedescription>testtest</responsedescription>
  <prop>
    <data/>
  </prop>
</propstat>
"""
          .trim());
      final error = WebDavStdResError('mock');
      when((errorParser as MockErrorElementParser).convert(any))
          .thenReturn(error);
      final dataPropParser = MockPropElementParser();
      when(dataPropParser.convert(any)).thenReturn(MockWebDavStdResourceProp());
      when(parserManager.fetchPropParser("data", null))
          .thenReturn(dataPropParser);
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.notFound);
      final result = parser
          .convert((node: input.rootElement, resource: resource)).toList();
      expect(result.length, 1);
      verify(dataPropParser.convert((
        node: input.findAllElements("data").first,
        status: HttpStatus.notFound,
        error: error,
        desc: "testtest"
      ))).called(1);
      verify((errorParser as MockErrorElementParser).convert(any)).called(1);
    });
    test("convert no prop", () {
      final input = XmlDocument.parse("""
<propstat>
  <status/>
</propstat>
"""
          .trim());
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.multiStatus);
      when((statusParser as MockHttpStatusElementParser).convert(any))
          .thenReturn(HttpStatus.ok);

      final result =
          parser.convert((node: input.rootElement, resource: resource));
      expect(result, isEmpty);
    });
    test("convert no status node and resource status is 207(multistatus)", () {
      expect(
          () => parser.convert((
                node: XmlDocument.parse("""
<propstat>
</propstat>
"""
                        .trim())
                    .rootElement,
                resource: WebDavStdResource(
                    path: Uri.base, status: HttpStatus.multiStatus)
              )),
          throwsA(TypeMatcher<WebDavParserDataError>()));
    });
    test("convert status element but convert return null", () {
      when((statusParser as MockHttpStatusElementParser).convert(any))
          .thenReturn(null);
      expect(
          () => parser.convert((
                node: XmlDocument.parse("""
<propstat>
  <status/>
</propstat>
"""
                        .trim())
                    .rootElement,
                resource: WebDavStdResource(
                    path: Uri.base, status: HttpStatus.multiStatus)
              )),
          throwsA(TypeMatcher<WebDavParserDataError>()));
    });
  });
}
