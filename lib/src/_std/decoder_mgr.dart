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

  final Map<String, ResponseBodyDecoder> _customs;

  const ResponseBodyDecoderManager({
    required Map<String, ResponseBodyDecoder> decoders,
  }) : _customs = decoders;

  @override
  ResponseBodyDecoder? operator [](Object? key) {
    if (key is! String) return null;
    return _customs[key] ?? _builtins[key.toLowerCase()];
  }

  @override
  void operator []=(String key, ResponseBodyDecoder value) =>
      _customs[key] = value;

  @override
  void clear() => _customs.clear();

  @override
  Iterable<String> get keys => _customs.keys;

  @override
  ResponseBodyDecoder? remove(Object? key) => _customs.remove(key);
}
