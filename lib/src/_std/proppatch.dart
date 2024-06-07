// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:xml/xml.dart';

import '../const.dart';
import '../dav/element.dart';
import '../dav/prop.dart';
import '../namespace.dart';
import '../request.dart';
import '../utils.dart';
import 'if.dart';
import 'request.dart';

enum ProppatchRequestOp { set, remove }

final class ProppatchRequestParam<P extends ProppatchRequestProp>
    with ToXmlMixin, IfHeaderRequestMixin
    implements WebDavRequestParam, ToXmlCapable {
  static Iterable<
          ({ProppatchRequestOp op, Iterable<ProppatchRequestProp> props})>
      groupPropsByOp(Iterable<ProppatchRequestProp> props) {
    final result =
        <({ProppatchRequestOp op, List<ProppatchRequestProp> props})>[];
    var currentProps = <ProppatchRequestProp>[];
    ProppatchRequestOp? currentOp;
    for (var prop in props) {
      if (currentOp != prop.op) {
        currentOp = prop.op;
        currentProps = [];
        result.add((op: prop.op, props: currentProps));
      }
      currentProps.add(prop);
    }
    return result;
  }

  @override
  final IfOr? condition;

  final List<P> _operations;

  @override
  String toRequestBody() => processXmlData().buildDocument().toXmlString();

  const ProppatchRequestParam({required List<P> ops, this.condition})
      : _operations = ops;

  Iterable<P> get operations => _operations;

  @override
  void beforeAddRequestBody(HttpClientRequest request) {}

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    const davns = kDavNamespaceUrlStr;
    nsmgr.generate(davns);
    for (var p in operations) {
      final ns = p.namespace;
      if (ns != null) nsmgr.generate(ns);
    }
    context.element(
      WebDavElementNames.propertyupdate,
      namespace: davns,
      namespaces: Map.fromEntries(nsmgr.all),
      nest: () {
        for (var groupPiece in groupPropsByOp(_operations)) {
          context.element(
            groupPiece.op.name,
            namespace: davns,
            nest: () {
              for (var prop in groupPiece.props) {
                prop.toXml(context, nsmgr);
              }
            },
          );
        }
      },
    );
  }
}

final class ProppatchRequestProp<V extends ToXmlCapable>
    implements Prop<V>, ToXmlCapable {
  @override
  final String name;
  @override
  final String? namespace;
  @override
  final V? value;

  final ProppatchRequestOp op;
  final String? lang;

  const ProppatchRequestProp({
    required this.name,
    this.namespace,
    required this.op,
    this.value,
    this.lang,
  });

  const ProppatchRequestProp.set({
    required this.name,
    this.namespace,
    this.value,
    this.lang,
  }) : op = ProppatchRequestOp.set;

  const ProppatchRequestProp.remove({
    required this.name,
    this.namespace,
    this.lang,
  })  : op = ProppatchRequestOp.remove,
        value = null;

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    final Map<String, String?> namespaces;
    final namespace = this.namespace;
    switch (namespace) {
      case null:
        namespaces = const {};
      case "":
        namespaces = const {"": null};
      default:
        if (!nsmgr.contain(namespace)) {
          namespaces = {namespace: nsmgr.generate(namespace)};
        } else {
          namespaces = const {};
        }
    }
    final value = this.value;
    final lang = this.lang;
    context.element(
      name,
      namespace: namespace,
      namespaces: namespaces,
      attributes: lang != null ? {kXmlLangAttrName: lang} : const {},
      nest: value != null ? () => value.toXml(context, nsmgr) : null,
    );
  }
}

final class ProppatchReqPropBaseValue<T> implements ToXmlCapable {
  final T value;

  const ProppatchReqPropBaseValue(this.value);

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    context.text(value.toString());
  }
}

final class ProppatchReqLastModifiedValue implements ToXmlCapable {
  final DateTime value;

  const ProppatchReqLastModifiedValue(this.value);

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    context.text(HttpDate.format(value));
  }
}
