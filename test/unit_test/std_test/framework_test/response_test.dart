// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/decoder_mgr.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/resource.dart';
import 'package:simple_webdav_client/src/_std/response.dart';
import 'package:simple_webdav_client/src/error.dart';
import 'package:simple_webdav_client/src/io.dart';
import 'package:simple_webdav_client/src/method.dart';
import 'package:test/test.dart';

@GenerateMocks([
  HttpHeaders,
  HttpClientResponse,
  ResponseBodyDecoderManager,
  ResponseResultParser,
  WebDavStdResResultView,
])
import 'response_test.mocks.dart';

void main() {
  group("test WebDavStdResponse", () {
    test("constructor", () {
      final response = WebDavStdResponse(
          response: MockHttpClientResponse(),
          path: Uri.base,
          method: WebDavMethod.get,
          bodyDecoders: MockResponseBodyDecoderManager(),
          resultParser: MockResponseResultParser());
      expect(response.response, equals(TypeMatcher<HttpClientResponse>()));
      expect(response.path, equals(Uri.base));
      expect(response.method, WebDavMethod.get);
      expect(response.bodyDecoders,
          equals(TypeMatcher<ResponseBodyDecoderManager>()));
      expect(
          response.resultParser, equals(TypeMatcher<ResponseResultParser>()));
      expect(response.body, isNull);
    });
    test("parse", () async {
      final contentType = ContentType.text;
      final httpStatus = HttpStatus.accepted;
      final httpResponse = MockHttpClientResponse();
      final bodyDecoders = MockResponseBodyDecoderManager();
      final resultParser = MockResponseResultParser();
      final httpResponseHeader = MockHttpHeaders();
      final dataResult = MockWebDavStdResResultView();
      when(httpResponse.headers).thenReturn(httpResponseHeader);
      when(httpResponseHeader.contentType).thenReturn(contentType);
      when(bodyDecoders[contentType.charset]).thenReturn(utf8.decoder);
      when(httpResponse.transform(utf8.decoder))
          .thenAnswer((_) => Stream.value("mock data"));
      when(httpResponse.statusCode).thenReturn(httpStatus);
      provideDummy<WebDavStdResResultView>(dataResult);
      when(resultParser.convert(any)).thenReturn(dataResult);
      final response = WebDavStdResponse(
          response: httpResponse,
          path: Uri.base,
          method: WebDavMethod.get,
          bodyDecoders: bodyDecoders,
          resultParser: resultParser);
      // parse
      final result = await response.parse();
      verify(httpResponse.transform(utf8.decoder)).called(1);
      verify(resultParser.convert(any)).called(1);
      expect(response.body, "mock data");
      expect(result, same(dataResult));
      // multi parse
      final result2 = await response.parse();
      verifyNever(httpResponse.transform(utf8.decoder));
      verifyNever(resultParser.convert(any));
      expect(response.body, "mock data");
      expect(result, same(result2));
    });
    test("parse with exception", () async {
      final contentType = ContentType.text;
      final httpStatus = HttpStatus.accepted;
      final httpResponse = MockHttpClientResponse();
      final bodyDecoders = MockResponseBodyDecoderManager();
      final resultParser = MockResponseResultParser();
      final httpResponseHeader = MockHttpHeaders();
      when(httpResponse.headers).thenReturn(httpResponseHeader);
      when(httpResponseHeader.contentType).thenReturn(contentType);
      when(bodyDecoders[contentType.charset]).thenReturn(utf8.decoder);
      when(httpResponse.transform(utf8.decoder))
          .thenAnswer((_) => Stream.value("mock data"));
      when(httpResponse.statusCode).thenReturn(httpStatus);
      provideDummy<WebDavStdResResultView>(MockWebDavStdResResultView());
      when(resultParser.convert(any))
          .thenAnswer((_) => throw Exception('mock message'));
      final response = WebDavStdResponse(
          response: httpResponse,
          path: Uri.base,
          method: WebDavMethod.get,
          bodyDecoders: bodyDecoders,
          resultParser: resultParser);
      // parse
      try {
        await response.parse();
      } on Exception catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), equals("Exception: mock message"));
      }
      verify(httpResponse.transform(utf8.decoder)).called(1);
      verify(resultParser.convert(any)).called(1);
      expect(response.body, "mock data");
      // parse multi
      try {
        await response.parse();
      } on Exception catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), equals("Exception: mock message"));
      }
      verifyNever(httpResponse.transform(utf8.decoder));
      verify(resultParser.convert(any)).called(1);
      expect(response.body, "mock data");
    });
    test("parse with unknown contentType", () async {
      final httpStatus = HttpStatus.accepted;
      final httpResponse = MockHttpClientResponse();
      final bodyDecoders = MockResponseBodyDecoderManager();
      final resultParser = MockResponseResultParser();
      final httpResponseHeader = MockHttpHeaders();
      when(httpResponse.headers).thenReturn(httpResponseHeader);
      when(httpResponseHeader.contentType).thenReturn(ContentType.text);
      when(bodyDecoders.keys).thenReturn([]);
      when(bodyDecoders[any]).thenReturn(null);
      when(httpResponse.transform(utf8.decoder))
          .thenAnswer((_) => Stream.value("mock data"));
      when(httpResponse.statusCode).thenReturn(httpStatus);
      provideDummy<WebDavStdResResultView>(MockWebDavStdResResultView());
      final response = WebDavStdResponse(
          response: httpResponse,
          path: Uri.base,
          method: WebDavMethod.get,
          bodyDecoders: bodyDecoders,
          resultParser: resultParser);
      // parse
      try {
        await response.parse();
      } on WebDavXmlDecodeError catch (e) {
        expect(e, isA<WebDavXmlDecodeError>());
        expect(
            e.message,
            equals("decode body error, got content type is text/plain; "
                "charset=utf-8, which not included from []"));
      }
      verifyNever(httpResponse.transform(any));
      verifyNever(resultParser.convert(any));
      expect(response.body, isNull);
      // parse multi
      try {
        await response.parse();
      } on WebDavXmlDecodeError catch (e) {
        expect(e, isA<WebDavXmlDecodeError>());
        expect(
            e.message,
            equals("decode body error, got content type is text/plain; "
                "charset=utf-8, which not included from []"));
      }
      verifyNever(httpResponse.transform(any));
      verifyNever(resultParser.convert(any));
      expect(response.body, isNull);
    });
  });
  group("test WebDavStdResponseResult", () {
    test("constructor", () {
      final result = WebDavStdResponseResult();
      expect(result, isEmpty);
      expect(result, equals(TypeMatcher<Iterable>()));
      expect(result, equals(TypeMatcher<WebDavStdResResultView>()));
    });
    test("constructor.fromMap", () {
      final result1 = const WebDavStdResponseResult.fromMap({});
      expect(result1, isEmpty);
      expect(result1, equals(TypeMatcher<Iterable>()));
      expect(result1, equals(TypeMatcher<WebDavStdResResultView>()));
      final resource = WebDavStdResource(
          path: Uri.parse("http://example.com"), status: HttpStatus.accepted);
      final result2 = WebDavStdResponseResult.fromMap({Uri.base: resource});
      expect(result2.length, 1);
      expect(result2, equals(TypeMatcher<Iterable>()));
      expect(result2, equals(TypeMatcher<WebDavStdResResultView>()));
      expect(result2.first, same(resource));
    });
    test("add", () {
      final result = WebDavStdResponseResult();
      final resource1 = WebDavStdResource(
          path: Uri.parse("http://example.com"), status: HttpStatus.accepted);
      expect(result.add(resource1), isTrue);
      expect(result.length, 1);
      expect(result.first, same(resource1));
      final resource2 = WebDavStdResource(
          path: Uri.parse("http://example.com"), status: HttpStatus.accepted);
      expect(result.add(resource2), isFalse);
      expect(result.length, 1);
      expect(result.first, same(resource1));
      final resource3 = WebDavStdResource(
          path: Uri.parse("http://example.com/3"), status: HttpStatus.accepted);
      expect(result.add(resource3), isTrue);
      expect(result.length, 2);
      expect(result.toList(), equals([resource1, resource3]));
    });
    test("clear", () {
      final result = WebDavStdResponseResult();
      result.add(WebDavStdResource(
          path: Uri.parse("http://example.com/1"),
          status: HttpStatus.accepted));
      result.add(WebDavStdResource(
          path: Uri.parse("http://example.com/2"),
          status: HttpStatus.accepted));
      expect(result, isNotEmpty);
      expect(result.length, 2);
      result.clear();
      expect(result, isEmpty);
      expect(result.length, 0);
    });
    test("contain", () {
      final result = WebDavStdResponseResult();
      result.add(WebDavStdResource(
          path: Uri.parse("http://example.com/1"),
          status: HttpStatus.accepted));
      result.add(WebDavStdResource(
          path: Uri.parse("http://example.com/2"),
          status: HttpStatus.accepted));
      expect(result.contain(Uri.parse("http://example.com/1")), isTrue);
      expect(result.contain(Uri.parse("http://example.com/2")), isTrue);
      expect(result.contain(Uri.parse("http://example.com/3")), isFalse);
    });
    test("find", () {
      final result = WebDavStdResponseResult();
      final resource1 = WebDavStdResource(
          path: Uri.parse("http://example.com/1"), status: HttpStatus.accepted);
      final resource2 = WebDavStdResource(
          path: Uri.parse("http://example.com/2"), status: HttpStatus.accepted);
      result.add(resource1);
      result.add(resource2);
      expect(result.find(Uri.parse("http://example.com/1")), same(resource1));
      expect(result.find(Uri.parse("http://example.com/2")), same(resource2));
      expect(result.find(Uri.parse("http://example.com/3")), isNull);
    });
    test("iterator", () {
      final result = WebDavStdResponseResult();
      expect(
          result.iterator, equals(TypeMatcher<Iterator<WebDavStdResource>>()));
    });
    test("remove", () {
      final result = WebDavStdResponseResult();
      final resource1 = WebDavStdResource(
          path: Uri.parse("http://example.com/1"), status: HttpStatus.accepted);
      final resource2 = WebDavStdResource(
          path: Uri.parse("http://example.com/2"), status: HttpStatus.accepted);
      result.add(resource1);
      result.add(resource2);
      expect(result, isNotEmpty);
      expect(result.length, 2);
      expect(result.remove(Uri.parse("http://example.com/1")), same(resource1));
      expect(result, isNotEmpty);
      expect(result.length, 1);
      expect(result.remove(Uri.parse("http://example.com/1")), isNull);
      expect(result, isNotEmpty);
      expect(result.length, 1);
      expect(result.remove(Uri.parse("http://example.com/2")), same(resource2));
      expect(result.length, 0);
      expect(result, isEmpty);
    });
    test("toDebugString", () {
      final result = WebDavStdResponseResult();
      final resource1 = WebDavStdResource(
          path: Uri.parse("http://example.com/1"),
          status: HttpStatus.accepted,
          props: {
            (name: "test", ns: "DAV:"): WebDavStdResourceProp(
              name: "test",
              namespace: Uri.parse("DAV:"),
              status: HttpStatus.accepted,
              value: DateTime.parse("2024-08-29 11:29:47"),
            ),
            (name: "test", ns: "CUSTOM:"): WebDavStdResourceProp(
              name: "test",
              namespace: Uri.parse("CUSTOM:"),
              status: HttpStatus.accepted,
              value: DateTime.parse("1970-01-01 12:00:00"),
            )
          });
      final resource2 = WebDavStdResource(
          path: Uri.parse("http://example.com/2"), status: HttpStatus.accepted);
      result.add(resource1);
      result.add(resource2);
      final expectString = """
WebDavStdResponseResult{
  // http://example.com/1
  WebDavStdResource{
    path:http://example.com/1 | status:202,
    props(2):
      [DAV:]test: WebDavStdResourceProp<dynamic>{name:test,ns:dav:,status:202,value:2024-08-29 11:29:47.000},
      [CUSTOM:]test: WebDavStdResourceProp<dynamic>{name:test,ns:custom:,status:202,value:1970-01-01 12:00:00.000},
  }
  // http://example.com/2
  WebDavStdResource{
    path:http://example.com/2 | status:202,
    props(0):
  }
}
"""
          .trim();
      expect(result.toDebugString(), expectString);
    });
  });
}
