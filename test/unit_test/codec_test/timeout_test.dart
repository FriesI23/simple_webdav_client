// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/codec/timeout.dart';
import 'package:test/test.dart';

void main() {
  group("test TimeType", () {
    test("codec", () {
      const codec = TimeTypeCodec();
      expect(codec.encoder, same(const TimeTypeEncoder()));
      expect(codec.decoder, same(const TimeTypeDecoder()));
    });
    test("encode", () {
      final encoder = TimeTypeEncoder();
      expect(encoder.convert(123.4), "Second-123");
      expect(encoder.convert(123.5), "Second-124");
      expect(encoder.convert(double.infinity), "Infinite");
      expect(encoder.convert(0.9), "Second-1");
      expect(encoder.convert(0.1), "Second-0");
      expect(encoder.convert(0), "Second-0");
      expect(encoder.convert(-10), "Second-0");
    });
    test("decode", () {
      final decoder = TimeTypeDecoder();
      expect(decoder.convert("Infinite"), double.infinity);
      expect(decoder.convert("Second-10"), 10);
      expect(() => decoder.convert("Secon-10"),
          throwsA(TypeMatcher<RangeError>()));
      expect(() => decoder.convert("Second-xxx0"),
          throwsA(TypeMatcher<FormatException>()));
    });
  });
  group("test timeout", () {
    test("codec", () {
      const codec = DavTimeoutCodec();
      expect(codec.encoder, same(const DavTimeoutEncoder()));
      expect(codec.decoder, same(const DavTimeoutDecoder()));
    });
    test("encode", () {
      final encoder = DavTimeoutEncoder();
      expect(encoder.convert([double.infinity, 123.3, 10]),
          "Infinite, Second-123, Second-10");
      expect(encoder.convert([double.infinity]), "Infinite");
    });
    test("decode", () {
      final decoder = DavTimeoutDecoder();
      expect(decoder.convert("Infinite"), orderedEquals([double.infinity]));
      expect(decoder.convert("Second-999"), orderedEquals([999]));
      expect(decoder.convert("Infinite,Second-123,Second-10"),
          orderedEquals([double.infinity, 123, 10]));
      expect(decoder.convert("Infinite, Second-123, Second-10"),
          orderedEquals([double.infinity, 123, 10]));
      expect(decoder.convert("Infinite,  Second-123,  Second-10"),
          orderedEquals([double.infinity, 123, 10]));
    });
  });
}
