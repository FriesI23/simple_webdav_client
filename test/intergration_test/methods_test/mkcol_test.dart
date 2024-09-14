// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';

import 'package:simple_webdav_client/client.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../server.dart';

void main() {
  group("test mkcol", () {
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
      await server.close();
    });

    setUp(() {
      server.expectedResponse = null;
      server.serverSideChecker = null;
    });

    test(
        "RFC4918 9.3.2 MKCOL, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.3.2",
        () async {
      final requestBody = '';
      final responseBody = '';

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.created;
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.method, WebDavMethod.mkcol.name);
        expect(event.headers.contentType, isNull);
        final body = await utf8.decodeStream(event);
        expect(body, requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final request = await client.dispatch(addr).createDir();
      final response = await request.close();
      final result = await response.parse();
      expect(response.body, responseBody);
      expect(result!.length, 1);
      expect(result.first.path, equals(addr));
      expect(result.first.props, isEmpty);
      expect(result.first.status, HttpStatus.created);
      expect(result.first.error, isNull);
      expect(result.first.desc, isNull);
    });
  });
}
