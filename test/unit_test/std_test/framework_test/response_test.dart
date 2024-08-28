// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';
import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/decoder_mgr.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/response.dart';
import 'package:simple_webdav_client/src/error.dart';
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
}
