// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';
import 'dart:io';

import 'package:simple_webdav_client/client.dart';
import 'package:test/test.dart';

import '../server.dart';

void main() {
  group("test unlock", () {
    late final TestUsagedHttpServer server;
    late final WebDavStdClient client;
    late Uri addr;

    setUpAll(() async {
      server = TestUsagedHttpServer();
      await server.open();

      addr = Uri(scheme: 'http', host: "localhost", port: server.bindPort);
    });

    tearDownAll(() async {
      server.close();
    });

    setUp(() {
      client = WebDavClient.std();
      server.expectedResponse = null;
      server.serverSideChecker = null;
    });

    tearDown(() {
      client.close();
    });

    test(
        "RFC4918 9.9.6 UNLOCK, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.11.2",
        () async {
      addr = Uri(
          scheme: addr.scheme,
          host: addr.host,
          port: addr.port,
          path: "/workspace/webdav/info.doc");
      final requestBody = '';
      final responseBody = '';
      final lockToken = "urn:uuid:a515cfa4-5da4-22e1-f5b5-00a0451e6bf7";

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.noContent;
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.method, WebDavMethod.unlock.name);
        expect(event.headers.contentType, isNull);
        final body = await utf8.decodeStream(event);
        expect(body, requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final uri = Uri(
          scheme: addr.scheme,
          host: addr.host,
          port: addr.port,
          path: "/workspace/webdav/");
      final credentials = HttpClientDigestCredentials("ejw", "");
      final realm = "ejw@example.com";
      client.addCredentials(uri, realm, credentials);

      final request =
          await client.dispatch(addr).unlock(token: Uri.parse(lockToken));
      final response = await request.close();
      expect(response.body, isNull);
      final result = await response.parse();
      expect(response.body, "");
      expect(result!.length, 1);
      expect(result.first.status, HttpStatus.noContent);
      expect(result.first.path, equals(addr));
    });
  });
}
