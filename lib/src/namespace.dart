// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '_std/namespace_mgr.dart';

abstract interface class NamespaceManager {
  factory NamespaceManager.std() => StdNamespaceManger();

  Iterable<MapEntry<String, String>> get all;

  String? generate(String uri, {bool noPrefix});

  bool contain(String uri);

  String? getPrefix(String uri);
  String? getUri(String prefix);

  void clear();
}
