// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/if.dart';
import 'package:simple_webdav_client/src/_std/namespace_mgr.dart';
import 'package:simple_webdav_client/src/_std/proppatch.dart';
import 'package:simple_webdav_client/src/utils.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  HttpClientRequest,
  HttpHeaders,
  ToXmlCapable,
])
import 'proppatch_test.mocks.dart';

void main() {
  group("test ProppatchRequestProp", () {
    test("constructor", () {
      final prop =
          ProppatchRequestProp(name: "prop", op: ProppatchRequestOp.set);
      expect(prop.name, "prop");
      expect(prop.namespace, isNull);
      expect(prop.value, isNull);
      expect(prop.op, ProppatchRequestOp.set);
      expect(prop.lang, isNull);
    });
    test("constructor with param", () {
      final prop = ProppatchRequestProp(
          name: "prop",
          op: ProppatchRequestOp.remove,
          namespace: "DAV:",
          value: MockToXmlCapable(),
          lang: "en-us");
      expect(prop.name, "prop");
      expect(prop.namespace, "DAV:");
      expect(prop.value, TypeMatcher<ToXmlCapable>());
      expect(prop.op, ProppatchRequestOp.remove);
      expect(prop.lang, 'en-us');
    });
    test("constructor.set", () {
      final prop = ProppatchRequestProp.set(
          name: "prop", value: MockToXmlCapable(), lang: "en-us");
      expect(prop.name, "prop");
      expect(prop.namespace, "DAV:");
      expect(prop.value, TypeMatcher<ToXmlCapable>());
      expect(prop.op, ProppatchRequestOp.set);
      expect(prop.lang, 'en-us');
    });
    test("constructor.remove", () {
      final prop = ProppatchRequestProp.remove(name: "prop", lang: "en-us");
      expect(prop.name, "prop");
      expect(prop.namespace, "DAV:");
      expect(prop.value, isNull);
      expect(prop.op, ProppatchRequestOp.remove);
      expect(prop.lang, 'en-us');
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final value = MockToXmlCapable();
      when(value.toXml(context, nsmgr)).thenReturn(null);
      final prop = ProppatchRequestProp(
          name: "prop", op: ProppatchRequestOp.set, value: value);
      prop.toXml(context, nsmgr);
      expect(context.buildDocument().toString(), '<prop/>');
      verify(value.toXml(context, nsmgr)).called(1);
    });
    test("toXml with full params", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final value = MockToXmlCapable();
      when(value.toXml(context, nsmgr)).thenReturn(null);
      final prop = ProppatchRequestProp(
          name: "prop",
          op: ProppatchRequestOp.remove,
          namespace: "DAV:",
          value: value,
          lang: "en-us");
      prop.toXml(context, nsmgr);
      expect(context.buildDocument().toString(),
          '<a1:prop xmlns:a1="DAV:" xml:lang="en-us"/>');
      verify(value.toXml(context, nsmgr)).called(1);
    });
    test("toXml with full params and namespace = ''", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final value = MockToXmlCapable();
      when(value.toXml(context, nsmgr)).thenReturn(null);
      final prop = ProppatchRequestProp(
          name: "prop",
          op: ProppatchRequestOp.remove,
          namespace: "",
          value: value,
          lang: "en-us");
      prop.toXml(context, nsmgr);
      expect(context.buildDocument().toString(),
          '<prop xmlns="" xml:lang="en-us"/>');
      verify(value.toXml(context, nsmgr)).called(1);
    });
  });
  group("test ProppatchRequestPropBaseValue", () {
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final value = ProppatchRequestPropBaseValue(123);
      value.toXml(context, nsmgr);
      expect(context.buildDocument().toString(), '123');
    });
  });
  group("test ProppatchRequestPropHttpDateValue", () {
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final value = ProppatchRequestPropHttpDateValue(
          DateTime.parse("2024-09-04 17:06:31"));
      value.toXml(context, nsmgr);
      expect(
          context.buildDocument().toString(), 'Wed, 04 Sep 2024 09:06:31 GMT');
    });
  });
  group("test ProppatchRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("groupPropsByOp", () {
      final p1 = ProppatchRequestProp.set(name: "prop1");
      final p2 = ProppatchRequestProp.remove(name: "prop2");
      final p3 = ProppatchRequestProp.set(name: "prop3");
      final p4 = ProppatchRequestProp.set(name: "prop4");
      final p5 = ProppatchRequestProp.remove(name: "prop5");
      final p6 = ProppatchRequestProp.remove(name: "prop6");
      final p7 = ProppatchRequestProp.set(name: "prop7");
      final result =
          ProppatchRequestParam.groupPropsByOp([p1, p2, p3, p4, p5, p6, p7])
              .toList();
      final expected = [
        (op: ProppatchRequestOp.set, props: [p1]),
        (op: ProppatchRequestOp.remove, props: [p2]),
        (op: ProppatchRequestOp.set, props: [p3, p4]),
        (op: ProppatchRequestOp.remove, props: [p5, p6]),
        (op: ProppatchRequestOp.set, props: [p7]),
      ];
      expect(result.length, expected.length);
      for (var i = 0; i < result.length; i++) {
        expect(result[i].op, expected[i].op);
        expect(result[i].props, orderedEquals(expected[i].props));
      }
    });
    test("constructor", () {
      final param = ProppatchRequestParam(ops: <ProppatchRequestProp>[]);
      expect(param.condition, isNull);
      expect(param.operations, isEmpty);
    });
    test("constructor with params", () {
      final param = ProppatchRequestParam(ops: <ProppatchRequestProp>[
        ProppatchRequestProp.set(name: "prop1"),
        ProppatchRequestProp.remove(name: "prop2"),
      ], condition: IfOr.tagged([]));
      expect(param.condition, TypeMatcher<IfOr>());
      expect(param.operations.length, 2);
    });
    test("beforeAddRequestBody", () {
      ProppatchRequestParam(ops: <ProppatchRequestProp>[])
          .beforeAddRequestBody(request);
      verifyNever(headers.add("If", any));
    });
    test("beforeAddRequestBody with conditions", () {
      final ifOr = IfOr.tagged([]);
      ProppatchRequestParam(ops: <ProppatchRequestProp>[], condition: ifOr)
          .beforeAddRequestBody(request);
      verify(headers.add("If", ifOr.toString())).called(1);
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      ProppatchRequestParam(ops: <ProppatchRequestProp>[])
          .toXml(context, nsmgr);
      expect(context.buildDocument().toString(),
          '<a1:propertyupdate xmlns:a1="DAV:"/>');
    });
    test("toXml with props", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final p1 = ProppatchRequestProp.set(
          name: "prop1", value: ProppatchRequestPropBaseValue(123));
      final p2 = ProppatchRequestProp.remove(name: "prop2");
      final p3 = ProppatchRequestProp.set(
          name: "prop3", value: ProppatchRequestPropBaseValue(234));
      final p4 = ProppatchRequestProp.set(
          name: "prop4", value: ProppatchRequestPropBaseValue(345));
      final p5 = ProppatchRequestProp.remove(name: "prop5");
      final p6 =
          ProppatchRequestProp.remove(name: "prop6", namespace: "CUSTOM:");
      final p7 = ProppatchRequestProp.set(
          name: "prop7", value: ProppatchRequestPropBaseValue(456));
      ProppatchRequestParam(ops: [p1, p2, p3, p4, p5, p6, p7])
          .toXml(context, nsmgr);
      expect(
          context.buildDocument().toXmlString(pretty: true),
          '''
<a1:propertyupdate xmlns:a1="DAV:" xmlns:a2="CUSTOM:">
  <a1:set>
    <a1:prop>
      <a1:prop1>123</a1:prop1>
    </a1:prop>
  </a1:set>
  <a1:remove>
    <a1:prop>
      <a1:prop2/>
    </a1:prop>
  </a1:remove>
  <a1:set>
    <a1:prop>
      <a1:prop3>234</a1:prop3>
      <a1:prop4>345</a1:prop4>
    </a1:prop>
  </a1:set>
  <a1:remove>
    <a1:prop>
      <a1:prop5/>
      <a2:prop6/>
    </a1:prop>
  </a1:remove>
  <a1:set>
    <a1:prop>
      <a1:prop7>456</a1:prop7>
    </a1:prop>
  </a1:set>
</a1:propertyupdate>
'''
              .trim());
    });
    test("toRequestBody", () {
      final p1 = ProppatchRequestProp.set(
          name: "prop1", value: ProppatchRequestPropBaseValue(123));
      final p2 = ProppatchRequestProp.remove(name: "prop2");
      final p3 = ProppatchRequestProp.set(
          name: "prop3", value: ProppatchRequestPropBaseValue(234));
      final p4 = ProppatchRequestProp.set(
          name: "prop4", value: ProppatchRequestPropBaseValue(345));
      final p5 = ProppatchRequestProp.remove(name: "prop5");
      final p6 =
          ProppatchRequestProp.remove(name: "prop6", namespace: "CUSTOM:");
      final p7 = ProppatchRequestProp.set(
          name: "prop7", value: ProppatchRequestPropBaseValue(456));
      final result = ProppatchRequestParam(ops: [p1, p2, p3, p4, p5, p6, p7])
          .toRequestBody();
      expect(
          result,
          '<?xml version="1.0" encoding="utf-8"?>'
          '<a1:propertyupdate xmlns:a1="DAV:" xmlns:a2="CUSTOM:">'
          '<a1:set><a1:prop><a1:prop1>123</a1:prop1></a1:prop></a1:set>'
          '<a1:remove><a1:prop><a1:prop2/></a1:prop></a1:remove>'
          '<a1:set><a1:prop><a1:prop3>234</a1:prop3>'
          '<a1:prop4>345</a1:prop4></a1:prop></a1:set>'
          '<a1:remove><a1:prop><a1:prop5/><a2:prop6/></a1:prop></a1:remove>'
          '<a1:set><a1:prop><a1:prop7>456</a1:prop7></a1:prop></a1:set>'
          '</a1:propertyupdate>');
    });
  });
}
