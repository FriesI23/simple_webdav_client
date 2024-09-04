// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/depth.dart';
import 'package:simple_webdav_client/src/_std/namespace_mgr.dart';
import 'package:simple_webdav_client/src/_std/propfind.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  PropfindRequestProp,
  HttpClientRequest,
  HttpHeaders,
])
import 'propfind_test.mocks.dart';

void main() {
  group("test PropfindRequestProp", () {
    test("constructor", () {
      final prop = PropfindRequestProp("prop", "xxx");
      expect(prop.name, "prop");
      expect(prop.namespace, "xxx");
      expect(prop.value, isNull);
    });
    test("constructor.dav", () {
      final prop = PropfindRequestProp.dav("prop");
      expect(prop.name, "prop");
      expect(prop.namespace, "DAV:");
      expect(prop.value, isNull);
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      PropfindRequestProp("prop").toXml(context, nsmgr);
      expect(context.buildDocument().toString(), "<prop/>");
      expect(nsmgr.namespaces, isEmpty);
    });
    test("toXml with namespace: ''", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      PropfindRequestProp("prop", "").toXml(context, nsmgr);
      expect(context.buildDocument().toString(), '<prop xmlns=""/>');
      expect(nsmgr.namespaces, isEmpty);
    });
    test("toXml with namespace: DAV:", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      PropfindRequestProp("prop", "DAV:").toXml(context, nsmgr);
      expect(context.buildDocument().toString(), '<a1:prop xmlns:a1="DAV:"/>');
      expect(nsmgr.namespaces, {"DAV:": "a1"});
    });
    test("toXml with namespace: DAV: and existed in nsmgr", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      nsmgr.generate("CUSTOM:");
      nsmgr.generate("DAV:");
      context.element('root', namespaces: nsmgr.namespaces, nest: () {
        PropfindRequestProp("prop", "DAV:").toXml(context, nsmgr);
      });
      expect(context.buildDocument().toString(),
          '<root xmlns:a1="CUSTOM:" xmlns:a2="DAV:"><a2:prop/></root>');
      expect(nsmgr.namespaces, {"DAV:": "a2", "CUSTOM:": "a1"});
    });
  });
  group("test PropfindPropRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("constructor", () {
      final param1 = PropfindPropRequestParam();
      expect(param1.props, isEmpty);
      expect(param1.depth, isNull);
    });
    test("constructor with params", () {
      final param1 = PropfindPropRequestParam(
          props: [MockPropfindRequestProp(), MockPropfindRequestProp()],
          depth: Depth.resource);
      expect(param1.props.length, 2);
      expect(param1.depth, Depth.resource);
    });
    test("beforeAddRequestBody", () {
      PropfindPropRequestParam().beforeAddRequestBody(request);
      verifyNever(headers.add("Depth", any));
      PropfindPropRequestParam(depth: Depth.all).beforeAddRequestBody(request);
      verify(headers.add("Depth", Depth.all.name)).called(1);
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      PropfindPropRequestParam().toXml(context, nsmgr);
      expect(context.buildDocument().toString(),
          '<a1:propfind xmlns:a1="DAV:"><a1:prop/></a1:propfind>');
    });
    test("toXml with props", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      PropfindPropRequestParam(props: [
        PropfindRequestProp("prop1"),
        PropfindRequestProp("prop2", ""),
        PropfindRequestProp("prop3", "CUSTOM:"),
        PropfindRequestProp.dav("prop4"),
      ]).toXml(context, nsmgr);
      expect(
          context.buildDocument().toXmlString(pretty: true),
          '''
<a1:propfind xmlns:a1="DAV:" xmlns:a2="CUSTOM:">
  <a1:prop>
    <prop1/>
    <prop2 xmlns=""/>
    <a2:prop3/>
    <a1:prop4/>
  </a1:prop>
</a1:propfind>
'''
              .trim());
    });
    test("toRequestBody", () {
      final body = PropfindPropRequestParam(props: [
        PropfindRequestProp("prop1"),
        PropfindRequestProp("prop2", ""),
        PropfindRequestProp("prop3", "CUSTOM:"),
        PropfindRequestProp.dav("prop4"),
      ]).toRequestBody();
      expect(
          body,
          '<?xml version="1.0" encoding="utf-8"?>'
          '<a1:propfind xmlns:a1="DAV:" xmlns:a2="CUSTOM:">'
          '<a1:prop><prop1/><prop2 xmlns=""/><a2:prop3/><a1:prop4/>'
          '</a1:prop></a1:propfind>');
    });
  });
  group("test PropfindAllRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("constructor", () {
      final param1 = PropfindAllRequestParam();
      expect(param1.includes, isEmpty);
      expect(param1.depth, isNull);
    });
    test("constructor with params", () {
      final param1 = PropfindAllRequestParam(
          include: [MockPropfindRequestProp(), MockPropfindRequestProp()],
          depth: Depth.resource);
      expect(param1.includes.length, 2);
      expect(param1.depth, Depth.resource);
    });
    test("beforeAddRequestBody", () {
      PropfindAllRequestParam().beforeAddRequestBody(request);
      verifyNever(headers.add("Depth", any));
      PropfindPropRequestParam(depth: Depth.all).beforeAddRequestBody(request);
      verify(headers.add("Depth", Depth.all.name)).called(1);
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      PropfindAllRequestParam().toXml(context, nsmgr);
      expect(context.buildDocument().toString(),
          '<a1:propfind xmlns:a1="DAV:"><a1:allprop/></a1:propfind>');
    });
    test("toXml with props", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      PropfindAllRequestParam(include: [
        PropfindRequestProp("prop1"),
        PropfindRequestProp("prop2", ""),
        PropfindRequestProp("prop3", "CUSTOM:"),
        PropfindRequestProp.dav("prop4"),
      ]).toXml(context, nsmgr);
      expect(
          context.buildDocument().toXmlString(pretty: true),
          '''
<a1:propfind xmlns:a1="DAV:" xmlns:a2="CUSTOM:">
  <a1:allprop/>
  <a1:include>
    <prop1/>
    <prop2 xmlns=""/>
    <a2:prop3/>
    <a1:prop4/>
  </a1:include>
</a1:propfind>
'''
              .trim());
    });
    test("toRequestBody", () {
      final body = PropfindAllRequestParam(include: [
        PropfindRequestProp("prop1"),
        PropfindRequestProp("prop2", ""),
        PropfindRequestProp("prop3", "CUSTOM:"),
        PropfindRequestProp.dav("prop4"),
      ]).toRequestBody();
      expect(
          body,
          '<?xml version="1.0" encoding="utf-8"?>'
          '<a1:propfind xmlns:a1="DAV:" xmlns:a2="CUSTOM:"><a1:allprop/>'
          '<a1:include><prop1/><prop2 xmlns=""/><a2:prop3/><a1:prop4/>'
          '</a1:include></a1:propfind>');
    });
  });
  group("test PropfindNameRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("constructor", () {
      final param = PropfindNameRequestParam();
      expect(param.depth, isNull);
      final param2 = PropfindNameRequestParam(depth: Depth.all);
      expect(param2.depth, Depth.all);
    });
    test("beforeAddRequestBody", () {
      PropfindNameRequestParam().beforeAddRequestBody(request);
      verifyNever(headers.add("Depth", any));
      PropfindNameRequestParam(depth: Depth.all).beforeAddRequestBody(request);
      verify(headers.add("Depth", Depth.all.name)).called(1);
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      PropfindNameRequestParam().toXml(context, nsmgr);
      expect(context.buildDocument().toString(),
          '<a1:propfind xmlns:a1="DAV:"><a1:propname/></a1:propfind>');
    });
    test("toRequestBody", () {
      final body = PropfindNameRequestParam().toRequestBody();
      expect(
          body,
          '<?xml version="1.0" encoding="utf-8"?>'
          '<a1:propfind xmlns:a1="DAV:"><a1:propname/></a1:propfind>');
    });
  });
}
