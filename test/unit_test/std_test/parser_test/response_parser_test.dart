// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/parser_mgr.dart';
import 'package:simple_webdav_client/src/_std/resource.dart';
import 'package:simple_webdav_client/src/_std/response.dart';
import 'package:simple_webdav_client/src/dav/content_type.dart';
import 'package:simple_webdav_client/src/response.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  WebDavResposneDataParserManger,
  WebDavStdResResultView,
  WebDavStdResourceProp,
  ResponseResultParser,
  MultiStatusElementParser,
  PropstatElementParser,
  ResponseElementParser,
  ErrorElementParser,
  PropElementParser,
  HttpHeaders,
])
import 'response_parser_test.mocks.dart';

void main() {
  group("test BaseRespResultParser", () {
    test("convert", () {
      final singleParser = MockResponseResultParser();
      final multiParser = MockResponseResultParser();
      final parser = BaseRespResultParser(
          singleResDecoder: singleParser, multiResDecoder: multiParser);
      final param = ResponseResultParserParam(
          path: Uri.base,
          status: HttpStatus.accepted,
          headers: MockHttpHeaders(),
          data: "mock data");
      provideDummy<WebDavStdResResultView>(MockWebDavStdResResultView());
      when(singleParser.convert(param))
          .thenReturn(MockWebDavStdResResultView());
      parser.convert(param);
      verify(singleParser.convert(param)).called(1);
      verifyNever(multiParser.convert(any));
    });
    test("convert multistatus", () {
      final singleParser = MockResponseResultParser();
      final multiParser = MockResponseResultParser();
      final parser = BaseRespResultParser(
          singleResDecoder: singleParser, multiResDecoder: multiParser);
      final param = ResponseResultParserParam(
          path: Uri.base,
          status: HttpStatus.multiStatus,
          headers: MockHttpHeaders(),
          data: "mock data");
      provideDummy<WebDavStdResResultView>(MockWebDavStdResResultView());
      when(multiParser.convert(param)).thenReturn(MockWebDavStdResResultView());
      parser.convert(param);
      verify(multiParser.convert(param)).called(1);
      verifyNever(singleParser.convert(any));
    });
  });
  group("test BaseRespSingleResultParser.convertProp", () {
    test("error", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      final errorParser = MockErrorElementParser();
      when(errorParser.convert(any)).thenReturn(WebDavStdResError("test-msg"));
      when(parserMgr.error).thenReturn(errorParser);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<error>
  <lock-token-submitted/>
</error>
"""
          .trim());
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.accepted);
      final result = parser.convertProp(root.rootElement, resource);
      expect(result.$1!.message, equals("test-msg"));
      expect(result.$2, isNull);
      expect(result.$3, isEmpty);
    });
    test("error with 'DAV:' namespace", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      final errorParser = MockErrorElementParser();
      when(errorParser.convert(any)).thenReturn(WebDavStdResError("test-msg"));
      when(parserMgr.error).thenReturn(errorParser);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:error xmlns:D="DAV:">
  <D:lock-token-submitted/>
</D:error>
"""
          .trim());
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.accepted);
      final result = parser.convertProp(root.rootElement, resource);
      expect(result.$1!.message, equals("test-msg"));
      expect(result.$2, isNull);
      expect(result.$3, isEmpty);
    });
    test("error with other namespace", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      when(parserMgr.error).thenReturn(null);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:error xmlns:D="CUSTOM:">
  <D:lock-token-submitted/>
</D:error>
"""
          .trim());
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.accepted);
      final result = parser.convertProp(root.rootElement, resource);
      expect(result.$1, isNull);
      expect(result.$2, isNull);
      expect(result.$3, isEmpty);
    });
    test("error with no parser", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      when(parserMgr.error).thenReturn(null);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<error>
  <lock-token-submitted/>
</error>
"""
          .trim());
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.accepted);
      final result = parser.convertProp(root.rootElement, resource);
      expect(result.$1, isNull);
      expect(result.$2, isNull);
      expect(result.$3, isEmpty);
    });
    test("propstat", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      final propstatParser = MockPropstatElementParser();
      final props = [MockWebDavStdResourceProp(), MockWebDavStdResourceProp()];
      when(propstatParser.convert(any)).thenReturn(props);
      when(parserMgr.propstat).thenReturn(propstatParser);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:propstat xmlns:D="DAV:">
  <D:data/>
</D:propstat>
"""
          .trim());
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.accepted);
      final result = parser.convertProp(root.rootElement, resource);
      expect(result.$1, isNull);
      expect(result.$2, isNull);
      expect(result.$3, equals(props));
    });
    test("propstat with no parser", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      when(parserMgr.propstat).thenReturn(null);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:propstat xmlns:D="DAV:">
  <D:prop>
    <D:getetag>"123456789"</D:getetag>
    <D:getlastmodified>Tue, 10 Aug 2023 14:30:00 GMT</D:getlastmodified>
  </D:prop>
</D:propstat>
"""
          .trim());
      final resource =
          WebDavStdResource(path: Uri.base, status: HttpStatus.accepted);
      final result = parser.convertProp(root.rootElement, resource);
      expect(result.$1, isNull);
      expect(result.$2, isNull);
      expect(result.$3, isEmpty);
    });
    test("prop", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      final propParser1 = MockPropElementParser();
      final propParser2 = MockPropElementParser();
      final prop1 = MockWebDavStdResourceProp();
      final prop2 = MockWebDavStdResourceProp();
      final error = WebDavStdResError("test");
      when(propParser1.convert(any)).thenReturn(prop1);
      when(propParser2.convert(any)).thenReturn(prop2);
      when(parserMgr.fetchPropParser("data1", "DAV:")).thenReturn(propParser1);
      when(parserMgr.fetchPropParser("data2", "DAV:")).thenReturn(propParser2);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
  <!-- data3 should never be converted -->
  <data3/>
</D:prop>
"""
          .trim());
      final resource = WebDavStdResource(
          path: Uri.base,
          status: HttpStatus.accepted,
          error: error,
          desc: "mock desc");
      final result = parser.convertProp(root.rootElement, resource);
      expect(result.$1, isNull);
      expect(result.$2, isNull);
      expect(result.$3.toList(), equals([prop1, prop2]));
      verify(parserMgr.fetchPropParser("data1", "DAV:")).called(1);
      verify(parserMgr.fetchPropParser("data2", "DAV:")).called(1);
      verify(propParser1.convert((
        node: root.rootElement.getElement("data1", namespace: "DAV:")!,
        status: HttpStatus.accepted,
        error: error,
        desc: "mock desc"
      ))).called(1);
      verify(propParser2.convert((
        node: root.rootElement.getElement("data2", namespace: "DAV:")!,
        status: HttpStatus.accepted,
        error: error,
        desc: "mock desc"
      ))).called(1);
    });
    test("prop with not parser", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      final error = WebDavStdResError("test");
      when(parserMgr.fetchPropParser(any, "DAV:")).thenReturn(null);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
</D:prop>
"""
          .trim());
      final resource = WebDavStdResource(
          path: Uri.base,
          status: HttpStatus.accepted,
          error: error,
          desc: "mock desc");
      final result = parser.convertProp(root.rootElement, resource);
      expect(result.$1, isNull);
      expect(result.$2, isNull);
      expect(result.$3.toList(), equals([]));
      verify(parserMgr.fetchPropParser("data1", "DAV:")).called(1);
      verify(parserMgr.fetchPropParser("data2", "DAV:")).called(1);
    });
  });
  group("test BaseRespSingleResultParser.convertResource", () {
    test("resposne", () {
      final resource = WebDavStdResource(
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          desc: "test mock",
          error: WebDavStdResError("test"),
          props: {
            (name: "data", ns: "DAV:"): WebDavStdResourceProp(
                name: "data",
                namespace: Uri.parse("DAV:"),
                status: HttpStatus.badGateway)
          });
      final parserMgr = MockWebDavResposneDataParserManger();
      final responseParser = MockResponseElementParser();
      when(parserMgr.response).thenReturn(responseParser);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:response xmlns:D="DAV:">
</D:response>
"""
          .trim());
      when(responseParser.convert(root.rootElement)).thenReturn([resource]);
      final result = parser.convertResource(root.rootElement,
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          redirect: Uri.parse("http://example.com/redirect"));
      expect(result.path, equals(resource.path));
      expect(result.status, equals(resource.status));
      expect(result.desc, equals(resource.desc));
      expect(result.error, equals(resource.error));
      expect(result.props, equals(resource.props));
    });
    test("resposne with not parser", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      when(parserMgr.response).thenReturn(null);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:response xmlns:D="DAV:">
</D:response>
"""
          .trim());
      final result = parser.convertResource(root.rootElement,
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          redirect: Uri.parse("http://example.com/redirect"));
      expect(result.path, equals(Uri.parse("http://example.com/resource")));
      expect(result.status, equals(HttpStatus.accepted));
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.props, isEmpty);
    });
    test("other with unknown element", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      final responseParser = MockResponseElementParser();
      when(parserMgr.response).thenReturn(responseParser);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:other xmlns:D="DAV:">
</D:other>
"""
          .trim());
      final result = parser.convertResource(root.rootElement,
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          redirect: Uri.parse("http://example.com/redirect"));
      expect(result.path, equals(Uri.parse("http://example.com/resource")));
      expect(result.status, equals(HttpStatus.accepted));
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.props, isEmpty);
    });
    test("other with no root", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      final responseParser = MockResponseElementParser();
      when(parserMgr.response).thenReturn(responseParser);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final result = parser.convertResource(null,
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          redirect: Uri.parse("http://example.com/redirect"));
      expect(result.path, equals(Uri.parse("http://example.com/resource")));
      expect(result.status, equals(HttpStatus.accepted));
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.props, isEmpty);
    });
    test("other with 'prop' element", () {
      final parserMgr = MockWebDavResposneDataParserManger();
      final propstatParser = MockPropstatElementParser();
      final props = [
        WebDavStdResourceProp(
            name: "data1",
            namespace: Uri.parse("DAV:"),
            status: HttpStatus.badGateway),
        WebDavStdResourceProp(
            name: "data2",
            namespace: Uri.parse("CUSTOM:"),
            status: HttpStatus.locked)
      ];
      when(propstatParser.convert(any)).thenReturn(props);
      when(parserMgr.propstat).thenReturn(propstatParser);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:propstat xmlns:D="DAV:">
</D:propstat>
"""
          .trim());
      final result = parser.convertResource(root.rootElement,
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          redirect: Uri.parse("http://example.com/redirect"));
      expect(result.path, equals(Uri.parse("http://example.com/resource")));
      expect(result.status, equals(HttpStatus.accepted));
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.props, equals(props));
    });
    test("other with 'error' element", () {
      final error = WebDavStdResError('mock');
      final parserMgr = MockWebDavResposneDataParserManger();
      final errorParser = MockErrorElementParser();
      when(errorParser.convert(any)).thenReturn(error);
      when(parserMgr.error).thenReturn(errorParser);
      final parser = BaseRespSingleResultParser(parserManger: parserMgr);
      final root = XmlDocument.parse("""
<D:error xmlns:D="DAV:">
</D:error>
"""
          .trim());
      final result = parser.convertResource(root.rootElement,
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          redirect: Uri.parse("http://example.com/redirect"));
      expect(result.path, equals(Uri.parse("http://example.com/resource")));
      expect(result.status, equals(HttpStatus.accepted));
      expect(result.desc, isNull);
      expect(result.error, same(error));
      expect(result.props, isEmpty);
    });
  });
  group("test BaseRespSingleResultParser.convert", () {
    late HttpHeaders headers;
    late WebDavResposneDataParserManger parserMgr;
    late BaseRespSingleResultParser parser;

    setUp(() {
      headers = MockHttpHeaders();
      parserMgr = MockWebDavResposneDataParserManger();
      parser = BaseRespSingleResultParser(parserManger: parserMgr);
    });

    test("not xml | no redirect", () {
      when(headers.value(HttpHeaders.locationHeader)).thenReturn(null);
      when(headers.contentType).thenReturn(null);
      final result = parser.convert(ResponseResultParserParam(
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          headers: headers,
          data: """
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
</D:prop>
"""
              .trim()));
      expect(result, equals(TypeMatcher<WebDavStdResResultView>()));
      expect(result.length, 1);
      expect(
          result.first.path, equals(Uri.parse("http://example.com/resource")));
      expect(result.first.status, equals(HttpStatus.accepted));
      expect(result.first.error, isNull);
      expect(result.first.desc, isNull);
      expect(result.first.props, isEmpty);
      expect(result.first.redirect, isNull);
    });
    test("not xml | with redirect", () {
      when(headers.value(HttpHeaders.locationHeader))
          .thenReturn("http://example.com/redirect");
      when(headers.contentType).thenReturn(null);
      final result = parser.convert(ResponseResultParserParam(
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          headers: headers,
          data: """
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
</D:prop>
"""
              .trim()));
      expect(result, equals(TypeMatcher<WebDavStdResResultView>()));
      expect(result.length, 1);
      expect(
          result.first.path, equals(Uri.parse("http://example.com/resource")));
      expect(result.first.status, equals(HttpStatus.accepted));
      expect(result.first.error, isNull);
      expect(result.first.desc, isNull);
      expect(result.first.props, isEmpty);
      expect(result.first.redirect,
          equals(Uri.parse("http://example.com/redirect")));
    });
    test("is xml | with redirect", () {
      when(headers.value(HttpHeaders.locationHeader))
          .thenReturn("http://example.com/redirect");
      when(headers.contentType).thenReturn(ContentType("custom", "xml"));
      final propParser1 = MockPropElementParser();
      final propParser2 = MockPropElementParser();
      final prop1 = MockWebDavStdResourceProp();
      when(prop1.name).thenReturn("data1-name");
      when(prop1.namespace).thenReturn(Uri.parse("DAV:"));
      final prop2 = MockWebDavStdResourceProp();
      when(prop2.name).thenReturn("data2-name");
      when(prop2.namespace).thenReturn(Uri.parse("DAV:"));
      when(propParser1.convert(any)).thenReturn(prop1);
      when(propParser2.convert(any)).thenReturn(prop2);
      when(parserMgr.fetchPropParser("data1", "DAV:")).thenReturn(propParser1);
      when(parserMgr.fetchPropParser("data2", "DAV:")).thenReturn(propParser2);
      final result = parser.convert(ResponseResultParserParam(
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          headers: headers,
          data: """
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
  <data3/>
</D:prop>
"""
              .trim()));
      expect(result, equals(TypeMatcher<WebDavStdResResultView>()));
      expect(result.length, 1);
      expect(
          result.first.path, equals(Uri.parse("http://example.com/resource")));
      expect(result.first.status, equals(HttpStatus.accepted));
      expect(result.first.error, isNull);
      expect(result.first.desc, isNull);
      expect(result.first.props, unorderedEquals([prop2, prop1]));
      expect(result.first.redirect,
          equals(Uri.parse("http://example.com/redirect")));
    });
  });
  group("test BaseRespMultiResultParser", () {
    late HttpHeaders headers;
    late WebDavResposneDataParserManger parserMgr;
    late BaseRespMultiResultParser parser;

    setUp(() {
      headers = MockHttpHeaders();
      parserMgr = MockWebDavResposneDataParserManger();
      parser = BaseRespMultiResultParser(parserManger: parserMgr);
    });

    test("convert not xml | no parser", () {
      when(headers.contentType).thenReturn(null);
      when(parserMgr.multistatus).thenReturn(null);
      final result = parser.convert(ResponseResultParserParam(
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          headers: headers,
          data: """
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
</D:prop>
"""
              .trim()));
      expect(result, equals(TypeMatcher<WebDavResponseResult>()));
      expect(result, isEmpty);
    });
    test("convert not xml | with parser", () {
      when(headers.contentType).thenReturn(null);
      when(parserMgr.multistatus).thenReturn(MockMultiStatusElementParser());
      final result = parser.convert(ResponseResultParserParam(
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          headers: headers,
          data: """
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
</D:prop>
"""
              .trim()));
      expect(result, equals(TypeMatcher<WebDavResponseResult>()));
      expect(result, isEmpty);
    });
    test("convert with xml | no parser", () {
      when(headers.contentType).thenReturn(XmlContentType.applicationXml);
      when(parserMgr.multistatus).thenReturn(null);
      final result = parser.convert(ResponseResultParserParam(
          path: Uri.parse("http://example.com/resource"),
          status: HttpStatus.accepted,
          headers: headers,
          data: """
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
</D:prop>
"""
              .trim()));
      expect(result, equals(TypeMatcher<WebDavResponseResult>()));
      expect(result, isEmpty);
    });
    test("convert with xml and parser", () {
      final multiParser = MockMultiStatusElementParser();
      final result = WebDavStdResponseResult();
      when(multiParser.convert(any)).thenReturn(result);
      when(headers.contentType).thenReturn(XmlContentType.applicationXml);
      when(parserMgr.multistatus).thenReturn(multiParser);
      expect(
          parser.convert(ResponseResultParserParam(
              path: Uri.parse("http://example.com/resource"),
              status: HttpStatus.accepted,
              headers: headers,
              data: """
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
</D:prop>
"""
                  .trim())),
          same(result));
      when(multiParser.convert(any)).thenReturn(null);
      expect(
          parser.convert(ResponseResultParserParam(
              path: Uri.parse("http://example.com/resource"),
              status: HttpStatus.accepted,
              headers: headers,
              data: """
<D:prop xmlns:D="DAV:">
  <D:data1/>
  <D:data2/>
</D:prop>
"""
                  .trim())),
          equals(TypeMatcher<WebDavResponseResultView>()));
    });
  });
}
