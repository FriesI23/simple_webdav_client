// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import "dart:io";

import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:simple_webdav_client/src/_std/delete.dart";
import "package:simple_webdav_client/src/_std/depth.dart";
import "package:simple_webdav_client/src/_std/if.dart";
import "package:test/test.dart";

@GenerateMocks([
  HttpClientRequest,
  HttpHeaders,
  IfOr,
])
import "delete_test.mocks.dart";

void main() {
  group("test DeleteRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("constructor", () {
      final param1 = DeleteRequestParam();
      expect(param1.condition, isNull);
      expect(param1.depth, isNull);
      final param2 =
          DeleteRequestParam(depth: Depth.all, condition: MockIfOr());
      expect(param2.condition, equals(TypeMatcher<IfOr>()));
      expect(param2.depth, equals(Depth.all));
    });
    test("constructor.only", () {
      final param = DeleteRequestParam.only(condition: MockIfOr());
      expect(param.depth, Depth.resource);
      expect(param.condition, equals(TypeMatcher<IfOr>()));
    });
    test("constructor.recursive", () {
      final param = DeleteRequestParam.recursive(condition: MockIfOr());
      expect(param.depth, Depth.all);
      expect(param.condition, equals(TypeMatcher<IfOr>()));
    });
    test("toRequestBody", () {
      expect(DeleteRequestParam().toRequestBody(), isNull);
    });
    test("beforeAddRequestBody", () {
      DeleteRequestParam().beforeAddRequestBody(request);
      verifyNever(headers.add("Depth", any));
      verifyNever(headers.add("If", any));
    });
    test("beforeAddRequestBody with param", () {
      final ifOr = MockIfOr();
      DeleteRequestParam(depth: Depth.all, condition: ifOr)
          .beforeAddRequestBody(request);
      verify(headers.add("Depth", Depth.all.name)).called(1);
      verify(headers.add("If", ifOr.toString())).called(1);
    });
  });
}
