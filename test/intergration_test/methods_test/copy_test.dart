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
  group("test copy", () {
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
        "RFC4918 9.8.6 COPY with Overwrite, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.8.6",
        () async {
      final requestBody = '';
      final responseBody = '';
      final destination = "http://example.com/new/location";

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.noContent;
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.method, WebDavMethod.copy.name);
        expect(event.headers.contentType, isNull);
        expect(event.headers["Destination"]!.first, equals(destination));
        final body = await utf8.decodeStream(event);
        expect(body, requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final request =
          await client.dispatch(addr).copy(to: Uri.parse(destination));
      final response = await request.close();
      final result = await response.parse();
      expect(result!.length, 1);
      expect(result.first.path, equals(addr));
      expect(result.first.status, equals(HttpStatus.noContent));
    });
    test(
        "RFC4918 9.8.7 COPY with No Overwrite, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.8.7",
        () async {
      final requestBody = '';
      final responseBody = '';
      final destination = "http://example.com/new/location";

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.preconditionFailed;
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.method, WebDavMethod.copy.name);
        expect(event.headers.contentType, isNull);
        expect(event.headers["Destination"]!.first, equals(destination));
        expect(event.headers["Overwrite"]!.first, "F");
        final body = await utf8.decodeStream(event);
        expect(body, requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final request = await client
          .dispatch(addr)
          .copy(to: Uri.parse(destination), overwrite: false);
      final response = await request.close();
      final result = await response.parse();
      expect(result!.length, 1);
      expect(result.first.path, equals(addr));
      expect(result.first.status, equals(HttpStatus.preconditionFailed));
    });
    test(
        "RFC4918 9.8.8 COPY of a Collection, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.8.8",
        () async {
      final requestBody = '';
      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>http://www.example.com/othercontainer/R2/</d:href>
    <d:status>HTTP/1.1 423 Locked</d:status>
    <d:error><d:lock-token-submitted/></d:error>
  </d:response>
</d:multistatus>
'''
          .trim();
      final destination = "http://example.com/new/location";

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.multiStatus;
        event.response.headers.contentType =
            ContentType.parse('application/xml; charset="utf-8"');
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.method, WebDavMethod.copy.name);
        expect(event.headers.contentType, isNull);
        expect(event.headers["Destination"]!.first, equals(destination));
        expect(event.headers["Depth"]!.first, "infinity");
        final body = await utf8.decodeStream(event);
        expect(body, requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final request =
          await client.dispatch(addr).copyDir(to: Uri.parse(destination));
      final response = await request.close();
      final result = await response.parse();
      expect(result!.length, 1);
      expect(result.first.path,
          equals(Uri.parse("http://www.example.com/othercontainer/R2/")));
      expect(result.first.status, equals(HttpStatus.locked));
      expect(result.first.error, TypeMatcher<WebDavStdResError>());
      expect(result.first.error!.conditions,
          contains(StdResErrorCond.lockTokenSubmitted));
      expect(result.first.desc, isNull);
      expect(result.first, isEmpty);
      expect(result.first.isEmpty, isTrue);
    });
  });
}
