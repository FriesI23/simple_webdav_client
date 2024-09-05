// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:simple_webdav_client/src/dav/content_type.dart';
import 'package:test/test.dart';

void main() {
  test("test applicationXml content type", () {
    final ct = XmlContentType.applicationXml;
    expect(ct.primaryType, "application");
    expect(ct.subType, "xml");
    expect(ct.charset, "utf-8");
  });
  test("test textXml content type", () {
    final ct = XmlContentType.textXml;
    expect(ct.primaryType, "text");
    expect(ct.subType, "xml");
    expect(ct.charset, "utf-8");
  });
}
