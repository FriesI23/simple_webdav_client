// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/_std/if.dart';
import 'package:test/test.dart';

void main() {
  group("test IfCondition", () {
    test("IfCondition.token", () {
      final cond = IfCondition.token(Uri.parse("http://example.com"));
      expect(cond.isEtag, isFalse);
      expect(cond.value, "http://example.com");
      expect(cond.toString(), '<http://example.com>');
      expect(cond.not().toString(),
          IfCondition.notToken(Uri.parse("http://example.com")).toString());
    });
    test("IfCondition.notToken", () {
      final cond = IfCondition.notToken(Uri.parse("http://example.com"));
      expect(cond.isEtag, isFalse);
      expect(cond.value, "http://example.com");
      expect(cond.toString(), 'Not <http://example.com>');
      expect(cond.not().toString(),
          IfCondition.token(Uri.parse("http://example.com")).toString());
    });
    test("IfCondition.etag", () {
      final cond = IfCondition.etag('W/"<etag_value>"');
      expect(cond.isEtag, isTrue);
      expect(cond.value, 'W/"<etag_value>"');
      expect(cond.toString(), '[W/"<etag_value>"]');
      expect(cond.not().toString(),
          IfCondition.notEtag('W/"<etag_value>"').toString());
    });
    test("IfCondition.notEtag", () {
      final cond = IfCondition.notEtag('"<etag_value>"');
      expect(cond.isEtag, isTrue);
      expect(cond.value, '"<etag_value>"');
      expect(cond.toString(), 'Not ["<etag_value>"]');
      expect(
          cond.not().toString(), IfCondition.etag('"<etag_value>"').toString());
    });
  });
  group("test IfAnd", () {
    test("IfAnd.tagged", () {
      final obj = IfAnd.tagged(Uri.parse("http://example.com"), [
        IfCondition.etag('W/"<etag_value>"'),
        IfCondition.notToken(Uri.parse("http://example.com")),
      ]);
      expect(obj.toString(),
          '<http://example.com> ([W/"<etag_value>"] Not <http://example.com>)');
      expect(obj.tagged, isTrue);
    });
    test("IfAnd.notag", () {
      final obj = IfAnd.notag([
        IfCondition.notToken(Uri.parse("http://example.com")),
        IfCondition.etag('W/"<etag_value>"'),
      ]);
      expect(obj.toString(), '(Not <http://example.com> [W/"<etag_value>"])');
      expect(obj.tagged, isFalse);
    });
  });
  group("test IfOr", () {
    test("test IfOr.tagged", () {
      final obj = IfOr.tagged([
        IfAnd.tagged(Uri.parse("http://example.com"), [
          IfCondition.etag('W/"<etag_value>"'),
          IfCondition.notToken(Uri.parse("http://example.com")),
        ]),
        IfAnd.tagged(Uri.parse("http://example.com/2"), [
          IfCondition.notEtag('W/"<teg_222>"'),
        ]),
        // notag list will be ignored
        IfAnd.notag([
          IfCondition.notToken(Uri.parse("http://example.com/3")),
          IfCondition.etag('W/"<etag_value333>"'),
        ])
      ]);
      expect(
          obj.toString(),
          '<http://example.com> ([W/"<etag_value>"] Not <http://example.com>)'
          ' <http://example.com/2> (Not [W/"<teg_222>"])');
    });
    test("test IfOr.notag", () {
      final obj = IfOr.notag([
        IfAnd.notag([
          IfCondition.etag('W/"<etag_value>"'),
          IfCondition.notToken(Uri.parse("http://example.com")),
        ]),
        // tagged list will be ignored
        IfAnd.tagged(Uri.parse("http://example.com/2"), [
          IfCondition.notEtag('W/"<teg_222>"'),
        ]),
        IfAnd.notag([
          IfCondition.token(Uri.parse("http://example.com/3")),
          IfCondition.notEtag('W/"<etag_value333>"'),
        ])
      ]);
      expect(
          obj.toString(),
          '([W/"<etag_value>"] Not <http://example.com>)'
          ' (<http://example.com/3> Not [W/"<etag_value333>"])');
    });
  });
  group("test if.toString examples on RFC4918", () {
    test('"No-Tag-List" format', () {
      final ifOr = IfOr.notag([
        IfAnd.notag([
          IfCondition.token(
              Uri.parse("urn:uuid:150852e2-3847-42d5-8cbe-0f4f296f26cf"))
        ])
      ]);
      expect(
          ifOr.toString(), "(<urn:uuid:150852e2-3847-42d5-8cbe-0f4f296f26cf>)");
    });
    test('"Tagged-List" format, for "http://example.com/locked/":', () {
      final ifOr = IfOr.tagged([
        IfAnd.tagged(Uri.parse("http://example.com/locked/"), [
          IfCondition.token(
              Uri.parse("urn:uuid:150852e2-3847-42d5-8cbe-0f4f296f26cf"))
        ])
      ]);
      expect(
          ifOr.toString(),
          "<http://example.com/locked/>"
          " (<urn:uuid:150852e2-3847-42d5-8cbe-0f4f296f26cf>)");
    });
    test('"Tagged-List" format, for "http://example.com/locked/member":', () {
      final ifOr = IfOr.tagged([
        IfAnd.tagged(Uri.parse("http://example.com/locked/member"), [
          IfCondition.token(
              Uri.parse("urn:uuid:150852e2-3847-42d5-8cbe-0f4f296f26cf"))
        ])
      ]);
      expect(
          ifOr.toString(),
          "<http://example.com/locked/member>"
          " (<urn:uuid:150852e2-3847-42d5-8cbe-0f4f296f26cf>)");
    });
  });
}
