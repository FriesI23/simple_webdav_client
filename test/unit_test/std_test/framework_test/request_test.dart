// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:simple_webdav_client/src/_std/decoder_mgr.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/request.dart';
import 'package:simple_webdav_client/src/request.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

@GenerateMocks([
  HttpClientRequest,
  WebDavRequestParam,
  ResponseBodyDecoderManager,
  ResponseResultParser,
])
import 'request_test.mocks.dart';

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
    test("close", () {
      final request = WebDavStdRequest<WebDavRequestParam>(
          request: MockHttpClientRequest(), param: null);
    });
  });
}
