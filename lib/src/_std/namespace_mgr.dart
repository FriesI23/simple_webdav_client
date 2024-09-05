// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../namespace.dart';

final class StdNamespaceManger implements NamespaceManager {
  final Map<String, String> namespaces = {};
  final Map<String, String> reversedCache = {};
  int index = 0xA1;

  StdNamespaceManger();

  @override
  void clear() {
    namespaces.clear();
    reversedCache.clear();
    index = 0xA1;
  }

  @override
  bool contain(String uri) => namespaces.containsKey(uri);

  String _genNextPrefix(bool noPrefix) {
    if (noPrefix) return "";
    while (reversedCache.containsKey(index.toRadixString(16))) {
      index += 1;
    }
    return index.toRadixString(16);
  }

  @override
  String? generate(String uri, {bool noPrefix = false}) {
    if (uri.isEmpty) return null;
    if (namespaces.containsKey(uri)) return getPrefix(uri);
    final prefix = _genNextPrefix(noPrefix);
    if (reversedCache.containsKey(prefix)) return null;
    namespaces[uri] = prefix;
    reversedCache[prefix] = uri;
    return prefix;
  }

  @override
  String? getPrefix(String uri) => namespaces[uri];

  @override
  String? getUri(String prefix) => reversedCache[prefix];

  @override
  Iterable<MapEntry<String, String>> get all => namespaces.entries;
}
