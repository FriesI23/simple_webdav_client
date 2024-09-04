// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/unlock.dart';
import 'package:test/test.dart';

@GenerateMocks([
  HttpClientRequest,
  HttpHeaders,
])
import 'unlock_test.mocks.dart';

void main() {
  group("test UnlockRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("constructor", () {
      final param = UnlockRequestParam(lockToken: Uri.parse("http://example"));
      expect(param.lockToken, Uri.parse("http://example"));
    });
    test("beforeAddRequestBody", () {
      UnlockRequestParam(lockToken: Uri.parse("http://example"))
          .beforeAddRequestBody(request);
      verify(headers.add("Lock-Token", "<http://example>"));
    });
    test("toRequestBody", () {
      expect(
          UnlockRequestParam(lockToken: Uri.parse("http://example"))
              .toRequestBody(),
          null);
    });
  });
}
