// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';
import 'dart:io';

import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/error.dart';
import 'package:test/test.dart';

import '../server.dart';

void main() {
  group("test delete", () {
    late final TestUsagedHttpServer server;
    late final WebDavStdClient client;
    late final Uri addr;

    setUpAll(() async {
      server = TestUsagedHttpServer();
      await server.open();
      client = WebDavClient.std();
      addr = Uri(scheme: 'http', host: "localhost", port: server.bindPort);
    });

    tearDownAll(() async {
      client.close();
      server.close();
    });

    setUp(() {
      server.expectedResponse = null;
      server.serverSideChecker = null;
    });

    test(
        "RFC4918 9.3.2 DELETE, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.6.2",
        () async {
      final requestBody = '';
      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>http://www.example.com/container/resource3</d:href>
    <d:status>HTTP/1.1 423 Locked</d:status>
    <d:error><d:lock-token-submitted/></d:error>
  </d:response>
</d:multistatus>
'''
          .trim();

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.headers.contentType =
            ContentType.parse('application/xml; charset="utf-8"');
        event.response.statusCode = HttpStatus.multiStatus;
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.method, WebDavMethod.delete.name);
        expect(event.headers.contentType, isNull);
        final body = await utf8.decodeStream(event);
        expect(body, requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final request = await client.dispatch(addr).delete();
      final response = await request.close();
      expect(response.body, isNull);
      final result = await response.parse();
      expect(response.body, responseBody);
      expect(result!.length, 1);
      final resource = result.first;
      expect(resource.path,
          Uri.parse("http://www.example.com/container/resource3"));
      expect(resource.status, HttpStatus.locked);
      expect(resource.desc, isNull);
      expect(resource.error, TypeMatcher<WebDavStdResError>());
      expect(resource.error!.conditions,
          contains(StdResErrorCond.lockTokenSubmitted));
      expect(resource.error!.message, '');
      expect(resource.isEmpty, isTrue);
      expect(resource.props, isEmpty);
    });
  });
}
