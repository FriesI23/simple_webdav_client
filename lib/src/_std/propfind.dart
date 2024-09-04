// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:xml/xml.dart';

import '../const.dart';
import '../dav/element.dart';
import '../dav/prop.dart';
import '../namespace.dart';
import '../utils.dart';
import '_param.dart';

final class PropfindPropRequestParam<P extends PropfindRequestProp>
    extends CommonPropfindRequestParam {
  final List<P>? _props;

  const PropfindPropRequestParam({super.depth, List<P>? props})
      : _props = props;

  Iterable<P> get props => _props ?? const [];

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    const davns = kDavNamespaceUrlStr;
    nsmgr.generate(davns);
    for (var p in props) {
      final ns = p.namespace;
      if (ns != null) nsmgr.generate(ns);
    }
    context.element(
      WebDavElementNames.propfind,
      namespace: davns,
      namespaces: Map.fromEntries(nsmgr.all.where((e) => e.value.isNotEmpty)),
      nest: () {
        context.element(
          WebDavElementNames.prop,
          namespace: davns,
          nest: () {
            for (var prop in _props ?? const []) {
              prop.toXml(context, nsmgr);
            }
          },
        );
      },
    );
  }

  @override
  String toRequestBody() => processXmlData().buildDocument().toXmlString();
}

final class PropfindAllRequestParam<P extends PropfindRequestProp>
    extends CommonPropfindRequestParam {
  final List<P>? _includes;

  const PropfindAllRequestParam({super.depth, List<P>? include})
      : _includes = include;

  Iterable<P> get includes => _includes ?? const [];

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    const davns = kDavNamespaceUrlStr;
    nsmgr.generate(davns);
    for (var p in includes) {
      final ns = p.namespace;
      if (ns != null) nsmgr.generate(ns);
    }
    context.element(
      WebDavElementNames.propfind,
      namespace: davns,
      namespaces: Map.fromEntries(nsmgr.all),
      nest: () {
        context.element(WebDavElementNames.allprop, namespace: davns);
        if (_includes != null) {
          context.element(
            WebDavElementNames.include,
            namespace: davns,
            nest: () {
              for (var prop in _includes ?? const []) {
                prop.toXml(context, nsmgr);
              }
            },
          );
        }
      },
    );
  }

  @override
  String toRequestBody() => processXmlData().buildDocument().toXmlString();
}

final class PropfindNameRequestParam extends CommonPropfindRequestParam {
  const PropfindNameRequestParam({super.depth});

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    const davns = kDavNamespaceUrlStr;
    nsmgr.generate(davns);
    context.element(
      WebDavElementNames.propfind,
      namespace: davns,
      namespaces: Map.fromEntries(nsmgr.all),
      nest: () {
        context.element(WebDavElementNames.propname, namespace: davns);
      },
    );
  }

  @override
  String toRequestBody() => processXmlData().buildDocument().toXmlString();
}

class PropfindRequestProp implements Prop<Null>, ToXmlCapable {
  @override
  final String name;
  @override
  final String? namespace;

  @override
  Null get value => null;

  const PropfindRequestProp(this.name, [this.namespace]);

  const PropfindRequestProp.dav(this.name) : namespace = kDavNamespaceUrlStr;

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
    context.element(name, namespace: namespace, namespaces: namespaces);
  }
}
