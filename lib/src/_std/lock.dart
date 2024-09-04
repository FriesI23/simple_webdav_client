// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:xml/xml.dart';

import '../const.dart';
import '../dav/element.dart';
import '../namespace.dart';
import '../request.dart';
import '../utils.dart';
import 'depth.dart';
import 'if.dart';
import 'prop.dart';
import 'request.dart';
import 'timeout.dart';

final class LockRequestParam
    with ToXmlMixin, IfHeaderRequestMixin
    implements WebDavRequestParam, ToXmlCapable {
  @override
  final IfOr? condition;

  final Depth? depth;
  final LockInfo? lockInfo;
  final Timeout? timeout;

  const LockRequestParam(
      {required LockInfo this.lockInfo,
      this.timeout,
      bool? recursive,
      this.condition})
      : depth =
            recursive != null ? (recursive ? Depth.all : Depth.resource) : null;

  const LockRequestParam.renew(
      {required IfOr this.condition, this.timeout, bool? recursive})
      : lockInfo = null,
        depth =
            recursive != null ? (recursive ? Depth.all : Depth.resource) : null;

  @override
  void beforeAddRequestBody(HttpClientRequest request) {
    final depth = this.depth;
    if (depth != null) {
      request.headers.add(Depth.headerKey, depth.name);
    }
    final timeout = this.timeout;
    if (timeout != null) {
      request.headers.add("Timeout", timeout.toString());
    }
    final condition = this.condition;
    if (condition != null) {
      request.headers.add("If", condition.toString());
    }
  }

  @override
  String? toRequestBody() =>
      lockInfo != null ? processXmlData().buildDocument().toXmlString() : null;

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) =>
      lockInfo?.toXml(context, nsmgr);
}

class LockInfo<O extends ToXmlCapable> implements ToXmlCapable {
  final LockScope lockScope;
  final O? owner;

  const LockInfo({required this.lockScope, this.owner});

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    const davns = kDavNamespaceUrlStr;
    context.element(
      WebDavElementNames.lockinfo,
      namespace: davns,
      namespaces: Map.fromEntries(nsmgr.all),
      nest: () {
        if (!nsmgr.contain(davns)) {
          context.namespace(davns, nsmgr.generate(davns));
        }
        context.element(WebDavElementNames.lockscope,
            namespace: davns,
            nest: () => context.element(lockScope.name, namespace: davns));
        context.element(WebDavElementNames.locktype,
            namespace: davns,
            nest: () => context.element("write", namespace: davns));
        final owner = this.owner;
        if (owner != null) {
          context.element(WebDavElementNames.owner,
              namespace: davns, nest: () => owner.toXml(context, nsmgr));
        }
      },
    );
  }
}
