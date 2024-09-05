// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/namespace_mgr.dart';
import 'package:test/test.dart';

void main() {
  group("test StdNamespaceManger", () {
    late StdNamespaceManger mgr;

    setUp(() {
      mgr = StdNamespaceManger();
    });

    test("constructor", () {
      expect(mgr.namespaces, isEmpty);
      expect(mgr.reversedCache, isEmpty);
      expect(mgr.index, 0xa1);
    });
    test("generate and other methods", () {
      // generate DAV: -> a1
      expect(mgr.generate("DAV:"), 'a1');
      expect(mgr.namespaces, {"DAV:": "a1"});
      expect(mgr.reversedCache, {"a1": "DAV:"});
      expect(mgr.getPrefix("DAV:"), "a1");
      expect(mgr.getUri("a1"), "DAV:");
      expect(mgr.all.length, 1);
      expect(mgr.contain("DAV:"), isTrue);
      expect(mgr.contain("XXX:"), isFalse);
      expect(mgr.index, 0xa1);
      // generate CUSTOM: -> a2
      expect(mgr.generate("CUSTOM:"), 'a2');
      expect(mgr.namespaces, {"DAV:": "a1", "CUSTOM:": "a2"});
      expect(mgr.reversedCache, {"a1": "DAV:", "a2": "CUSTOM:"});
      expect(mgr.getPrefix("CUSTOM:"), "a2");
      expect(mgr.getUri("a2"), "CUSTOM:");
      expect(mgr.all.length, 2);
      expect(mgr.contain("DAV:"), isTrue);
      expect(mgr.contain("CUSTOM:"), isTrue);
      expect(mgr.contain("CUSTOM_1:"), isFalse);
      expect(mgr.index, 0xa2);
      // generate(duplicated) DAV: -> a1
      expect(mgr.generate("DAV:"), 'a1');
      expect(mgr.namespaces, {"DAV:": "a1", "CUSTOM:": "a2"});
      expect(mgr.reversedCache, {"a1": "DAV:", "a2": "CUSTOM:"});
      expect(mgr.getPrefix("CUSTOM:"), "a2");
      expect(mgr.getUri("a2"), "CUSTOM:");
      expect(mgr.all.length, 2);
      expect(mgr.contain("DAV:"), isTrue);
      expect(mgr.contain("CUSTOM:"), isTrue);
      expect(mgr.contain("CUSTOM_1:"), isFalse);
      expect(mgr.getPrefix("DAV:"), "a1");
      expect(mgr.getUri("a1"), "DAV:");
      expect(mgr.contain("DAV:"), isTrue);
      expect(mgr.contain("XXX:"), isFalse);
      expect(mgr.index, 0xa2);
      // generate(noprefix) CUSTOM1: -> ""
      expect(mgr.generate("CUSTOM_1:", noPrefix: true), "");
      expect(mgr.namespaces, {"DAV:": "a1", "CUSTOM:": "a2", "CUSTOM_1:": ""});
      expect(
          mgr.reversedCache, {"a1": "DAV:", "a2": "CUSTOM:", "": "CUSTOM_1:"});
      expect(mgr.getPrefix("CUSTOM_1:"), "");
      expect(mgr.getUri(""), "CUSTOM_1:");
      expect(mgr.all.length, 3);
      expect(mgr.contain("CUSTOM_1:"), isTrue);
      expect(mgr.contain("CUSTOM_2:"), isFalse);
      expect(mgr.index, 0xa2);
      // generate(noprefix|duplicated) CUSTOM_2: -> ""
      expect(mgr.generate("CUSTOM_2:", noPrefix: true), null);
      expect(mgr.namespaces, {"DAV:": "a1", "CUSTOM:": "a2", "CUSTOM_1:": ""});
      expect(
          mgr.reversedCache, {"a1": "DAV:", "a2": "CUSTOM:", "": "CUSTOM_1:"});
      expect(mgr.getPrefix("CUSTOM_1:"), "");
      expect(mgr.getPrefix("CUSTOM_2:"), isNull);
      expect(mgr.getUri(""), "CUSTOM_1:");
      expect(mgr.all.length, 3);
      expect(mgr.contain("CUSTOM_1:"), isTrue);
      expect(mgr.contain("CUSTOM_2:"), isFalse);
      expect(mgr.index, 0xa2);
      // clear
      mgr.clear();
      expect(mgr.namespaces, isEmpty);
      expect(mgr.reversedCache, isEmpty);
      expect(mgr.index, 0xa1);
      expect(mgr.getPrefix("DAV:"), isNull);
      expect(mgr.getPrefix("CUSTOM:"), isNull);
      expect(mgr.getPrefix("CUSTOM_1:"), isNull);
      expect(mgr.getPrefix("CUSTOM_2:"), isNull);
      expect(mgr.getUri("a1"), isNull);
      expect(mgr.getUri("a2"), isNull);
      expect(mgr.getUri(""), isNull);
      expect(mgr.all, isEmpty);
      expect(mgr.contain("DAV:"), isFalse);
      expect(mgr.contain("CUSTOM:"), isFalse);
      expect(mgr.contain("CUSTOM_1:"), isFalse);
      expect(mgr.contain("CUSTOM_2:"), isFalse);
    });
  });
}
