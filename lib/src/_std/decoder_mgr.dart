// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:collection';
import 'dart:convert';

import 'decoder.dart';

class ResponseBodyDecoderManager extends MapBase<String, ResponseBodyDecoder> {
  static final Map<String, ResponseBodyDecoder> _builtins = {
    'utf-8': utf8.decoder,
    'ascii': ascii.decoder,
    'latin-1': latin1.decoder,
    'iso-8859-1': latin1.decoder,
  };

  final Map<String, ResponseBodyDecoder>? _customs;

  const ResponseBodyDecoderManager({
    Map<String, ResponseBodyDecoder>? decoders,
  }) : _customs = decoders;

  Map<String, ResponseBodyDecoder> get _map => _customs ?? const {};

  @override
  ResponseBodyDecoder? operator [](Object? key) {
    if (key is! String) return null;
    final realKey = key.toLowerCase();
    return _map[realKey] ?? _builtins[realKey];
  }

  @override
  void operator []=(String key, ResponseBodyDecoder value) => _map[key] = value;

  @override
  void clear() => _map.clear();

  @override
  Iterable<String> get keys => _map.keys;

  @override
  ResponseBodyDecoder? remove(Object? key) => _map.remove(key);
}
