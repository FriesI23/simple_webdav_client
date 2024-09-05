// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/depth.dart';
import 'package:simple_webdav_client/src/_std/if.dart';
import 'package:simple_webdav_client/src/_std/lock.dart';
import 'package:simple_webdav_client/src/_std/namespace_mgr.dart';
import 'package:simple_webdav_client/src/_std/prop.dart';
import 'package:simple_webdav_client/src/utils.dart';
import 'package:simple_webdav_client/src/_std/timeout.dart' as davto;
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  HttpClientRequest,
  HttpHeaders,
  ToXmlCapable,
])
import 'lock_test.mocks.dart';

void main() {
  group("test LockInfo", () {
    test("constructor", () {
      final info = LockInfo(lockScope: LockScope.exclusive);
      expect(info.lockScope, LockScope.exclusive);
      expect(info.owner, isNull);
    });
    test("constructor with params", () {
      final info =
          LockInfo(lockScope: LockScope.shared, owner: MockToXmlCapable());
      expect(info.lockScope, LockScope.shared);
      expect(info.owner, TypeMatcher<ToXmlCapable>());
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final info = LockInfo(lockScope: LockScope.exclusive);
      info.toXml(context, nsmgr);
      expect(
          context.buildDocument().toXmlString(pretty: true),
          """
<a1:lockinfo xmlns:a1="DAV:">
  <a1:lockscope>
    <a1:exclusive/>
  </a1:lockscope>
  <a1:locktype>
    <a1:write/>
  </a1:locktype>
</a1:lockinfo>

  """
              .trim());
    });
    test("toXml with params", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      final owner = MockToXmlCapable();
      when(owner.toXml(context, nsmgr)).thenAnswer((_) {
        context.text("mock-test");
      });
      final info = LockInfo(lockScope: LockScope.shared, owner: owner);
      info.toXml(context, nsmgr);
      expect(
          context.buildDocument().toXmlString(pretty: true),
          """
<a1:lockinfo xmlns:a1="DAV:">
  <a1:lockscope>
    <a1:shared/>
  </a1:lockscope>
  <a1:locktype>
    <a1:write/>
  </a1:locktype>
  <a1:owner>mock-test</a1:owner>
</a1:lockinfo>
  """
              .trim());
    });
  });
  group("test LockRequestParam", () {
    late MockHttpClientRequest request;
    late MockHttpHeaders headers;

    setUp(() {
      request = MockHttpClientRequest();
      headers = MockHttpHeaders();
      when(request.headers).thenReturn(headers);
      when(headers.add(any, any)).thenReturn(null);
    });

    test("constructor", () {
      final param =
          LockRequestParam(lockInfo: LockInfo(lockScope: LockScope.exclusive));
      expect(param.lockInfo!.lockScope, LockScope.exclusive);
      expect(param.condition, isNull);
      expect(param.depth, isNull);
      expect(param.timeout, isNull);
    });
    test("constructor with param", () {
      final param = LockRequestParam(
        lockInfo: LockInfo(lockScope: LockScope.exclusive),
        timeout: davto.DavTimeout([double.infinity, 123]),
        recursive: true,
        condition: IfOr.tagged([]),
      );
      expect(param.lockInfo!.lockScope, LockScope.exclusive);
      expect(param.condition, TypeMatcher<IfOr>());
      expect(param.depth, Depth.all);
      expect(param.timeout, equals([double.infinity, 123]));
    });
    test("constructor.renew", () {
      final param = LockRequestParam.renew(
        timeout: davto.DavTimeout([double.infinity, 123]),
        recursive: true,
        condition: IfOr.tagged([]),
      );
      expect(param.lockInfo, isNull);
      expect(param.condition, TypeMatcher<IfOr>());
      expect(param.depth, Depth.all);
      expect(param.timeout, equals([double.infinity, 123]));
    });
    test("beforeAddRequestBody", () {
      LockRequestParam(lockInfo: LockInfo(lockScope: LockScope.exclusive))
          .beforeAddRequestBody(request);
      verifyNever(headers.add('Depth', any));
      verifyNever(headers.add('Timeout', any));
      verifyNever(headers.add('If', any));
    });
    test("beforeAddRequestBody with params", () {
      final ifOr = IfOr.tagged([]);
      LockRequestParam(
        lockInfo: LockInfo(lockScope: LockScope.exclusive),
        timeout: davto.DavTimeout([double.infinity, 123]),
        recursive: true,
        condition: ifOr,
      ).beforeAddRequestBody(request);
      verify(headers.add('Depth', Depth.all.name)).called(1);
      verify(headers.add('Timeout', "Infinite, Second-123")).called(1);
      verify(headers.add('If', ifOr.toString())).called(1);
    });
    test("toXml", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      LockRequestParam(lockInfo: LockInfo(lockScope: LockScope.exclusive))
          .toXml(context, nsmgr);
      expect(
          context.buildDocument().toXmlString(pretty: true),
          '''
<a1:lockinfo xmlns:a1="DAV:">
  <a1:lockscope>
    <a1:exclusive/>
  </a1:lockscope>
  <a1:locktype>
    <a1:write/>
  </a1:locktype>
</a1:lockinfo>
'''
              .trim());
    });
    test("toXml renew", () {
      final context = XmlBuilder();
      final nsmgr = StdNamespaceManger();
      LockRequestParam.renew(
        timeout: davto.DavTimeout([double.infinity, 123]),
        recursive: true,
        condition: IfOr.tagged([]),
      ).toXml(context, nsmgr);
      expect(context.buildDocument().toXmlString(pretty: true), '');
    });
    test("toRequestBody", () {
      final result =
          LockRequestParam(lockInfo: LockInfo(lockScope: LockScope.exclusive))
              .toRequestBody();
      expect(
          result,
          '<?xml version="1.0" encoding="utf-8"?>'
          '<a1:lockinfo xmlns:a1="DAV:">'
          '<a1:lockscope><a1:exclusive/></a1:lockscope>'
          '<a1:locktype><a1:write/></a1:locktype></a1:lockinfo>');
    });
    test("toRequestBody renew", () {
      final result =
          LockRequestParam.renew(condition: IfOr.tagged([])).toRequestBody();
      expect(result, isNull);
    });
  });
}
