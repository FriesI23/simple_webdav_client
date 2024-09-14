// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:simple_webdav_client/src/_std/resource.dart';
import 'package:simple_webdav_client/src/io.dart';
import 'package:test/test.dart';

void main() {
  group("test WebDavStdResourceProp", () {
    test("constructor", () {
      final prop = WebDavStdResourceProp(
          name: "prop",
          namespace: Uri.base,
          status: HttpStatus.badGateway,
          desc: "desc",
          error: WebDavStdResError("test"),
          value: 123,
          lang: "en-us");
      expect(prop.name, "prop");
      expect(prop.namespace, Uri.base);
      expect(prop.status, HttpStatus.badGateway);
      expect(prop.desc, "desc");
      expect(prop.error, TypeMatcher<WebDavStdResError>());
      expect(prop.value, 123);
      expect(prop.lang, "en-us");
    });
    test("toDebugString", () {
      final prop = WebDavStdResourceProp(
          name: "prop",
          namespace: Uri.parse("https://example.com"),
          status: HttpStatus.badGateway,
          desc: "desc",
          error: WebDavStdResError("test", conditions: [
            StdResErrorCond.noConflictingLock,
            StdResErrorCond.cannotModifyProtectedProperty
          ]),
          value: 123,
          lang: "en-us");
      expect(
          prop.toDebugString(),
          "WebDavStdResourceProp<int>"
          "{name:prop,ns:https://example.com,status:502,desc:desc,"
          "err:StdResErrorCond{test, "
          "cond=[no-conflicting-lock,cannot-modify-protected-property]},"
          "value:123}");
    });
  });
  group("test WebDavStdResource", () {
    test("constructor", () {
      final path = Uri.parse("http://example.com/file");
      final resource =
          WebDavStdResource(path: path, status: HttpStatus.accepted);
      expect(resource.path, path);
      expect(resource.status, HttpStatus.accepted);
      expect(resource.desc, isNull);
      expect(resource.error, isNull);
      expect(resource.redirect, isNull);
      expect(resource.props, isEmpty);
      expect(resource.isEmpty, isTrue);
      expect(resource.isNotEmpty, isFalse);
      expect(resource.length, 0);
      expect(
          resource.toDebugString(),
          """
WebDavStdResource{
  path:http://example.com/file | status:202,
  props(0):
}
"""
              .trim());
    });
    test("constructor with param", () {
      final path = Uri.parse("http://example.com/file");
      final resource = WebDavStdResource(
          path: path,
          status: HttpStatus.multiStatus,
          error: WebDavStdResError("test"),
          desc: "desc",
          redirect: Uri.parse("http://redirect"),
          props: {
            (name: "prop", ns: "DAV:"): WebDavStdResourceProp(
                name: "prop1",
                status: HttpStatus.accepted,
                namespace: Uri.parse("DAV:")),
          });
      expect(resource.path, path);
      expect(resource.status, HttpStatus.multiStatus);
      expect(resource.desc, "desc");
      expect(resource.error, TypeMatcher<WebDavStdResError>());
      expect(resource.redirect, Uri.parse("http://redirect"));
      expect(resource.props.length, 1);
      expect(resource.isEmpty, isFalse);
      expect(resource.isNotEmpty, isTrue);
      expect(resource.length, 1);
      expect(
          resource.toDebugString(),
          """
WebDavStdResource{
  path:http://example.com/file | status:207,
  err:StdResErrorCond{test, cond=[]},
  desc:desc,
  props(1):
    [DAV:]prop: WebDavStdResourceProp<dynamic>{name:prop1,ns:dav:,status:202,value:null},
}

"""
              .trim());
    });
    test("constructor.fromProps", () {
      final path = Uri.parse("http://example.com/file");
      final resource = WebDavStdResource.fromProps(
          path: path,
          status: HttpStatus.multiStatus,
          error: WebDavStdResError("test"),
          desc: "desc",
          redirect: Uri.parse("http://redirect"),
          props: [
            WebDavStdResourceProp<dynamic>(
                name: "prop1",
                status: HttpStatus.accepted,
                namespace: Uri.parse("DAV:")),
            WebDavStdResourceProp<int>(
                name: "prop2", status: HttpStatus.accepted, value: 123),
            WebDavStdResourceProp<String>(
                name: "prop1",
                status: HttpStatus.notFound,
                namespace: Uri.parse("DAV:"),
                value: "test"),
          ]);
      expect(resource.path, path);
      expect(resource.status, HttpStatus.multiStatus);
      expect(resource.desc, "desc");
      expect(resource.error, TypeMatcher<WebDavStdResError>());
      expect(resource.redirect, Uri.parse("http://redirect"));
      expect(resource.props.length, 2);
      expect(resource.isEmpty, isFalse);
      expect(resource.isNotEmpty, isTrue);
      expect(resource.length, 2);
      expect(resource.props.where((e) => e.name == 'prop1').length, 1);
      expect(resource.props.where((e) => e.name == 'prop1').first.namespace,
          Uri.parse("DAV:"));
      expect(
          resource.props.where((e) => e.name == 'prop1').first.value, "test");
      expect(resource.props.where((e) => e.name == 'prop2').length, 1);
      expect(resource.props.where((e) => e.name == 'prop2').first.namespace,
          isNull);
      expect(resource.props.where((e) => e.name == 'prop2').first.value, 123);
      expect(
          resource.toDebugString(),
          """
WebDavStdResource{
  path:http://example.com/file | status:207,
  err:StdResErrorCond{test, cond=[]},
  desc:desc,
  props(2):
    [dav:]prop1: WebDavStdResourceProp<String>{name:prop1,ns:dav:,status:404,value:test},
    prop2: WebDavStdResourceProp<int>{name:prop2,status:202,value:123},
}
"""
              .trim());
    });
    test("find", () {
      final path = Uri.parse("http://example.com/file");
      final resource = WebDavStdResource.fromProps(
          path: path,
          status: HttpStatus.multiStatus,
          error: WebDavStdResError("test"),
          desc: "desc",
          redirect: Uri.parse("http://redirect"),
          props: [
            WebDavStdResourceProp<String>(
                name: "prop1",
                status: HttpStatus.notFound,
                namespace: Uri.parse("DAV:"),
                value: "test"),
            WebDavStdResourceProp<int>(
                name: "prop2", status: HttpStatus.accepted, value: 123),
          ]);
      expect(resource.path, path);
      expect(resource.status, HttpStatus.multiStatus);
      expect(resource.desc, "desc");
      expect(resource.error, TypeMatcher<WebDavStdResError>());
      expect(resource.redirect, Uri.parse("http://redirect"));
      expect(resource.props.length, 2);
      expect(resource.isEmpty, isFalse);
      expect(resource.isNotEmpty, isTrue);
      expect(resource.length, 2);
      final prop1 = resource.props.where((e) => e.name == 'prop1').first;
      final prop2 = resource.props.where((e) => e.name == 'prop2').first;
      expect(resource.find("prop1", emptyNamespace: false), equals([prop1]));
      expect(resource.find("prop1", namespace: "DAV:"), equals([prop1]));
      expect(resource.find("prop1", namespace: "CUS:"), isEmpty);
      expect(resource.find("prop1"), isEmpty);
      expect(resource.find("prop2", emptyNamespace: false), equals([prop2]));
      expect(resource.find("prop2"), equals([prop2]));
      expect(resource.find("prop2", namespace: "DAV:"), isEmpty);
      expect(resource.find("prop3", emptyNamespace: false), isEmpty);
      expect(resource.findByNamespace("DAV:"), equals([prop1]));
      expect(resource.findByNamespace(null), equals([prop2]));
      expect(resource.findByNamespace("DAV:", name: "prop1"), equals([prop1]));
      expect(resource.findByNamespace("DAV:", name: "prop2"), isEmpty);
      expect(resource.findByNamespace(null, name: "prop1"), isEmpty);
      expect(resource.findByNamespace(null, name: "prop2"), equals([prop2]));
    });
  });
}
