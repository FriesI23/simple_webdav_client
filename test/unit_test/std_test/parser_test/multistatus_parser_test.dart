// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:simple_webdav_client/src/_std/parser.dart';
import 'package:simple_webdav_client/src/_std/resource.dart';
import 'package:simple_webdav_client/src/response.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

@GenerateMocks([
  ResponseElementParser,
])
import 'multistatus_parser_test.mocks.dart';

void main() {
  group("test BaseMultistatusElementParser", () {
    test("convert", () {
      final responseParser = MockResponseElementParser();
      final parser =
          BaseMultistatusElementParser(responseParser: responseParser);
      final data = XmlDocument.parse("""
<D:multistatus xmlns:D="DAV:">
  <D:response/>
</D:multistatus>
"""
          .trim());
      when(responseParser
              .convert(data.rootElement.getElement("response", namespace: "*")))
          .thenReturn([WebDavStdResource(path: Uri.base, status: 200)]);
      final result = parser.convert(data.rootElement);
      expect(result, equals(TypeMatcher<WebDavResponseResult>()));
      expect(result.first.path, Uri.base);
      expect(result.length, 1);
      verify(responseParser.convert(any)).called(1);
    });
    test("convert empty", () {
      final responseParser = MockResponseElementParser();
      final parser =
          BaseMultistatusElementParser(responseParser: responseParser);
      final data = XmlDocument.parse("""
<D:multistatus xmlns:D="DAV:">
</D:multistatus>
"""
          .trim());
      when(responseParser.convert(any))
          .thenReturn([WebDavStdResource(path: Uri.base, status: 200)]);
      final result = parser.convert(data.rootElement);
      expect(result, equals(TypeMatcher<WebDavResponseResult>()));
      expect(result, isEmpty);
      verifyNever(responseParser.convert(any));
    });
    test("convert multi", () {
      final responseParser = MockResponseElementParser();
      final parser =
          BaseMultistatusElementParser(responseParser: responseParser);
      final data = XmlDocument.parse("""
<D:multistatus xmlns:D="DAV:">
  <D:response/>
  <D:response/>
</D:multistatus>
"""
          .trim());
      when(responseParser
              .convert(data.rootElement.getElement("response", namespace: "*")))
          .thenReturn([
        WebDavStdResource(path: Uri.parse("http://test/1"), status: 200),
        WebDavStdResource(path: Uri.parse("http://test/2"), status: 201)
      ]);
      when(responseParser.convert(
              data.rootElement.findElements("response", namespace: "*").last))
          .thenReturn([
        WebDavStdResource(path: Uri.parse("http://test/3"), status: 400),
        WebDavStdResource(path: Uri.parse("http://test/4"), status: 403)
      ]);
      final result = parser.convert(data.rootElement);
      expect(result, equals(TypeMatcher<WebDavResponseResult>()));
      expect(result.length, 4);
      int i = 0;
      for (var r in result) {
        switch (i) {
          case 0:
            expect(r.path, Uri.parse("http://test/1"));
            expect(r.status, 200);
          case 1:
            expect(r.path, Uri.parse("http://test/2"));
            expect(r.status, 201);
          case 2:
            expect(r.path, Uri.parse("http://test/3"));
            expect(r.status, 400);
          case 3:
            expect(r.path, Uri.parse("http://test/4"));
            expect(r.status, 403);
        }
        i += 1;
      }
      verify(responseParser.convert(any)).called(2);
    });
  });
}
