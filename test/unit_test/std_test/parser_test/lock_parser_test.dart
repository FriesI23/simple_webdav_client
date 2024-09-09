// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';
import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/depth.dart';
import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/prop.dart';
import 'package:simple_webdav_client/src/const.dart';
import 'package:simple_webdav_client/src/error.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  LockScopeElementParser,
  WriteLockElementParser,
  LockEntryElementParser,
  ActiveLockElementParser,
  NestedHrefElementParser,
  Converter,
  ActiveLock,
  LockEntry,
])
import 'lock_parser_test.mocks.dart';

void main() {
  group("test BaseLockScopeElementParser", () {
    test("convert lockscope:exclusive", () {
      final parser = BaseLockScopeElementParser();
      final input = XmlDocument.parse("""
<lockscope>
  <exclusive/>
  <!-- only match first element -->
  <shared/>
</lockscope>
"""
          .trim());
      final result = parser.convert(input.rootElement);
      expect(result, LockScope.exclusive);
    });
    test("convert lockscope:shared", () {
      final parser = BaseLockScopeElementParser();
      final input = XmlDocument.parse("""
<lockscope>
  <shared/>
</lockscope>
"""
          .trim());
      final result = parser.convert(input.rootElement);
      expect(result, LockScope.shared);
    });
    test("convert lockscope:unknown", () {
      final parser = BaseLockScopeElementParser();
      final input = XmlDocument.parse("""
<lockscope>
  <noshared/>
</lockscope>
"""
          .trim());
      final result = parser.convert(input.rootElement);
      expect(result, isNull);
    });
    test("convert no lockscope", () {
      final parser = BaseLockScopeElementParser();
      final input = XmlDocument.parse("""
<lockscope>
</lockscope>
"""
          .trim());
      final result = parser.convert(input.rootElement);
      expect(result, isNull);
    });
  });
  group("test BaseWriteLockElementParser", () {
    test("convert is write lock", () {
      final parser = BaseWriteLockElementParser();
      final input = XmlDocument.parse("""
<root>
  <write/>
</root>
"""
          .trim());
      final result = parser.convert(input.rootElement);
      expect(result, isTrue);
    });
    test("convert is not write lock", () {
      final parser = BaseWriteLockElementParser();
      final input = XmlDocument.parse("""
<root>
</root>
"""
          .trim());
      final result = parser.convert(input.rootElement);
      expect(result, isFalse);
    });
  });
  group("test SupportedLockPropParser", () {
    test("convert", () {
      final entryParser = MockLockEntryElementParser();
      final parser = SupportedLockPropParser(pieceParser: entryParser);
      final result = parser.convert((
        desc: null,
        error: null,
        node: XmlDocument.parse("<prop1></prop1>").rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, isNull);
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.lang, isNull);
      expect(result.value, isEmpty);
    });
    test("convert with null lockEntry", () {
      final entryParser = MockLockEntryElementParser();
      when(entryParser.convert(any)).thenReturn(null);
      final parser = SupportedLockPropParser(pieceParser: entryParser);
      final result = parser.convert((
        desc: null,
        error: null,
        node: XmlDocument.parse("""
<D:prop1 xmlns:D=DAV:>
  <D:lockentry/>
  <D:lockentry/>
  <D:lockentry/>
</D:prop1>
"""
                .trim())
            .rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.lang, isNull);
      expect(result.value, isEmpty);
    });
    test("convert, full case", () {
      final entryParser = MockLockEntryElementParser();
      when(entryParser.convert(any)).thenReturn(MockLockEntry());
      final parser = SupportedLockPropParser(pieceParser: entryParser);
      final result = parser.convert((
        desc: 'test',
        error: WebDavStdResError("mock"),
        node: XmlDocument.parse("""
<D:prop1 xml:lang=en-us xmlns:D=DAV:>
  <D:lockentry/>
  <D:lockentry/>
  <D:lockentry/>
</D:prop1>
"""
                .trim())
            .rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, 'test');
      expect(result.error!.message, "mock");
      expect(result.lang, 'en-us');
      expect(result.value!.length, 3);
    });
  });
  group("test BaseLockEntryElementParser", () {
    late LockScopeElementParser lockScopeParser;
    late WriteLockElementParser lockTypeParser;
    late BaseLockEntryElementParser parser;

    setUp(() {
      lockScopeParser = MockLockScopeElementParser();
      lockTypeParser = MockWriteLockElementParser();
      parser = BaseLockEntryElementParser(
          lockScopeParser: lockScopeParser, lockTypeParser: lockTypeParser);
    });

    test('convert', () {
      final input = XmlDocument.parse("""
<D:lockentry xmlns:D=DAV:>
  <D:lockscope/>
  <D:locktype/>
</D:lockentry>
"""
          .trim());
      when((lockScopeParser as MockLockScopeElementParser).convert(any))
          .thenReturn(LockScope.exclusive);
      when((lockTypeParser as MockWriteLockElementParser).convert(any))
          .thenReturn(true);
      final result = parser.convert(input.rootElement)!;
      expect(result.lockScope, LockScope.exclusive);
      expect(result.isWriteLock, isTrue);
    });
    test('convert with no child elements', () {
      final inputs = [
        XmlDocument.parse("""
<D:lockentry xmlns:D=DAV:>
</D:lockentry>
"""
            .trim()),
        XmlDocument.parse("""
<D:lockentry xmlns:D=DAV:>
  <D:locktype/>
</D:lockentry>
"""
            .trim()),
        XmlDocument.parse("""
<D:lockentry xmlns:D=DAV:>
  <D:lockscope/>
</D:lockentry>
"""
            .trim())
      ];
      for (var input in inputs) {
        expect(parser.convert(input.rootElement), isNull);
      }
    });
    test('convert lockscope got null', () {
      final input = XmlDocument.parse("""
<D:lockentry xmlns:D=DAV:>
  <D:lockscope/>
  <D:locktype/>
</D:lockentry>
"""
          .trim());
      when((lockScopeParser as MockLockScopeElementParser).convert(any))
          .thenReturn(null);
      when((lockTypeParser as MockWriteLockElementParser).convert(any))
          .thenReturn(true);
      expect(() => parser.convert(input.rootElement),
          throwsA(TypeMatcher<WebDavParserDataError>()));
    });
    test('convert locktype got null', () {
      final input = XmlDocument.parse("""
<D:lockentry xmlns:D=DAV:>
  <D:lockscope/>
  <D:locktype/>
</D:lockentry>
"""
          .trim());
      when((lockScopeParser as MockLockScopeElementParser).convert(any))
          .thenReturn(LockScope.exclusive);
      when((lockTypeParser as MockWriteLockElementParser).convert(any))
          .thenReturn(null);
      final result = parser.convert(input.rootElement)!;
      expect(result.lockScope, LockScope.exclusive);
      expect(result.isWriteLock, isFalse);
    });
  });
  group("test ActiveLockElementParser", () {
    test("convert", () {
      final entryParser = MockActiveLockElementParser();
      final parser = LockDiscoveryPropParser(pieceParser: entryParser);
      final result = parser.convert((
        desc: null,
        error: null,
        node: XmlDocument.parse("<prop1></prop1>").rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, isNull);
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.lang, isNull);
      expect(result.value, isEmpty);
    });
    test("convert with null lockEntry", () {
      final entryParser = MockActiveLockElementParser();
      when(entryParser.convert(any)).thenReturn(null);
      final parser = LockDiscoveryPropParser(pieceParser: entryParser);
      final result = parser.convert((
        desc: null,
        error: null,
        node: XmlDocument.parse("""
<D:prop1 xmlns:D=DAV:>
  <D:activelock/>
  <D:activelock/>
  <D:activelock/>
</D:prop1>
"""
                .trim())
            .rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, isNull);
      expect(result.error, isNull);
      expect(result.lang, isNull);
      expect(result.value, isEmpty);
    });
    test("convert, full case", () {
      final entryParser = MockActiveLockElementParser();
      when(entryParser.convert(any)).thenReturn(MockActiveLock());
      final parser = LockDiscoveryPropParser(pieceParser: entryParser);
      final result = parser.convert((
        desc: 'test',
        error: WebDavStdResError("mock"),
        node: XmlDocument.parse("""
<D:prop1 xml:lang=en-us xmlns:D=DAV:>
  <D:activelock/>
  <D:activelock/>
  <D:activelock/>
</D:prop1>
"""
                .trim())
            .rootElement,
        status: HttpStatus.accepted,
      ));
      expect(result.name, "prop1");
      expect(result.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(result.status, HttpStatus.accepted);
      expect(result.desc, 'test');
      expect(result.error!.message, "mock");
      expect(result.lang, 'en-us');
      expect(result.value!.length, 3);
    });
  });
  group("test BaseActiveLockElementParser", () {
    late MockLockScopeElementParser lockScopeParser;
    late MockWriteLockElementParser lockTypeParser;
    late MockConverter<XmlElement, Depth?> depthParser;
    late MockConverter<XmlElement, String?> ownerParser;
    late MockConverter<XmlElement, double?> timeoutParser;
    late MockNestedHrefElementParser lockTokenParser;
    late MockNestedHrefElementParser lockRootParser;
    late BaseActiveLockElementParser<String> parser;

    setUp(() {
      lockScopeParser = MockLockScopeElementParser();
      lockTypeParser = MockWriteLockElementParser();
      depthParser = MockConverter<XmlElement, Depth?>();
      ownerParser = MockConverter<XmlElement, String?>();
      timeoutParser = MockConverter<XmlElement, double?>();
      lockTokenParser = MockNestedHrefElementParser();
      lockRootParser = MockNestedHrefElementParser();
      parser = BaseActiveLockElementParser(
          lockScopeParser: lockScopeParser,
          lockTypeParser: lockTypeParser,
          depthParser: depthParser,
          ownerParser: ownerParser,
          timeoutParser: timeoutParser,
          lockTokenParser: lockTokenParser,
          lockRootParser: lockRootParser);
    });

    test("convert", () {
      final input = XmlDocument.parse("""
<D:activelock xmlns:D=DAV:>
  <D:locktype/>
  <D:lockscope/>
  <D:depth/>
  <D:owner/>
  <D:timeout/>
  <D:locktoken/>
  <D:lockroot/>
</D:activelock>
"""
          .trim());
      when(lockScopeParser.convert(any)).thenReturn(LockScope.exclusive);
      when(lockTypeParser.convert(any)).thenReturn(true);
      when(depthParser.convert(any)).thenReturn(Depth.all);
      when(ownerParser.convert(any)).thenReturn("mock owner");
      when(timeoutParser.convert(any)).thenReturn(1234.56);
      when(lockTokenParser.convert(any)).thenReturn(Uri.parse("/lock/token"));
      when(lockRootParser.convert(any)).thenReturn(Uri.parse("/lock/root"));
      final result = parser.convert(input.rootElement)!;
      expect(result.lockScope, LockScope.exclusive);
      expect(result.isWriteLock, isTrue);
      expect(result.depth, Depth.all);
      expect(result.owner, "mock owner");
      expect(result.timeout, 1234.56);
      expect(result.lockToken, equals(Uri.parse("/lock/token")));
      expect(result.lockRoot, equals(Uri.parse("/lock/root")));
    });
    test("convert without lockscope/locktype/depth element", () {
      final inputs = [
        XmlDocument.parse("""
<D:activelock xmlns:D=DAV:>
  <D:locktype/>
  <D:depth/>
  <D:owner/>
  <D:timeout/>
  <D:locktoken/>
  <D:lockroot/>
</D:activelock>
"""),
        XmlDocument.parse("""
<D:activelock xmlns:D=DAV:>
  <D:lockscope/>
  <D:depth/>
  <D:owner/>
  <D:timeout/>
  <D:locktoken/>
  <D:lockroot/>
</D:activelock>
"""),
        XmlDocument.parse("""
<D:activelock xmlns:D=DAV:>
  <D:locktype/>
  <D:lockscope/>
  <D:owner/>
  <D:timeout/>
  <D:locktoken/>
  <D:lockroot/>
</D:activelock>
""")
      ];
      for (var input in inputs) {
        expect(parser.convert(input.rootElement), isNull);
      }
    });
    test("convert: lockscope parser failed", () {
      final input = XmlDocument.parse("""
<D:activelock xmlns:D=DAV:>
  <D:locktype/>
  <D:lockscope/>
  <D:depth/>
  <D:owner/>
  <D:timeout/>
  <D:locktoken/>
  <D:lockroot/>
</D:activelock>
"""
          .trim());
      when(lockScopeParser.convert(any)).thenReturn(null);
      expect(() => parser.convert(input.rootElement),
          throwsA(TypeMatcher<WebDavParserDataError>()));
    });
    test("convert: depth parser failed", () {
      final input = XmlDocument.parse("""
<D:activelock xmlns:D=DAV:>
  <D:locktype/>
  <D:lockscope/>
  <D:depth/>
  <D:owner/>
  <D:timeout/>
  <D:locktoken/>
  <D:lockroot/>
</D:activelock>
"""
          .trim());
      when(lockScopeParser.convert(any)).thenReturn(LockScope.exclusive);
      when(depthParser.convert(any)).thenReturn(null);
      expect(() => parser.convert(input.rootElement),
          throwsA(TypeMatcher<WebDavParserDataError>()));
    });
    test("convert with empty elements", () {
      final input = XmlDocument.parse("""
<D:activelock xmlns:D=DAV:>
  <D:locktype/>
  <D:lockscope/>
  <D:depth/>
  <D:owner/>
  <D:timeout/>
  <D:locktoken/>
  <D:lockroot/>
</D:activelock>
"""
          .trim());
      when(lockScopeParser.convert(any)).thenReturn(LockScope.exclusive);
      when(lockTypeParser.convert(any)).thenReturn(null);
      when(depthParser.convert(any)).thenReturn(Depth.all);
      when(ownerParser.convert(any)).thenReturn(null);
      when(timeoutParser.convert(any)).thenReturn(null);
      when(lockTokenParser.convert(any)).thenReturn(null);
      when(lockRootParser.convert(any)).thenReturn(null);
      final result = parser.convert(input.rootElement)!;
      expect(result.lockScope, LockScope.exclusive);
      expect(result.isWriteLock, isFalse);
      expect(result.depth, Depth.all);
      expect(result.owner, isNull);
      expect(result.timeout, isNull);
      expect(result.lockToken, isNull);
      expect(result.lockRoot, isNull);
    });
    test("convert with no optional parsers", () {
      final input = XmlDocument.parse("""
<D:activelock xmlns:D=DAV:>
  <D:locktype/>
  <D:lockscope/>
  <D:depth/>
  <D:owner/>
  <D:timeout/>
  <D:locktoken/>
  <D:lockroot/>
</D:activelock>
"""
          .trim());
      when(lockScopeParser.convert(any)).thenReturn(LockScope.exclusive);
      when(lockTypeParser.convert(any)).thenReturn(true);
      when(depthParser.convert(any)).thenReturn(Depth.all);
      when(lockRootParser.convert(any)).thenReturn(Uri.parse("/lock/root"));
      parser = BaseActiveLockElementParser(
          lockScopeParser: lockScopeParser,
          lockTypeParser: lockTypeParser,
          depthParser: depthParser,
          ownerParser: null,
          timeoutParser: null,
          lockTokenParser: null,
          lockRootParser: lockRootParser);
      final result = parser.convert(input.rootElement)!;
      expect(result.lockScope, LockScope.exclusive);
      expect(result.isWriteLock, isTrue);
      expect(result.depth, Depth.all);
      expect(result.owner, isNull);
      expect(result.timeout, isNull);
      expect(result.lockToken, isNull);
      expect(result.lockRoot, equals(Uri.parse("/lock/root")));
    });
  });
}
