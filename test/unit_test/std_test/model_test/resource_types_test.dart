// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/namespace_mgr.dart';
import 'package:simple_webdav_client/src/_std/prop.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group("test ResourceTypes", () {
    test("constructor", () {
      final ts = ResourceTypes([]);
      expect(ts, TypeMatcher<Iterable>());
      expect(ts, isEmpty);
      expect(ts.isCollection, isFalse);
    });
    test("constructor with collection", () {
      final ts = ResourceTypes([(name: "collection", ns: "DAV:")]);
      expect(ts, TypeMatcher<Iterable>());
      expect(ts, isNotEmpty);
      expect(ts.isCollection, isTrue);
      expect(ts.length, 1);
      expect(ts.first, (name: "collection", ns: "DAV:"));
      final ts2 = ResourceTypes([(name: "collection", ns: null)]);
      expect(ts2, TypeMatcher<Iterable>());
      expect(ts2, isNotEmpty);
      expect(ts2.isCollection, isFalse);
      expect(ts2.length, 1);
    });
    test("constructor.collection", () {
      final ts = ResourceTypes.collection();
      expect(ts, TypeMatcher<Iterable>());
      expect(ts.length, 1);
      expect(ts.isCollection, isTrue);
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final ts = ResourceTypes([]);
      ts.toXml(context, nsmgr);
      expect(context.buildDocument().toString(), '');
    });
    test("toXml with types", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final ts = ResourceTypes(
          [(name: "collection", ns: "DAV:"), (name: "other", ns: "CUSTOM:")]);
      context.element("root", nest: () {
        ts.toXml(context, nsmgr);
      });
      expect(
          context.buildDocument().toString(),
          '<root xmlns:a1="DAV:" xmlns:a2="CUSTOM:">'
          '<a1:collection/><a2:other/></root>');
    });
  });
}
