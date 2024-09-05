// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';

import 'package:mockito/annotations.dart';
import 'package:simple_webdav_client/src/_std/decoder.dart';
import 'package:simple_webdav_client/src/_std/decoder_mgr.dart';
import 'package:test/test.dart';

@GenerateMocks([
  ResponseBodyDecoder,
])
import 'decoder_mgr_test.mocks.dart';

void main() {
  group('test ResponseBodyDecoderManager', () {
    test("constructor", () {
      const mgr = ResponseBodyDecoderManager(decoders: {});
      expect(mgr, TypeMatcher<Map>());
      expect(mgr, isEmpty);
      final mgr2 = ResponseBodyDecoderManager(
          decoders: {'utf-18': MockResponseBodyDecoder()});
      expect(mgr2.length, 1);
      expect(mgr2['utf-18'], TypeMatcher<ResponseBodyDecoder>());
    });
    test("operator[]", () {
      final mgr = ResponseBodyDecoderManager(
          decoders: {'utf-18': MockResponseBodyDecoder()});
      expect(mgr['test'], isNull);
      expect(mgr['utf-18'], TypeMatcher<ResponseBodyDecoder>());
      expect(mgr['UTF-18'], isNull);
    });
    test("operator[] with builtin", () {
      final mgr = ResponseBodyDecoderManager(decoders: {});
      expect(mgr['utf-8'], utf8.decoder);
      expect(mgr['UTF-8'], utf8.decoder);
    });
    test("operator[]=", () {
      final mgr = ResponseBodyDecoderManager(decoders: {});
      expect(mgr['utf-18'], isNull);
      mgr['utf-18'] = MockResponseBodyDecoder();
      expect(mgr['utf-18'], TypeMatcher<ResponseBodyDecoder>());
      expect(mgr['utf-8'], utf8.decoder);
      mgr['UTF-8'] = MockResponseBodyDecoder();
      expect(mgr['UTF-8'], isNot(equals(utf8.decoder)));
      expect(mgr['utf-8'], utf8.decoder);
      mgr['utf-8'] = MockResponseBodyDecoder();
      expect(mgr['utf-8'], isNot(equals(utf8.decoder)));
    });
    test("clear", () {
      final mgr = ResponseBodyDecoderManager(
          decoders: {'utf-18': MockResponseBodyDecoder()});
      expect(mgr, isNotEmpty);
      mgr.clear();
      expect(mgr, isEmpty);
    });
    test("keys", () {
      final mgr = ResponseBodyDecoderManager(decoders: {});
      expect(mgr.keys, isEmpty);
      final mgr2 = ResponseBodyDecoderManager(
          decoders: {'utf-18': MockResponseBodyDecoder()});
      expect(mgr2.keys, equals(['utf-18']));
    });
    test("remove", () {
      final mgr = ResponseBodyDecoderManager(
          decoders: {'utf-18': MockResponseBodyDecoder()});
      expect(mgr['utf-18'], TypeMatcher<ResponseBodyDecoder>());
      mgr.remove('utf-18');
      expect(mgr['utf-18'], isNull);
      expect(mgr, isEmpty);
    });
  });
}
