// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';

import 'package:mockito/annotations.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/parser_mgr.dart';
import 'package:simple_webdav_client/src/_std/resource.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  XmlElement,
  Converter,
  PropElementParser,
  ErrorElementParser,
  PropstatElementParser,
  ResponseElementParser,
  MultiStatusElementParser,
  HrefElementParser,
  HttpStatusElementParser,
])
import 'parser_mgr_test.mocks.dart';

void main() {
  group("test WebDavResposneDataParserManger", () {
    test("constructor", () {
      const mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, TypeMatcher<Map>());
      expect(mgr, isEmpty);
    });
    test("constructor with params", () {
      final mgr = WebDavResposneDataParserManger(
          parsers: {(name: 'xxx', ns: null): MockConverter()});
      expect(mgr, TypeMatcher<Map>());
      expect(mgr, isNotEmpty);
      expect(mgr.length, 1);
    });
    test("operator[]", () {
      final mgr = WebDavResposneDataParserManger(
          parsers: {(name: 'xxx', ns: null): MockConverter()});
      expect(mgr[(name: 'xxx', ns: null)], TypeMatcher<Converter>());
      expect(mgr[(name: 'xxx', ns: 'DAV:')], isNull);
    });
    test("operator[]=", () {
      final mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, isEmpty);
      mgr[(name: 'xxx', ns: null)] = MockConverter();
      expect(mgr, isNotEmpty);
      expect(mgr[(name: 'xxx', ns: null)], TypeMatcher<Converter>());
    });
    test("clear", () {
      final mgr = WebDavResposneDataParserManger(
          parsers: {(name: 'xxx', ns: null): MockConverter()});
      expect(mgr, isNotEmpty);
      mgr.clear();
      expect(mgr, isEmpty);
    });
    test("keys", () {
      final mgr = WebDavResposneDataParserManger(
          parsers: {(name: 'xxx', ns: null): MockConverter()});
      expect(mgr.keys, [(name: 'xxx', ns: null)]);
    });
    test("remove", () {
      final mgr = WebDavResposneDataParserManger(
          parsers: {(name: 'xxx', ns: null): MockConverter()});
      expect(mgr, isNotEmpty);
      expect(mgr.remove((name: 'xxx', ns: null)), TypeMatcher<Converter>());
      expect(mgr, isEmpty);
      expect(mgr.remove((name: 'xxx', ns: null)), isNull);
    });
    test("fetchPropParser", () {
      final mgr = WebDavResposneDataParserManger(parsers: {
        (name: 'prop1', ns: null): MockConverter(),
        (name: 'prop2', ns: null):
            MockPropElementParser<WebDavStdResourceProp<String>>(),
        (name: 'prop3', ns: null):
            MockPropElementParser<WebDavStdResourceProp<int>>(),
      });
      // prop1
      expect(mgr[(name: 'prop1', ns: null)], TypeMatcher<MockConverter>());
      expect(mgr.fetchPropParser('prop1', null), isNull);
      // prop2
      expect(mgr[(name: 'prop2', ns: null)],
          TypeMatcher<MockPropElementParser<WebDavStdResourceProp<String>>>());
      expect(mgr.fetchPropParser('prop2', null),
          TypeMatcher<MockPropElementParser<WebDavStdResourceProp<String>>>());
      expect(mgr.fetchPropParser<WebDavStdResourceProp<String>>('prop2', null),
          TypeMatcher<MockPropElementParser<WebDavStdResourceProp<String>>>());
      expect(mgr.fetchPropParser<WebDavStdResourceProp<int>>('prop2', null),
          isNull);
      // prop3
      expect(mgr[(name: 'prop3', ns: null)],
          TypeMatcher<MockPropElementParser<WebDavStdResourceProp<int>>>());
      expect(mgr.fetchPropParser('prop3', null),
          TypeMatcher<MockPropElementParser<WebDavStdResourceProp<int>>>());
      expect(mgr.fetchPropParser<WebDavStdResourceProp<int>>('prop3', null),
          TypeMatcher<MockPropElementParser<WebDavStdResourceProp<int>>>());
      expect(mgr.fetchPropParser<WebDavStdResourceProp<double>>('prop3', null),
          isNull);
    });
    test('prop.error', () {
      final mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, isEmpty);
      expect(mgr.error, isNull);
      // set
      mgr.error = MockErrorElementParser();
      expect(mgr, isNotEmpty);
      expect(mgr.error, TypeMatcher<ErrorElementParser>());
      final newConvert = MockErrorElementParser();
      expect(mgr.error, isNot(newConvert));
      mgr.error = newConvert;
      expect(mgr.error, same(newConvert));
      // remove
      mgr.error = null;
      expect(mgr, isEmpty);
      expect(mgr.error, isNull);
    });
    test('prop.propstat', () {
      final mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, isEmpty);
      expect(mgr.propstat, isNull);
      // set
      mgr.propstat = MockPropstatElementParser();
      expect(mgr, isNotEmpty);
      expect(mgr.propstat, TypeMatcher<MockPropstatElementParser>());
      final newConvert = MockPropstatElementParser();
      expect(mgr.propstat, isNot(newConvert));
      mgr.propstat = newConvert;
      expect(mgr.propstat, same(newConvert));
      // remove
      mgr.propstat = null;
      expect(mgr, isEmpty);
      expect(mgr.propstat, isNull);
    });
    test('prop.response', () {
      final mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, isEmpty);
      expect(mgr.response, isNull);
      // set
      mgr.response = MockResponseElementParser();
      expect(mgr, isNotEmpty);
      expect(mgr.response, TypeMatcher<MockResponseElementParser>());
      final newConvert = MockResponseElementParser();
      expect(mgr.response, isNot(newConvert));
      mgr.response = newConvert;
      expect(mgr.response, same(newConvert));
      // remove
      mgr.response = null;
      expect(mgr, isEmpty);
      expect(mgr.response, isNull);
    });
    test('prop.multistatus', () {
      final mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, isEmpty);
      expect(mgr.response, isNull);
      // set
      mgr.multistatus = MockMultiStatusElementParser();
      expect(mgr, isNotEmpty);
      expect(mgr.multistatus, TypeMatcher<MockMultiStatusElementParser>());
      final newConvert = MockMultiStatusElementParser();
      expect(mgr.multistatus, isNot(newConvert));
      mgr.multistatus = newConvert;
      expect(mgr.multistatus, same(newConvert));
      // remove
      mgr.multistatus = null;
      expect(mgr, isEmpty);
      expect(mgr.multistatus, isNull);
    });
    test('prop.href', () {
      final mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, isEmpty);
      expect(mgr.href, isNull);
      // set
      mgr.href = MockHrefElementParser();
      expect(mgr, isNotEmpty);
      expect(mgr.href, TypeMatcher<MockHrefElementParser>());
      final newConvert = MockHrefElementParser();
      expect(mgr.href, isNot(newConvert));
      mgr.href = newConvert;
      expect(mgr.href, same(newConvert));
      // remove
      mgr.href = null;
      expect(mgr, isEmpty);
      expect(mgr.href, isNull);
    });
    test('prop.location', () {
      final mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, isEmpty);
      expect(mgr.location, isNull);
      // set
      mgr.location = MockHrefElementParser();
      expect(mgr, isNotEmpty);
      expect(mgr.location, TypeMatcher<MockHrefElementParser>());
      final newConvert = MockHrefElementParser();
      expect(mgr.location, isNot(newConvert));
      mgr.location = newConvert;
      expect(mgr.location, same(newConvert));
      // remove
      mgr.location = null;
      expect(mgr, isEmpty);
      expect(mgr.location, isNull);
    });
    test('prop.status', () {
      final mgr = WebDavResposneDataParserManger(parsers: {});
      expect(mgr, isEmpty);
      expect(mgr.status, isNull);
      // set
      mgr.status = MockHttpStatusElementParser();
      expect(mgr, isNotEmpty);
      expect(mgr.status, TypeMatcher<MockHttpStatusElementParser>());
      final newConvert = MockHttpStatusElementParser();
      expect(mgr.status, isNot(newConvert));
      mgr.status = newConvert;
      expect(mgr.status, same(newConvert));
      // remove
      mgr.status = null;
      expect(mgr, isEmpty);
      expect(mgr.status, isNull);
    });
  });
}
