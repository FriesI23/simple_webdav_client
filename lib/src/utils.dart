// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:xml/xml.dart';

import 'namespace.dart';

abstract interface class ToXmlCapable {
  void toXml(XmlBuilder context, NamespaceManager nsmgr);
}

extension ContentTypeExtension on ContentType {
  bool get isXml => subType.toLowerCase().contains('xml');
}

extension IterableExtension<T> on Iterable<T?> {
  Iterable<T> whereNotNull() => whereType<T>();
}
