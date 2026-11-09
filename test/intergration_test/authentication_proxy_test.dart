// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:simple_webdav_client/client.dart';
import 'package:test/test.dart';

import 'server.dart';

typedef _Visit = ({
  String method,
  String body,
  String? originAuth,
  String? proxyAuth,
});

void main() {
  late TestUsagedHttpServer proxy;
  late List<_Visit> visits;
  late List<WebDavStdClient> clients;
  late String challenge;
  Future<void> Function(HttpRequest)? respond;
  const payload = 'important payload';

  WebDavStdClient client(
    Uri root,
    WebDavAuthenticationMode mode, {
    String? proxyConfiguration,
  }) {
    final http = HttpClient()
      ..findProxy = (_) =>
          proxyConfiguration ?? 'PROXY 127.0.0.1:${proxy.bindPort}';
    final result = WebDavStdClient.authenticated(
      client: http,
      authentication: WebDavAuthenticationConfig(
        scope: root,
        username: 'user',
        password: 'password',
        mode: mode,
        allowInsecureBasic: root.scheme == 'http',
        discoveryTimeout: const Duration(seconds: 1),
      ),
    );
    clients.add(result);
    return result;
  }

  Future<int> put(WebDavStdClient client, Uri root) async {
    final response =
        await (await client
                .dispatch(root.resolve('file'))
                .create(data: payload))
            .close();
    await response.response.drain<void>();
    return response.response.statusCode;
  }

  setUp(() async {
    visits = [];
    clients = [];
    challenge = 'Basic realm="proxy"';
    respond = null;
    proxy = TestUsagedHttpServer();
    proxy.expectedResponse = (request) async {
      visits.add((
        method: request.method,
        body: await utf8.decoder.bind(request).join(),
        originAuth: request.headers.value(HttpHeaders.authorizationHeader),
        proxyAuth: request.headers.value(HttpHeaders.proxyAuthorizationHeader),
      ));
      if (respond case final handler?) {
        await handler(request);
      } else {
        request.response.statusCode = HttpStatus.proxyAuthenticationRequired;
        request.response.headers.set(
          HttpHeaders.proxyAuthenticateHeader,
          challenge,
        );
      }
      return true;
    };
    await proxy.open(additionalMethods: const {'CONNECT'});
  });

  tearDown(() async {
    for (final client in clients) {
      client.close(force: true);
    }
    await proxy.close();
  });

  for (final mode in WebDavAuthenticationMode.values) {
    for (final scheme in ['http', 'https']) {
      for (final offered in [
        'Basic realm="proxy"',
        'Digest realm="proxy", nonce="fixed", qop="auth"',
        'Basic realm="proxy", Bearer realm="proxy-oauth"',
      ]) {
        test(
          '$mode $scheme proxy refusal fails without retries: $offered',
          () async {
            challenge = offered;
            final root = Uri.parse('$scheme://origin.example.test/');
            final operation = put(
              client(root, mode),
              root,
            ).timeout(const Duration(seconds: 2));
            if (scheme == 'http' &&
                mode == WebDavAuthenticationMode.basic &&
                !offered.contains('Bearer')) {
              expect(await operation, HttpStatus.proxyAuthenticationRequired);
            } else {
              await expectLater(operation, throwsA(isA<HttpException>()));
            }
            expect(visits, hasLength(1));
            expect(visits.single.proxyAuth, isNull);
            if (scheme == 'https') {
              expect(visits.single.method, 'CONNECT');
              expect(visits.single.originAuth, isNull);
              expect(visits.single.body, isEmpty);
            } else if (mode == WebDavAuthenticationMode.basic) {
              expect(visits.single.method, WebDavMethod.put.name);
              expect(visits.single.body, payload);
            } else {
              expect(visits.single.method, WebDavMethod.propfind.name);
              expect(visits.single.originAuth, isNull);
            }
          },
        );
      }

      test('$mode $scheme propagates unsupported SDK proxy directives', () async {
        final root = Uri.parse('$scheme://origin.example.test/');
        final managed = client(
          root,
          mode,
          proxyConfiguration:
              'HTTPS proxy-user:private-proxy-password@127.0.0.1:${proxy.bindPort}',
        );
        await expectLater(
          put(managed, root).timeout(const Duration(seconds: 2)),
          throwsA(
            isA<HttpException>().having(
              (e) => e is WebDavAuthenticationError,
              'package error',
              isFalse,
            ),
          ),
        );
        expect(visits, isEmpty);
      });

      test('$mode $scheme proxy connection failure stays bounded', () async {
        final unavailable = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final port = unavailable.port;
        await unavailable.close(force: true);
        final root = Uri.parse('$scheme://origin.example.test/');
        final managed = client(
          root,
          mode,
          proxyConfiguration: 'PROXY 127.0.0.1:$port',
        );
        await expectLater(
          put(managed, root).timeout(const Duration(seconds: 2)),
          throwsA(isA<SocketException>()),
        );
        expect(visits, isEmpty);
      });
    }

    for (final password in ['proxy-password', 'wrong']) {
      test(
        '$mode preemptive Basic proxy credentials preserve PUT ($password)',
        () async {
          final expectedProxy =
              'Basic ${base64Encode(utf8.encode('proxy-user:proxy-password'))}';
          final expectedOrigin =
              'Basic ${base64Encode(utf8.encode('user:password'))}';
          respond = (request) async {
            if (request.headers.value(HttpHeaders.proxyAuthorizationHeader) !=
                expectedProxy) {
              request.response.statusCode =
                  HttpStatus.proxyAuthenticationRequired;
              request.response.headers.set(
                HttpHeaders.proxyAuthenticateHeader,
                'Basic realm="proxy"',
              );
            } else if (request.headers.value(HttpHeaders.authorizationHeader) !=
                expectedOrigin) {
              request.response.statusCode = HttpStatus.unauthorized;
              request.response.headers.set(
                HttpHeaders.wwwAuthenticateHeader,
                'Basic realm="origin", Bearer realm="oauth"',
              );
            } else {
              request.response.statusCode = HttpStatus.created;
            }
          };
          final root = Uri.parse('http://origin.example.test/');
          final managed = client(
            root,
            mode,
            proxyConfiguration:
                'PROXY proxy-user:$password@127.0.0.1:${proxy.bindPort}',
          );
          if (password == 'wrong' && mode == WebDavAuthenticationMode.auto) {
            await expectLater(
              put(managed, root),
              throwsA(
                isA<WebDavAuthenticationError>().having(
                  (e) => e.statusCode,
                  'status',
                  HttpStatus.proxyAuthenticationRequired,
                ),
              ),
            );
          } else {
            expect(
              await put(managed, root),
              password == 'wrong'
                  ? HttpStatus.proxyAuthenticationRequired
                  : HttpStatus.created,
            );
          }
          final puts = visits
              .where((v) => v.method == WebDavMethod.put.name)
              .toList();
          if (password == 'wrong' && mode == WebDavAuthenticationMode.auto) {
            expect(puts, isEmpty);
          } else {
            expect(puts, hasLength(1));
            expect(puts.single.body, payload);
          }
        },
      );
    }
  }

  for (final mode in ['legacy', ...WebDavAuthenticationMode.values]) {
    test('$mode retains caller-controlled SDK proxy authentication', () async {
      respond = (request) async {
        if (request.headers.value(HttpHeaders.proxyAuthorizationHeader) ==
            null) {
          request.response.statusCode = HttpStatus.proxyAuthenticationRequired;
          request.response.headers.set(
            HttpHeaders.proxyAuthenticateHeader,
            'Basic realm="proxy"',
          );
        } else {
          request.response.statusCode = HttpStatus.ok;
        }
      };
      final root = Uri.parse('http://origin.example.test/');
      final WebDavStdClient configured;
      if (mode is WebDavAuthenticationMode) {
        configured = client(root, mode);
      } else {
        final http = HttpClient()
          ..findProxy = (_) => 'PROXY 127.0.0.1:${proxy.bindPort}';
        configured = WebDavStdClient.withClient(http);
        clients.add(configured);
      }
      var attempts = 0;
      configured.setAuthenticateProxy((host, port, scheme, realm) async {
        if (attempts++ >= 2) return false;
        configured.addProxyCredentials(
          host,
          port,
          realm ?? '',
          HttpClientBasicCredentials('proxy-user', 'proxy-password'),
        );
        return true;
      });
      final response = await (await configured.dispatch(root).get()).close();
      await response.response.drain<void>();
      expect(response.response.statusCode, HttpStatus.ok);
      expect(attempts, greaterThan(0));
      expect(visits.last.proxyAuth, isNotNull);
    });
  }

  for (final scheme in ['http', 'https']) {
    test('automatic $scheme proxy discovery has a response deadline', () async {
      final gate = Completer<void>();
      respond = (_) => gate.future;
      final root = Uri.parse('$scheme://origin.example.test/');
      final managed = client(root, WebDavAuthenticationMode.auto);
      try {
        await expectLater(
          put(managed, root).timeout(const Duration(seconds: 2)),
          throwsA(
            isA<WebDavAuthenticationError>().having(
              (e) => e.message,
              'message',
              'Authentication discovery timed out',
            ),
          ),
        );
        expect(managed.closed, isTrue);
        expect(visits, hasLength(1));
        expect(visits.single.originAuth, isNull);
      } finally {
        gate.complete();
      }
    });
  }
}
