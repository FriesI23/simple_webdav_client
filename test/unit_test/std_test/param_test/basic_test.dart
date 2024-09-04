// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/_param.dart';
import 'package:simple_webdav_client/src/_std/copy.dart';
import 'package:simple_webdav_client/src/_std/depth.dart';
import 'package:simple_webdav_client/src/_std/if.dart';
import 'package:test/test.dart';

@GenerateMocks([
  HttpClientRequest,
  HttpHeaders,
  IfOr,
])
import "basic_test.mocks.dart";

void main() {
  group("test CommonCopyMoveRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("constructor", () {
      final param1 = CommonCopyMoveRequestParam(destination: Uri.base);
      expect(param1.condition, isNull);
      expect(param1.depth, isNull);
      expect(param1.destination, equals(Uri.base));
      expect(param1.overwrite, isNull);
      final param2 = CommonCopyMoveRequestParam(
          destination: Uri.base,
          overwrite: false,
          depth: Depth.resource,
          condition: MockIfOr());
      expect(param2.condition, TypeMatcher<IfOr>());
      expect(param2.depth, Depth.resource);
      expect(param2.destination, equals(Uri.base));
      expect(param2.overwrite, isFalse);
    });

    test("toRequestBody", () {
      expect(CommonCopyMoveRequestParam(destination: Uri.base).toRequestBody(),
          isNull);
    });
    test("beforeAddRequestBody", () {
      CommonCopyMoveRequestParam(destination: Uri.parse("/path"))
          .beforeAddRequestBody(request);
      verify(headers.add("Destination", "/path")).called(1);
      verifyNever(headers.add("Depth", any));
      verifyNever(headers.add("Overwrite", any));
      verifyNever(headers.add("If", any));
    });
    test("beforeAddRequestBody with params", () {
      final ifOr = MockIfOr();
      CommonCopyMoveRequestParam(
              destination: Uri.parse("/path"),
              depth: Depth.all,
              overwrite: true,
              condition: ifOr)
          .beforeAddRequestBody(request);
      verify(headers.add("Destination", "/path")).called(1);
      verify(headers.add("Depth", Depth.all.name)).called(1);
      verify(headers.add("Overwrite", "T")).called(1);
      verify(headers.add("If", ifOr.toString())).called(1);
    });
    test("beforeAddRequestBody with overwirte is false", () {
      final ifOr = MockIfOr();
      CommonCopyMoveRequestParam(
              destination: Uri.parse("/path"),
              depth: Depth.resource,
              overwrite: false,
              condition: ifOr)
          .beforeAddRequestBody(request);
      verify(headers.add("Destination", "/path")).called(1);
      verify(headers.add("Depth", Depth.resource.name)).called(1);
      verify(headers.add("Overwrite", "F")).called(1);
      verify(headers.add("If", ifOr.toString())).called(1);
    });
  });
  group("test CommonDataRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("constructor", () {
      final param1 = CommonDataRequestParam<String>(data: "mock");
      expect(param1.data, "mock");
      expect(param1.condition, isNull);
      final param2 =
          CommonDataRequestParam<int>(data: 123, condition: MockIfOr());
      expect(param2.data, 123);
      expect(param2.condition, equals(TypeMatcher<IfOr>()));
    });

    test("toRequestBody", () {
      expect(CommonDataRequestParam(data: 123.45).toRequestBody(), "123.45");
      expect(CommonDataRequestParam(data: null).toRequestBody(), isNull);
    });

    test("beforeAddRequestBody", () {
      CommonDataRequestParam(data: null).beforeAddRequestBody(request);
      verifyNever(headers.add("If", any));
    });
    test("beforeAddRequestBody with condition", () {
      final ifOr = MockIfOr();
      CommonDataRequestParam(data: null, condition: ifOr)
          .beforeAddRequestBody(request);
      verify(headers.add("If", ifOr.toString())).called(1);
    });
  });
  group("test CopyRequestParam", () {
    test("constructor", () {
      final param = CopyRequestParam(destination: Uri.base);
      expect(param.destination, Uri.base);
      expect(param.depth, isNull);
      expect(param.overwrite, isNull);
      expect(param.condition, isNull);
    });
    test("constructor with params", () {
      final param = CopyRequestParam(
          destination: Uri.base,
          recursive: false,
          overwrite: true,
          condition: MockIfOr());
      expect(param.destination, Uri.base);
      expect(param.depth, Depth.resource);
      expect(param.overwrite, isTrue);
      expect(param.condition, equals(TypeMatcher<IfOr>()));
    });
    test("constructor when recursive is true", () {
      final param = CopyRequestParam(
          destination: Uri.base,
          recursive: true,
          overwrite: false,
          condition: MockIfOr());
      expect(param.destination, Uri.base);
      expect(param.depth, Depth.all);
      expect(param.overwrite, isFalse);
      expect(param.condition, equals(TypeMatcher<IfOr>()));
    });
  });
}
