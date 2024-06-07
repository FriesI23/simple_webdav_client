// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import '../error.dart';
import '../method.dart';
import '../response.dart';
import 'decoder_mgr.dart';
import 'parser.dart';
import 'resource.dart';

class WebDavStdResponse<T extends WebDavStdResResultView>
    implements WebDavResponse<T> {
  final HttpClientResponse response;
  @override
  final Uri path;
  @override
  final WebDavMethod method;

  final ResponseBodyDecoderManager bodyDecoders;
  final ResponseResultParser<T> resultParser;

  Completer<T?>? _parsing;
  String? _data;

  WebDavStdResponse({
    required this.response,
    required this.path,
    required this.method,
    required this.bodyDecoders,
    required this.resultParser,
  });

  Future<String> _decodeBody() async {
    final contentType = response.headers.contentType;
    final decoder = bodyDecoders[contentType?.charset ?? 'utf-8'];
    if (decoder == null) {
      throw WebDavXmlDecodeError(
          "decode body error, got content type is $contentType, "
          "which not included from ${bodyDecoders.keys.toList()}");
    }
    return response.transform(decoder).join();
  }

  @override
  Future<T?> parse() async {
    if (_parsing != null) return _parsing!.future;
    _parsing = Completer<T?>();
    try {
      final String rawData = _data != null ? _data! : await _decodeBody();
      _data = rawData;
      final result = resultParser.convert(ResponseResultParserParam(
          data: rawData,
          headers: response.headers,
          status: response.statusCode,
          path: path));
      _parsing?.complete(result);
    } on Exception {
      if (_parsing != null) _parsing!.complete(null);
      _parsing = null;
      rethrow;
    }
    return _parsing?.future;
  }
}

typedef WebDavStdResResultView = WebDavResponseResultView<WebDavStdResource>;

class WebDavStdResponseResult
    with IterableMixin<WebDavStdResource>
    implements WebDavStdResResultView, WebDavResponseResult<WebDavStdResource> {
  final Map<Uri, WebDavStdResource> _resources;

  WebDavStdResponseResult() : _resources = {};

  const WebDavStdResponseResult.fromMap(Map<Uri, WebDavStdResource> resources)
      : _resources = resources;

  @override
  bool add(WebDavStdResource resource) =>
      _resources.putIfAbsent(resource.path, () => resource) == resource;

  @override
  void clear() => _resources.clear();

  @override
  bool contain(Uri path) => _resources.containsKey(path);

  @override
  WebDavStdResource? find(Uri path) => _resources[path];

  @override
  Iterator<WebDavStdResource> get iterator => _resources.values.iterator;

  @override
  WebDavStdResource? remove(Uri path) => _resources.remove(path);

  @override
  String toDebugString() {
    final sb = StringBuffer();
    sb.writeln("WebDavStdResponseResult{");
    for (var entry in _resources.entries) {
      sb.writeln("  // ${entry.key}");
      sb.writeln(entry.value
          .toDebugString()
          .split("\n")
          .map((e) => "  $e")
          .join('\n'));
    }
    sb.write("}");
    return sb.toString();
  }
}
