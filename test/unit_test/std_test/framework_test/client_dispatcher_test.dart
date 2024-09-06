// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:simple_webdav_client/src/_std/client.dart';
import 'package:simple_webdav_client/src/_std/client_dispatcher.dart';
import 'package:simple_webdav_client/src/_std/copy.dart';
import 'package:simple_webdav_client/src/_std/delete.dart';
import 'package:simple_webdav_client/src/_std/depth.dart';
import 'package:simple_webdav_client/src/_std/get.dart';
import 'package:simple_webdav_client/src/_std/if.dart';
import 'package:simple_webdav_client/src/_std/lock.dart';
import 'package:simple_webdav_client/src/_std/mkcol.dart';
import 'package:simple_webdav_client/src/_std/move.dart';
import 'package:simple_webdav_client/src/_std/propfind.dart';
import 'package:simple_webdav_client/src/_std/proppatch.dart';
import 'package:simple_webdav_client/src/_std/put.dart';
import 'package:simple_webdav_client/src/_std/timeout.dart';
import 'package:simple_webdav_client/src/_std/unlock.dart';
import 'package:simple_webdav_client/src/method.dart';
import 'package:test/test.dart';

@GenerateMocks([
  PropfindRequestProp,
  ProppatchRequestProp,
  LockInfo,
  HttpClient,
])
import 'client_dispatcher_test.mocks.dart';

class MockHttpOverrides extends HttpOverrides {
  static late MockHttpClient client;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    client = MockHttpClient();
    return client;
  }
}

void main() {
  group("test StdRequestDispatcherImpl", () {
    final source = Uri.parse("http://example.com");
    late StdRequestDispatcherImpl dispatcher;
    late WebDavStdClient client;

    setUp(() {
      client = WebDavStdClient();
      dispatcher = StdRequestDispatcherImpl(client, source);
    });

    test("constructor", () {
      expect(dispatcher.client, same(client));
      expect(dispatcher.source, same(source));
    });

    test("findProps", () async {
      final props = [MockPropfindRequestProp(), MockPropfindRequestProp()];
      final request =
          await dispatcher.findProps(props: props, depth: Depth.all);
      expect(request.method, WebDavMethod.propfind);
      expect(request.param, TypeMatcher<PropfindPropRequestParam>());
      expect(request.param!.props, equals(props));
      expect(request.param!.depth, Depth.all);
    });

    test("findAllProps", () async {
      final includes = [MockPropfindRequestProp(), MockPropfindRequestProp()];
      final request =
          await dispatcher.findAllProps(includes: includes, depth: Depth.all);
      expect(request.method, WebDavMethod.propfind);
      expect(request.param, TypeMatcher<PropfindAllRequestParam>());
      expect(request.param!.includes, equals(includes));
      expect(request.param!.depth, Depth.all);
    });

    test("findPropNames", () async {
      final request = await dispatcher.findPropNames(depth: Depth.members);
      expect(request.method, WebDavMethod.propfind);
      expect(request.param, TypeMatcher<PropfindNameRequestParam>());
      expect(request.param!.depth, Depth.members);
    });

    test("updateProps", () async {
      final operations = [
        MockProppatchRequestProp(),
        MockProppatchRequestProp()
      ];
      final condition = IfOr.notag([]);
      final request = await dispatcher.updateProps(
          operations: operations, condition: condition);
      expect(request.method, WebDavMethod.proppatch);
      expect(request.param, TypeMatcher<ProppatchRequestParam>());
      expect(request.param!.operations, same(operations));
      expect(request.param!.condition, same(condition));
    });

    test("get", () async {
      final request = await dispatcher.get();
      expect(request.method, WebDavMethod.get);
      expect(request.param, TypeMatcher<GetRequestParam>());
      expect(request.param!.data, isNull);
    });

    test("create", () async {
      final data = "some data";
      final condition = IfOr.notag([]);
      final request = await dispatcher.create(data: data, condition: condition);
      expect(request.method, WebDavMethod.put);
      expect(request.param, TypeMatcher<PutRequestParam>());
      expect(request.param!.data, same(data));
      expect(request.param!.condition, same(condition));
    });

    test("createDir", () async {
      final condition = IfOr.notag([]);
      final request = await dispatcher.createDir(condition: condition);
      expect(request.method, WebDavMethod.mkcol);
      expect(request.param, TypeMatcher<MkcolRequestParam>());
      expect(request.param!.condition, same(condition));
    });

    test("delete", () async {
      final condition = IfOr.notag([]);
      final request = await dispatcher.delete(condition: condition);
      expect(request.method, WebDavMethod.delete);
      expect(request.param, TypeMatcher<DeleteRequestParam>());
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, Depth.resource);
    });

    test("deleteDir", () async {
      final condition = IfOr.notag([]);
      final request = await dispatcher.deleteDir(condition: condition);
      expect(request.method, WebDavMethod.delete);
      expect(request.param, TypeMatcher<DeleteRequestParam>());
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, Depth.all);
    });

    test("copy", () async {
      final to = Uri.base;
      final overwrite = true;
      final condition = IfOr.notag([]);
      final request = await dispatcher.copy(
          to: to, overwrite: overwrite, condition: condition);
      expect(request.method, WebDavMethod.copy);
      expect(request.param, TypeMatcher<CopyRequestParam>());
      expect(request.param!.destination, same(to));
      expect(request.param!.overwrite, isTrue);
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, Depth.resource);
    });

    test("copyDir", () async {
      final to = Uri.base;
      final overwrite = false;
      final condition = IfOr.notag([]);
      final request = await dispatcher.copyDir(
          to: to, overwrite: overwrite, condition: condition);
      expect(request.method, WebDavMethod.copy);
      expect(request.param, TypeMatcher<CopyRequestParam>());
      expect(request.param!.destination, same(to));
      expect(request.param!.overwrite, isFalse);
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, Depth.all);
    });

    test("move", () async {
      final to = Uri.base;
      final overwrite = true;
      final condition = IfOr.notag([]);
      final request = await dispatcher.move(
          to: to, overwrite: overwrite, condition: condition);
      expect(request.method, WebDavMethod.move);
      expect(request.param, TypeMatcher<MoveRequestParam>());
      expect(request.param!.destination, same(to));
      expect(request.param!.overwrite, isTrue);
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, isNull);
    });

    test("moveDir", () async {
      final to = Uri.base;
      final overwrite = false;
      final condition = IfOr.notag([]);
      final request = await dispatcher.moveDir(
          to: to, overwrite: overwrite, condition: condition);
      expect(request.method, WebDavMethod.move);
      expect(request.param, TypeMatcher<MoveRequestParam>());
      expect(request.param!.destination, same(to));
      expect(request.param!.overwrite, isFalse);
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, Depth.all);
    });

    test("createLock", () async {
      final info = MockLockInfo();
      final timeout = DavTimeout([]);
      final condition = IfOr.notag([]);
      final request = await dispatcher.createLock(
          info: info, timeout: timeout, condition: condition);
      expect(request.method, WebDavMethod.lock);
      expect(request.param, TypeMatcher<LockRequestParam>());
      expect(request.param!.lockInfo, same(info));
      expect(request.param!.timeout, same(timeout));
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, Depth.resource);
    });

    test("createDirLock", () async {
      final info = MockLockInfo();
      final timeout = DavTimeout([]);
      final condition = IfOr.notag([]);
      final request = await dispatcher.createDirLock(
          info: info, timeout: timeout, condition: condition);
      expect(request.method, WebDavMethod.lock);
      expect(request.param, TypeMatcher<LockRequestParam>());
      expect(request.param!.lockInfo, same(info));
      expect(request.param!.timeout, same(timeout));
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, Depth.all);
    });

    test("renewLock", () async {
      final timeout = DavTimeout([]);
      final condition = IfOr.notag([]);
      final request =
          await dispatcher.renewLock(timeout: timeout, condition: condition);
      expect(request.method, WebDavMethod.lock);
      expect(request.param, TypeMatcher<LockRequestParam>());
      expect(request.param!.lockInfo, isNull);
      expect(request.param!.timeout, same(timeout));
      expect(request.param!.condition, same(condition));
      expect(request.param!.depth, isNull);
    });

    test("unlock", () async {
      final token = Uri.base;
      final request = await dispatcher.unlock(token: token);
      expect(request.method, WebDavMethod.unlock);
      expect(request.param, TypeMatcher<UnlockRequestParam>());
      expect(request.param!.lockToken, same(token));
    });
  });
}
