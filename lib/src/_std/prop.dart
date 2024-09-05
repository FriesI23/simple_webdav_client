// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:collection';

import 'package:xml/xml.dart';

import '../const.dart';
import '../dav/element.dart';
import '../namespace.dart';
import 'depth.dart';
import 'request.dart';

enum LockScope {
  exclusive("exclusive"),
  shared("shared");

  final String name;

  const LockScope(this.name);

  static LockScope? fromName(String name) =>
      LockScope.values.where((e) => e.name == name).firstOrNull;
}

class ResourceTypes
    with IterableMixin<({String name, String? ns})>, ToXmlMixin {
  final List<({String name, String? ns})> _types;

  const ResourceTypes(List<({String name, String? ns})> types) : _types = types;

  ResourceTypes.collection()
      : _types = [
          (name: WebDavElementNames.collection, ns: kDavNamespaceUrlStr)
        ];

  @override
  int get length => _types.length;

  @override
  Iterator<({String name, String? ns})> get iterator => _types.iterator;

  bool get isCollection => _types
      .where((e) =>
          e.ns == kDavNamespaceUrlStr &&
          e.name == WebDavElementNames.collection)
      .isNotEmpty;

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    for (var type in _types) {
      final ns = type.ns;
      if (ns != null && !nsmgr.contain(ns)) nsmgr.generate(ns);
      if (ns != null) context.namespace(ns, nsmgr.getPrefix(ns));
      context.element(type.name, namespace: type.ns);
    }
  }
}

typedef SupportedLock = List<LockEntry>;

class LockEntry {
  final LockScope lockScope;
  final bool isWriteLock;

  const LockEntry({required this.lockScope, required this.isWriteLock});
}

typedef LockDiscovery<O> = List<ActiveLock<O>>;

class ActiveLock<O> {
  final LockScope lockScope;
  final bool isWriteLock;
  final Depth depth;
  final O? owner;
  final double? timeout;
  final Uri? lockToken;
  final Uri? lockRoot;

  const ActiveLock(
      {required this.lockScope,
      required this.isWriteLock,
      required this.depth,
      this.owner,
      this.timeout,
      this.lockToken,
      this.lockRoot});
}
