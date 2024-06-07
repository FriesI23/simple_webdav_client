// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:collection';
import 'dart:convert';

import '../const.dart';
import '../dav/element.dart';
import 'parser.dart';
import 'resource.dart';

class WebDavResposneDataParserManger
    with MapMixin<({String name, String? ns}), Converter> {
  final Map<({String name, String? ns}), Converter>? _parsers;

  const WebDavResposneDataParserManger({
    Map<({String name, String? ns}), Converter>? parsers,
  }) : _parsers = parsers;

  Map<({String name, String? ns}), Converter> get _map => _parsers ?? const {};

  @override
  Converter? operator [](Object? key) => _map[key];

  @override
  void operator []=(({String name, String? ns}) key, Converter value) =>
      _map[key] = value;

  @override
  void clear() => _map.clear();

  @override
  Iterable<({String name, String? ns})> get keys => _map.keys;

  @override
  Converter? remove(Object? key) => _map.remove(key);

  PropElementParser<T>? fetchPropParser<T extends WebDavStdResourceProp>(
      String name, String? namespace) {
    final Converter? result = _map[(name: name, ns: namespace)];
    return result is PropElementParser<T> ? result : null;
  }

  void _setOrRemove(({String name, String? ns}) key, dynamic parser) =>
      parser != null ? _map[key] = parser : _map.remove(key);

  ErrorElementParser? get error =>
      _map[const (name: WebDavElementNames.error, ns: kDavNamespaceUrlStr)]
          as ErrorElementParser?;
  set error(ErrorElementParser? parser) => _setOrRemove(
      const (name: WebDavElementNames.error, ns: kDavNamespaceUrlStr), parser);

  PropstatElementParser? get propstat =>
      _map[const (name: WebDavElementNames.propstat, ns: kDavNamespaceUrlStr)]
          as PropstatElementParser?;
  set propstat(PropstatElementParser? parser) => _setOrRemove(
      const (name: WebDavElementNames.propstat, ns: kDavNamespaceUrlStr),
      parser);

  ResponseElementParser? get response =>
      _map[const (name: WebDavElementNames.response, ns: kDavNamespaceUrlStr)]
          as ResponseElementParser?;
  set response(ResponseElementParser? parser) => _setOrRemove(
      const (name: WebDavElementNames.response, ns: kDavNamespaceUrlStr),
      parser);

  MultiStatusElementParser? get multistatus => _map[const (
        name: WebDavElementNames.multistatus,
        ns: kDavNamespaceUrlStr
      )] as MultiStatusElementParser?;
  set multistatus(MultiStatusElementParser? parser) => _setOrRemove(
      const (name: WebDavElementNames.multistatus, ns: kDavNamespaceUrlStr),
      parser);

  HrefElementParser? get href =>
      _map[const (name: WebDavElementNames.href, ns: kDavNamespaceUrlStr)]
          as HrefElementParser?;
  set href(HrefElementParser? parser) => _setOrRemove(
      const (name: WebDavElementNames.href, ns: kDavNamespaceUrlStr), parser);

  HrefElementParser? get location =>
      _map[const (name: WebDavElementNames.location, ns: kDavNamespaceUrlStr)]
          as HrefElementParser?;
  set location(HrefElementParser? parser) => _setOrRemove(
      const (name: WebDavElementNames.location, ns: kDavNamespaceUrlStr),
      parser);

  HttpStatusElementParser? get status =>
      _map[const (name: WebDavElementNames.status, ns: kDavNamespaceUrlStr)]
          as HttpStatusElementParser?;
  set status(HttpStatusElementParser? parser) => _setOrRemove(
      const (name: WebDavElementNames.status, ns: kDavNamespaceUrlStr), parser);
}
