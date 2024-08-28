// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/const.dart';
import 'package:simple_webdav_client/src/_std/decoder_mgr.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/request.dart';
import 'package:simple_webdav_client/src/_std/response.dart';
import 'package:simple_webdav_client/src/method.dart';
import 'package:simple_webdav_client/src/namespace.dart';
import 'package:simple_webdav_client/src/request.dart';
import 'package:test/test.dart';
import 'package:xml/src/xml/builder.dart';

@GenerateMocks([
  HttpClientRequest,
  HttpClientResponse,
  WebDavRequestParam,
  ResponseBodyDecoderManager,
  ResponseResultParser,
])
import 'request_test.mocks.dart';

final class _ToXmlMixinStub with ToXmlMixin {
  void Function(XmlBuilder context, NamespaceManager nsmgr)? toXmlFunc;

  _ToXmlMixinStub({this.toXmlFunc});

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    toXmlFunc?.call(context, nsmgr);
  }
}

void main() {
  group("test WebDavStdRequest", () {
    test("constructor", () {
      final request = WebDavStdRequest<WebDavRequestParam>(
          request: MockHttpClientRequest(), param: null);
      expect(request.request, equals(TypeMatcher<HttpClientRequest>()));
      expect(request.responseBodyDecoders, isNull);
      expect(request.responseResultParser, isNull);
      expect(request.param, isNull);
    });
    test("constructor with params", () {
      final request = WebDavStdRequest<WebDavRequestParam>(
        request: MockHttpClientRequest(),
        param: MockWebDavRequestParam(),
        responseBodyDecoders: MockResponseBodyDecoderManager(),
        responseResultParser: MockResponseResultParser(),
      );
      expect(request.request, equals(TypeMatcher<HttpClientRequest>()));
      expect(request.responseBodyDecoders,
          equals(TypeMatcher<ResponseBodyDecoderManager>()));
      expect(request.responseResultParser,
          equals(TypeMatcher<ResponseResultParser>()));
      expect(request.param, equals(TypeMatcher<WebDavRequestParam>()));
    });
    test("close", () async {
      final method = WebDavMethod.get;
      final httpRequest = MockHttpClientRequest();
      when(httpRequest.uri).thenReturn(Uri.base);
      when(httpRequest.method).thenReturn(method.name);
      when(httpRequest.close())
          .thenAnswer((_) => Future.value(MockHttpClientResponse()));
      final request = WebDavStdRequest<WebDavRequestParam>(
          request: httpRequest, param: null);
      final response = await request.close();
      expect(response, equals(TypeMatcher<WebDavStdResponse>()));
      expect(response.response, equals(TypeMatcher<HttpClientResponse>()));
      expect(response.path, equals(Uri.base));
      expect(response.method, equals(method));
      expect(response.bodyDecoders, kStdDecoderManager);
      expect(response.resultParser, kStdResponseResultParser);
    });
    test("close with params", () async {
      final param = MockWebDavRequestParam();
      when(param.toRequestBody()).thenReturn('123');
      final bodyDecoderMgr = MockResponseBodyDecoderManager();
      final resultParserMgr = MockResponseResultParser();
      final method = WebDavMethod.get;
      final httpRequest = MockHttpClientRequest();
      when(httpRequest.uri).thenReturn(Uri.base);
      when(httpRequest.method).thenReturn(method.name);
      when(httpRequest.write('123')).thenReturn(null);
      when(httpRequest.close())
          .thenAnswer((_) => Future.value(MockHttpClientResponse()));
      final request = WebDavStdRequest<WebDavRequestParam>(
          request: httpRequest,
          param: param,
          responseBodyDecoders: bodyDecoderMgr,
          responseResultParser: resultParserMgr);
      final response = await request.close();
      verify(param.beforeAddRequestBody(httpRequest)).called(1);
      verify(param.toRequestBody()).called(1);
      verify(httpRequest.write("123")).called(1);
      expect(response, equals(TypeMatcher<WebDavStdResponse>()));
      expect(response.response, equals(TypeMatcher<HttpClientResponse>()));
      expect(response.method, equals(method));
      expect(response.path, equals(Uri.base));
      expect(response.bodyDecoders, same(bodyDecoderMgr));
      expect(response.resultParser, same(resultParserMgr));
    });
  });
  group("test ToXmlMixin", () {
    test("processXmlData", () {
      final obj = _ToXmlMixinStub(
        toXmlFunc: (context, nsmgr) {
          context.element("test");
          expect(nsmgr, equals(TypeMatcher<NamespaceManager>()));
        },
      );
      final builder = obj.processXmlData();
      final result = builder.buildDocument();
      expect(result.toXmlString(),
          '<?xml version="1.0" encoding="utf-8"?><test/>');
    });
  });
}
