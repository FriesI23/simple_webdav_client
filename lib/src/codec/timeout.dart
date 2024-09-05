// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';
import 'dart:math';

final class TimeTypeCodec extends Codec<double, String> {
  const TimeTypeCodec();

  @override
  Converter<String, double> get decoder => const TimeTypeDecoder();

  @override
  Converter<double, String> get encoder => const TimeTypeEncoder();
}

final class TimeTypeDecoder extends Converter<String, double> {
  const TimeTypeDecoder();

  @override
  double convert(String input) {
    if (input == "Infinite") return double.infinity;
    return double.parse(input.split("Second-")[1]);
  }
}

final class TimeTypeEncoder extends Converter<double, String> {
  const TimeTypeEncoder();

  @override
  String convert(double input) {
    if (input == double.infinity) return "Infinite";
    return "Second-${max(0, input).round()}";
  }
}

final class DavTimeoutCodec extends Codec<Iterable<double>, String> {
  const DavTimeoutCodec();

  @override
  Converter<String, Iterable<double>> get decoder => const DavTimeoutDecoder();

  @override
  Converter<Iterable<double>, String> get encoder => const DavTimeoutEncoder();
}

final class DavTimeoutEncoder extends Converter<Iterable<double>, String> {
  final TimeTypeEncoder typeEncoder;

  const DavTimeoutEncoder({this.typeEncoder = const TimeTypeEncoder()});

  @override
  String convert(Iterable<double> input) =>
      input.map((e) => typeEncoder.convert(e)).join(', ');
}

final class DavTimeoutDecoder extends Converter<String, Iterable<double>> {
  final TimeTypeDecoder typeDecoder;

  const DavTimeoutDecoder({this.typeDecoder = const TimeTypeDecoder()});

  @override
  Iterable<double> convert(String input) =>
      input.split(",").map((e) => e.trim()).map((e) => typeDecoder.convert(e));
}
