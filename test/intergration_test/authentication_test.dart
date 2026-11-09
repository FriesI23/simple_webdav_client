// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http_parser/http_parser.dart' show AuthenticationChallenge;
import 'package:mockito/mockito.dart' show Fake;
import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/utils.dart' show Depth;
import 'package:test/test.dart';

import 'server.dart';

const _basic = 'Basic realm="WebDAV"';
const _mixed = '$_basic, Bearer resource_metadata="https://example.test/meta"';
final _authorization = 'Basic ${base64Encode(utf8.encode('user:password'))}';
typedef _Visit = ({String method, String path, String? auth, String body});

void main() {
  late TestUsagedHttpServer server;
  late Uri root;
  late List<_Visit> visits;
  late List<WebDavStdClient> clients;
  late List<String> challenges;
  Future<void> Function(HttpRequest, String)? handler;

  WebDavStdClient client({
    WebDavAuthenticationMode mode = WebDavAuthenticationMode.auto,
    String password = 'password',
    bool allowInsecureBasic = true,
    Uri? scope,
    Uri? probeUri,
    Duration timeout = const Duration(seconds: 3),
    HttpClient? http,
    Future<ConnectionTask<Socket>> Function(Uri, String?, int?)?
    connectionFactory,
  }) {
    final result = WebDavStdClient.authenticated(
      client: http,
      connectionFactory: connectionFactory,
      authentication: WebDavAuthenticationConfig(
        scope: scope ?? root,
        probeUri: probeUri,
        username: 'user',
        password: password,
        mode: mode,
        allowInsecureBasic: allowInsecureBasic,
        discoveryTimeout: timeout,
      ),
    );
    clients.add(result);
    return result;
  }

  Future<int> get(WebDavStdClient client, [Uri? uri]) async {
    final response = await (await client.dispatch(uri ?? root).get()).close();
    await response.response.drain<void>();
    return response.response.statusCode;
  }

  Future<void> expectRedirectResponse(WebDavStdClient client, Uri scope) async {
    handler = (request, body) async {
      if (scope.scheme == 'https') {
        expect(
          request.headers.value(HttpHeaders.proxyAuthorizationHeader),
          isNull,
        );
      }
      request.response.statusCode = HttpStatus.found;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        'http://outside.invalid/private',
      );
    };
    final response =
        await (await client
                .dispatch(scope.resolve('redirect'))
                .create(data: 'payload'))
            .close()
            .timeout(const Duration(seconds: 2));
    expect(response.response.statusCode, HttpStatus.found);
    expect(response.response.redirects, isEmpty);
    await response.response.drain<void>();
  }

  void requireDigest({String? qop = 'auth', Map<String, String>? files}) {
    final challenge =
        'Digest realm="WebDAV", nonce="fixed-nonce", algorithm=MD5${qop == null ? '' : ', qop="$qop"'}';
    handler = (request, body) async {
      final header = request.headers.value(HttpHeaders.authorizationHeader);
      final fields = header == null
          ? <String, String>{}
          : AuthenticationChallenge.parse(header).parameters;
      String hash(String value) => md5.convert(utf8.encode(value)).toString();
      final ha1 = hash('user:WebDAV:password');
      final ha2 = hash('${request.method}:${request.uri}');
      final expected = qop == null
          ? hash('$ha1:fixed-nonce:$ha2')
          : hash(
              '$ha1:fixed-nonce:${fields['nc']}:${fields['cnonce']}:auth:$ha2',
            );
      if (fields['response'] != expected ||
          fields['uri'] != request.uri.toString()) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.set(
          HttpHeaders.wwwAuthenticateHeader,
          challenge,
        );
        return;
      }
      if (request.method == WebDavMethod.put.name) {
        files?[request.uri.path] = body;
        request.response.statusCode = HttpStatus.created;
      } else if (request.method == WebDavMethod.get.name) {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(files?[request.uri.path] ?? '');
      } else {
        request.response.statusCode = HttpStatus.multiStatus;
      }
    };
  }

  setUp(() async {
    server = TestUsagedHttpServer();
    visits = [];
    clients = [];
    challenges = [_mixed];
    handler = null;
    server.expectedResponse = (request) async {
      final body = await utf8.decoder.bind(request).join();
      visits.add((
        method: request.method,
        path: request.uri.path,
        auth: request.headers.value(HttpHeaders.authorizationHeader),
        body: body,
      ));
      final custom = handler;
      if (custom != null) {
        await custom(request, body);
      } else if (request.headers.value(HttpHeaders.authorizationHeader) !=
          _authorization) {
        request.response.statusCode = HttpStatus.unauthorized;
        for (final value in challenges) {
          request.response.headers.add(
            HttpHeaders.wwwAuthenticateHeader,
            value,
          );
        }
      } else {
        request.response.statusCode =
            request.method == WebDavMethod.propfind.name
            ? HttpStatus.multiStatus
            : HttpStatus.ok;
      }
      return true;
    };
    await server.open();
    root = Uri.parse('http://127.0.0.1:${server.bindPort}/');
  });

  tearDown(() async {
    for (final client in clients) {
      client.close(force: true);
    }
    await server.close();
  });

  for (final headers in <List<String>>[
    [_basic],
    [_mixed],
    ['Bearer realm="oauth", $_basic'],
    ['Bearer realm="oauth"', _basic],
    [
      'bAsIc ReAlM="WebDAV, \\"quoted\\"", CHARSET="UTF-8", Bearer realm="oauth"',
    ],
    ['Digest realm="other", nonce="nonce", $_basic'],
    ['Basic realm="first", realm="last"'],
  ]) {
    test('auto discovers Basic from $headers', () async {
      challenges = headers;
      expect(await get(client()), HttpStatus.ok);
      expect(visits.map((v) => v.method), [
        WebDavMethod.propfind.name,
        WebDavMethod.get.name,
      ]);
      expect(visits.first.auth, isNull);
      expect(visits.last.auth, _authorization);
    });
  }

  test('first PUT retains payload and custom request headers', () async {
    final data = jsonEncode({'name': '习惯', 'value': 42});
    handler = (request, body) async {
      if (request.method == WebDavMethod.propfind.name) {
        expect(request.headers.value(Depth.headerKey), Depth.resource.name);
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.set(HttpHeaders.wwwAuthenticateHeader, _mixed);
      } else {
        expect(request.method, WebDavMethod.put.name);
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          _authorization,
        );
        expect(request.headers.value(HttpHeaders.ifMatchHeader), '"etag"');
        expect(
          request.headers.contentType?.mimeType,
          ContentType.json.mimeType,
        );
        expect(body, data);
        request.response.statusCode = HttpStatus.created;
      }
    };
    final request = await client()
        .dispatch(root.resolve('habit.json'))
        .create(data: data);
    request.request.headers.contentType = ContentType.json;
    request.request.headers.set(HttpHeaders.ifMatchHeader, '"etag"');
    request.request.contentLength = utf8.encode(data).length;
    final response = await request.close();
    await response.response.drain<void>();
    expect(response.response.statusCode, HttpStatus.created);
    expect(
      visits.where((v) => v.method == WebDavMethod.put.name),
      hasLength(1),
    );
  });

  test(
    'forced Basic skips discovery and retains a normal wrong-password 401',
    () async {
      final basic = client(mode: WebDavAuthenticationMode.basic);
      expect(await get(basic), HttpStatus.ok);
      expect(visits.single.method, WebDavMethod.get.name);
      expect(
        await get(
          client(mode: WebDavAuthenticationMode.basic, password: 'wrong'),
        ),
        HttpStatus.unauthorized,
      );
    },
  );

  test('automatic Basic wrong password returns 401 without retrying', () async {
    expect(await get(client(password: 'wrong')), HttpStatus.unauthorized);
    expect(visits, hasLength(2));
  });

  for (final mode in WebDavAuthenticationMode.values) {
    test('$mode concurrent first requests share initialization', () async {
      final auth = client(mode: mode);
      final expectedProbes = switch (mode) {
        WebDavAuthenticationMode.auto => 1,
        WebDavAuthenticationMode.basic => 0,
      };
      expect(
        await Future.wait(List.generate(8, (_) => get(auth))),
        everyElement(HttpStatus.ok),
      );
      expect(
        visits.where((v) => v.method == WebDavMethod.propfind.name),
        hasLength(expectedProbes),
      );
      expect(await get(auth), HttpStatus.ok);
      expect(
        visits.where((v) => v.method == WebDavMethod.propfind.name),
        hasLength(expectedProbes),
      );
    });

    test('$mode close before first request prevents initialization', () async {
      final auth = client(mode: mode);
      auth.close();
      expect(auth.closed, isTrue);
      await expectLater(get(auth), throwsStateError);
      expect(visits, isEmpty);
    });
  }

  test(
    'missing sync directory discovers authentication at its parent',
    () async {
      handler = (request, body) async {
        if (request.uri.path != '/dav/') {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response.statusCode =
              request.method == WebDavMethod.propfind.name
              ? HttpStatus.unauthorized
              : HttpStatus.ok;
          if (request.method == WebDavMethod.propfind.name) {
            request.response.headers.set(
              HttpHeaders.wwwAuthenticateHeader,
              _mixed,
            );
          }
        }
      };
      expect(
        await get(
          client(
            scope: root.resolve('dav/'),
            probeUri: root.resolve('dav/new/nested/'),
          ),
          root.resolve('dav/'),
        ),
        HttpStatus.ok,
      );
      expect(visits.map((v) => v.path), [
        '/dav/new/nested/',
        '/dav/new/',
        '/dav/',
        '/dav/',
      ]);
      expect(visits.take(3).map((v) => v.auth), everyElement(isNull));
    },
  );

  test('parent discovery stops at scope boundary', () async {
    handler = (request, body) async {
      request.response.statusCode = HttpStatus.notFound;
    };
    final auth = client(
      scope: root.resolve('dav/'),
      probeUri: root.resolve('dav/new/'),
    );
    await expectLater(
      get(auth, root.resolve('dav/')),
      throwsA(
        isA<WebDavAuthenticationError>().having(
          (e) => e.statusCode,
          'status',
          HttpStatus.notFound,
        ),
      ),
    );
    expect(visits.map((v) => v.path), ['/dav/new/', '/dav/']);
  });

  test('anonymous successful discovery does not send credentials', () async {
    handler = (request, body) async {
      request.response.statusCode = HttpStatus.ok;
    };
    expect(await get(client()), HttpStatus.ok);
    expect(visits.map((v) => v.auth), everyElement(isNull));
  });

  for (final headers in <List<String>>[
    ['Bearer realm="oauth"'],
    // http_parser's RFC 2617 parser rejects token68, even beside Basic.
    ['Bearer abc=='],
    ['Bearer abc==', _basic],
    ['$_basic, Bearer abc=='],
    ['Bearer abc==, $_basic'],
    ['Basic realm="unterminated'],
    ['Basic'],
    ['Digest realm="r", nonce="n", Bearer realm="b"'],
    ['Digest realm="r", nonce="n", algorithm=SHA-256'],
    ['Digest realm="r", nonce="n", qop="auth-int"'],
    ['Digest realm="r", nonce="n", qop="auth,auth-int"'],
    ['Digest realm="r", nonce="n", qop=" auth "'],
    ['Digest realm="r", nonce="n", charset="unknown"'],
    ['Digest realm="r", nonce="n", userhash=true'],
  ]) {
    test('unsupported/malformed challenge fails bounded: $headers', () async {
      challenges = headers;
      final auth = client();
      await expectLater(
        get(auth),
        throwsA(
          isA<WebDavAuthenticationError>().having(
            (e) => e.statusCode,
            'status',
            HttpStatus.unauthorized,
          ),
        ),
      );
      await expectLater(get(auth), throwsA(isA<WebDavAuthenticationError>()));
      expect(visits, hasLength(1));
    });
  }

  test('insecure Basic requires explicit opt-in', () async {
    await expectLater(
      get(client(allowInsecureBasic: false)),
      throwsA(isA<WebDavAuthenticationError>()),
    );
    expect(visits.single.auth, isNull);
    visits.clear();
    await expectLater(
      get(
        client(mode: WebDavAuthenticationMode.basic, allowInsecureBasic: false),
      ),
      throwsA(isA<WebDavAuthenticationError>()),
    );
    expect(visits, isEmpty);
  });

  test(
    'scope rejects another origin, sibling prefix and encoded traversal',
    () async {
      for (final mode in WebDavAuthenticationMode.values) {
        final auth = client(mode: mode, scope: root.resolve('dav/'));
        for (final uri in [
          root.replace(port: root.port + 1),
          root.resolve('dav-other/'),
          root.resolve('dav/%2e%2e/private/'),
          root.replace(scheme: 'https', path: '/dav/'),
        ]) {
          await expectLater(
            get(auth, uri),
            throwsA(isA<WebDavAuthenticationError>()),
          );
        }
      }
      expect(visits, isEmpty);
    },
  );

  test(
    'authenticated requests return redirects without following them',
    () async {
      handler = (request, body) async {
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          root.resolve('other/').toString(),
        );
      };
      expect(
        await get(client(mode: WebDavAuthenticationMode.basic)),
        HttpStatus.found,
      );
      expect(visits, hasLength(1));
    },
  );

  test('discovery redirect is a bounded error without credentials', () async {
    handler = (request, body) async {
      request.response.statusCode = HttpStatus.found;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        'http://example.test/',
      );
    };
    await expectLater(
      get(client()),
      throwsA(
        isA<WebDavAuthenticationError>().having(
          (e) => e.statusCode,
          'status',
          HttpStatus.found,
        ),
      ),
    );
    expect(visits.single.auth, isNull);
  });

  test('timeout aborts discovery and fails subsequent requests', () async {
    final gate = Completer<void>();
    handler = (request, body) => gate.future;
    final auth = client(timeout: const Duration(milliseconds: 60));
    await expectLater(get(auth), throwsA(isA<WebDavAuthenticationError>()));
    expect(auth.closed, isTrue);
    gate.complete();
    await expectLater(get(auth), throwsStateError);
  });

  test('discovery preserves connection failures', () async {
    final unavailable = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final uri = root.replace(port: unavailable.port);
    await unavailable.close(force: true);
    final auth = client(scope: uri);
    await expectLater(get(auth, uri), throwsA(isA<SocketException>()));
    expect(visits, isEmpty);
  });

  for (final phase in ['discovery', 'business auto', 'business basic']) {
    for (final error in <Exception>[
      const SocketException('connection failed'),
      const HandshakeException('certificate rejected'),
      const HttpException('transport failed'),
      TimeoutException('transport deadline'),
    ]) {
      test('$phase preserves the original ${error.runtimeType}', () async {
        final transport = _FailingOpenClient();
        final auth = client(
          http: transport,
          mode: phase == 'business basic'
              ? WebDavAuthenticationMode.basic
              : WebDavAuthenticationMode.auto,
        );
        if (phase == 'business auto') {
          expect(await get(auth), HttpStatus.ok);
        }
        transport.failure = error;
        await expectLater(get(auth), throwsA(same(error)));
        expect(auth.closed, isFalse);
      });
    }
  }

  for (final access in ['Basic auto', 'Basic forced', 'anonymous']) {
    test('$access preserves the injected HTTP connection factory', () async {
      if (access == 'anonymous') {
        handler = (request, body) async {
          request.response.statusCode = HttpStatus.ok;
        };
      }
      var connections = 0;
      final http = HttpClient()
        ..connectionFactory = (uri, host, port) {
          connections++;
          return Socket.startConnect(uri.host, uri.port);
        };
      final auth = client(
        http: http,
        mode: access == 'Basic forced'
            ? WebDavAuthenticationMode.basic
            : WebDavAuthenticationMode.auto,
      );
      expect(await get(auth), HttpStatus.ok);
      final afterFirst = connections;
      expect(afterFirst, greaterThan(0));
      expect(await get(auth), HttpStatus.ok);
      expect(connections, afterFirst);
    });
  }

  test(
    'parent discovery timeout reports its actual URI and last status',
    () async {
      final gate = Completer<void>();
      handler = (request, body) async {
        if (request.uri.path == '/dav/missing/') {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          await gate.future;
        }
      };
      final scope = root.resolve('dav/');
      final auth = client(
        scope: scope,
        probeUri: scope.resolve('missing/'),
        timeout: const Duration(milliseconds: 200),
      );
      try {
        await expectLater(
          get(auth, scope),
          throwsA(
            isA<WebDavAuthenticationError>()
                .having((e) => e.uri, 'uri', scope)
                .having((e) => e.statusCode, 'status', HttpStatus.notFound),
          ),
        );
      } finally {
        gate.complete();
      }
      expect(auth.closed, isTrue);
    },
  );

  test('close aborts an in-flight discovery', () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    handler = (request, body) {
      started.complete();
      return gate.future;
    };
    final auth = client();
    final pending = expectLater(get(auth), throwsA(anything));
    await started.future;
    auth.close(force: true);
    gate.complete();
    await pending;
    await expectLater(get(auth), throwsStateError);
  });

  test('managed and SDK credentials are mutually exclusive', () {
    final auth = client();
    expect(() => auth.setAuthenticate(null), throwsStateError);
    expect(
      () => auth.addCredentials(root, '', HttpClientBasicCredentials('a', 'b')),
      throwsStateError,
    );
    expect(auth.toString(), isNot(contains('password')));
  });

  test(
    'close interrupts a discovery response with an unfinished body',
    () async {
      final headersSent = Completer<void>();
      final gate = Completer<void>();
      handler = (request, body) async {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.set(HttpHeaders.wwwAuthenticateHeader, _mixed);
        request.response.write('unfinished');
        await request.response.flush();
        headersSent.complete();
        await gate.future;
      };
      final auth = client();
      final pending = expectLater(get(auth), throwsA(anything));
      await headersSent.future;
      auth.close();
      try {
        await pending.timeout(const Duration(milliseconds: 500));
      } finally {
        gate.complete();
      }
    },
  );

  test('authentication errors redact URI user information', () {
    final error = WebDavAuthenticationError(
      'Out of scope',
      uri: Uri.parse('https://user:secret@example.test/dav/'),
    );
    expect(error.uri.userInfo, isEmpty);
    expect(error.toString(), isNot(contains('secret')));
  });

  for (final qop in [null, 'auth']) {
    for (final route in [
      'direct',
      'proxy',
      'proxy fallback',
      'direct fallback',
      'switch at same endpoint',
    ]) {
      test(
        'Digest $route signs the wire target and keeps PUT data (qop: $qop)',
        () async {
          final files = <String, String>{};
          requireDigest(qop: qop, files: files);
          final unavailable = await HttpServer.bind(
            InternetAddress.loopbackIPv4,
            0,
          );
          final unavailablePort = unavailable.port;
          await unavailable.close(force: true);
          final proxied = route == 'proxy' || route == 'proxy fallback';
          final scope = proxied
              ? Uri.parse('http://origin.example.test/dav/')
              : root.resolve('dav/');
          final proxy = 'PROXY 127.0.0.1:${server.bindPort}';
          final http = HttpClient()
            ..findProxy = (uri) => switch (route) {
              'direct' => 'DIRECT',
              'proxy' => proxy,
              'proxy fallback' => 'PROXY 127.0.0.1:$unavailablePort; $proxy',
              'direct fallback' => 'PROXY 127.0.0.1:$unavailablePort; DIRECT',
              _ => uri.queryParameters['via'] == 'proxy' ? proxy : 'DIRECT',
            };
          final observedRoutes = <bool>[];
          final auth = client(
            http: http,
            scope: scope,
            probeUri: scope.resolve('probe/'),
            connectionFactory: (uri, host, port) {
              observedRoutes.add(host != null);
              return Socket.startConnect(host ?? uri.host, port ?? uri.port);
            },
          );
          final file = scope.resolve(
            'file%20%E4%B9%A0%E6%83%AF.json?via=proxy&name=a%20b#fragment',
          );
          const data = '{"habit":"习惯","value":42}';
          final request = await auth.dispatch(file).create(data: data);
          request.request.headers.contentType = ContentType.json;
          request.request.contentLength = utf8.encode(data).length;
          final upload = await request.close();
          expect(upload.response.statusCode, HttpStatus.created);
          await upload.response.drain<void>();
          for (final uri in [
            file,
            file.replace(query: ''),
            file.resolve(file.path),
          ]) {
            final download = await (await auth.dispatch(uri).get()).close();
            expect(download.response.statusCode, HttpStatus.ok);
            expect(await utf8.decoder.bind(download.response).join(), data);
          }
          expect(
            visits.where((v) => v.method == WebDavMethod.put.name),
            hasLength(1),
          );
          expect(observedRoutes, isNotEmpty);
          if (route == 'switch at same endpoint') {
            expect(observedRoutes, containsAll([false, true]));
          }
          await expectRedirectResponse(auth, scope);
        },
      );
    }
  }

  for (final proxied in [false, true]) {
    test('Digest signs an empty path with query (proxy: $proxied)', () async {
      requireDigest();
      final scope = proxied ? Uri.parse('http://origin.example.test/') : root;
      final http = HttpClient()
        ..findProxy = (_) =>
            proxied ? 'PROXY 127.0.0.1:${server.bindPort}' : 'DIRECT';
      final auth = client(http: http, scope: scope);
      final uri = scope.replace(
        path: '',
        query: 'version=1',
        fragment: 'client-only',
      );
      expect(await get(auth, uri), HttpStatus.ok);
    });
  }

  for (final mode in WebDavAuthenticationMode.values) {
    test('$mode keeps the SDK default for explicit HTTP port zero', () async {
      int? observedPort;
      final uri = Uri.parse('http://127.0.0.1:0/');
      final http = HttpClient()..findProxy = (_) => 'DIRECT';
      final auth = client(http: http, scope: uri, mode: mode);
      await IOOverrides.runZoned(
        () async {
          await expectLater(get(auth, uri), throwsA(isA<IOException>()));
        },
        socketStartConnect:
            (host, port, {sourceAddress, sourcePort = 0}) async {
              observedPort = port;
              throw const SocketException(
                'Stop before opening a test connection',
              );
            },
      );
      expect(observedPort, HttpClient.defaultHttpPort);
      expect(visits, isEmpty);
    });
  }

  test('unknown routing aborts the unsent Digest probe connection', () async {
    requireDigest();
    final transport = _UnknownRouteClient();
    final auth = client(http: transport);
    await expectLater(
      get(auth),
      throwsA(
        isA<WebDavAuthenticationError>().having(
          (e) => e.message,
          'message',
          'Cannot determine the Digest request target',
        ),
      ),
    );
    expect(() => transport.lastSocket!.port, throwsA(isA<SocketException>()));
    expect(visits, hasLength(1));
  });

  for (final scheme in ['Digest', 'Basic auto', 'Basic forced']) {
    for (final route in [
      'direct TLS',
      'CONNECT tunnel',
      'authenticated CONNECT tunnel',
      'custom TLS factory',
      'untrusted TLS',
      'CONNECT tunnel wrong host',
    ]) {
      test(
        '$scheme $route keeps credentials scoped and preserves TLS configuration',
        () async {
          final files = <String, String>{};
          requireDigest(files: files);
          if (scheme != 'Digest') {
            handler = (request, body) async {
              if (request.headers.value(HttpHeaders.authorizationHeader) !=
                  _authorization) {
                request.response.statusCode = HttpStatus.unauthorized;
                request.response.headers.set(
                  HttpHeaders.wwwAuthenticateHeader,
                  _mixed,
                );
              } else if (request.method == WebDavMethod.put.name) {
                files[request.uri.path] = body;
                request.response.statusCode = HttpStatus.created;
              } else {
                request.response.statusCode = HttpStatus.ok;
                request.response.write(files[request.uri.path] ?? '');
              }
            };
          }
          final originProxyHeaders = <String?>[];
          final respondToOrigin = handler!;
          handler = (request, body) {
            originProxyHeaders.add(
              request.headers.value(HttpHeaders.proxyAuthorizationHeader),
            );
            return respondToOrigin(request, body);
          };
          final respond = server.expectedResponse;
          await server.close();
          server = TestUsagedHttpServer()..expectedResponse = respond;
          const certificate = 'test/intergration_test/fixtures/test-cert.pem';
          final serverContext = SecurityContext()
            ..useCertificateChain(certificate)
            ..usePrivateKey('test/intergration_test/fixtures/test-key.pem');
          await server.open(securityContext: serverContext);
          root = Uri.parse('https://localhost:${server.bindPort}/');
          if (route == 'CONNECT tunnel wrong host') {
            root = root.replace(host: 'wrong.invalid');
          }
          final trust = SecurityContext()
            ..setTrustedCertificates(
              'test/intergration_test/fixtures/test-ca.pem',
            );
          final http = HttpClient(
            context: route == 'untrusted TLS' ? SecurityContext() : trust,
          );
          final pinned = File(certificate).readAsStringSync().trim();
          bool isTestCertificate(X509Certificate certificate) =>
              certificate.pem.trim() == pinned;
          // Native stores can limit leaf lifetimes even for private test CAs.
          if (route != 'untrusted TLS') {
            http.badCertificateCallback = (certificate, host, port) =>
                host == 'localhost' &&
                port == server.bindPort &&
                isTestCertificate(certificate);
          }
          var tunnels = 0;
          var customConnections = 0;
          if (route.contains('CONNECT tunnel')) {
            final proxy = await HttpServer.bind(
              InternetAddress.loopbackIPv4,
              0,
            );
            final sockets = <Socket>[];
            addTearDown(() async {
              for (final socket in sockets) {
                socket.destroy();
              }
              await proxy.close(force: true);
            });
            Future<void> pipe(Socket source, Socket destination) async {
              try {
                await destination.addStream(source);
                await destination.close();
              } on IOException {
                destination.destroy();
              }
            }

            proxy.listen((request) async {
              expect(request.method, 'CONNECT');
              expect(request.uri.toString(), root.authority);
              tunnels++;
              expect(
                request.headers.value(HttpHeaders.authorizationHeader),
                isNull,
              );
              if (route == 'authenticated CONNECT tunnel') {
                expect(
                  request.headers.value(HttpHeaders.proxyAuthorizationHeader),
                  'Basic ${base64Encode(utf8.encode('proxy-user:proxy-password'))}',
                );
              }
              final upstream = await Socket.connect(
                '127.0.0.1',
                server.bindPort,
              );
              request.response.statusCode = HttpStatus.ok;
              request.response.contentLength = 0;
              final downstream = await request.response.detachSocket();
              sockets.addAll([upstream, downstream]);
              unawaited(pipe(upstream, downstream));
              unawaited(pipe(downstream, upstream));
            });
            http.findProxy = (_) => route == 'authenticated CONNECT tunnel'
                ? 'PROXY proxy-user:proxy-password@127.0.0.1:${proxy.port}'
                : 'PROXY 127.0.0.1:${proxy.port}';
          } else if (route == 'custom TLS factory') {
            http.connectionFactory = (uri, host, port) {
              customConnections++;
              expect(host, isNull);
              return SecureSocket.startConnect(
                uri.host,
                uri.port,
                context: trust,
                onBadCertificate: isTestCertificate,
              );
            };
          }
          final auth = client(
            http: http,
            scope: root,
            mode: scheme == 'Basic forced'
                ? WebDavAuthenticationMode.basic
                : WebDavAuthenticationMode.auto,
          );
          final file = root.resolve('habit%20name.json?version=1#fragment');
          if (route == 'untrusted TLS' ||
              route == 'CONNECT tunnel wrong host') {
            await expectLater(
              auth.dispatch(file).create(data: 'payload'),
              throwsA(isA<HandshakeException>()),
            );
            expect(originProxyHeaders, isEmpty);
            return;
          }
          final upload =
              await (await auth.dispatch(file).create(data: 'payload')).close();
          expect(upload.response.statusCode, HttpStatus.created);
          await upload.response.drain<void>();
          final download = await (await auth.dispatch(file).get()).close();
          expect(download.response.statusCode, HttpStatus.ok);
          expect(await utf8.decoder.bind(download.response).join(), 'payload');
          expect(originProxyHeaders, everyElement(isNull));
          await expectRedirectResponse(auth, root);
          if (route.contains('CONNECT tunnel')) expect(tunnels, greaterThan(0));
          if (route == 'custom TLS factory') expect(customConnections, 1);
        },
      );
    }
  }

  test(
    'Digest route tracking preserves custom connection cancellation',
    () async {
      requireDigest();
      final pending = Completer<Socket>();
      var cancellations = 0;
      var connections = 0;
      final auth = client(
        timeout: const Duration(milliseconds: 100),
        connectionFactory: (uri, host, port) async {
          if (connections++ == 0) {
            return Socket.startConnect(uri.host, uri.port);
          }
          return ConnectionTask.fromSocket(pending.future, () {
            cancellations++;
            if (!pending.isCompleted) {
              pending.completeError(const SocketException('cancelled'));
            }
          });
        },
      );
      await expectLater(get(auth), throwsA(isA<WebDavAuthenticationError>()));
      expect(cancellations, 1);
      expect(auth.closed, isTrue);
      expect(visits, hasLength(1));
    },
  );

  for (final qop in [null, 'auth']) {
    for (final password in ['password', 'wrong']) {
      test('pure Digest verifies before PUT ($password, qop: $qop)', () async {
        requireDigest(qop: qop);
        final auth = client(
          password: password,
          timeout: const Duration(milliseconds: 300),
        );
        Future<int> operation() async {
          final response =
              await (await auth
                      .dispatch(root.resolve('file'))
                      .create(data: 'payload'))
                  .close();
          await response.response.drain<void>();
          return response.response.statusCode;
        }

        if (password == 'password') {
          expect(await operation(), HttpStatus.created);
          final put = visits
              .where((v) => v.method == WebDavMethod.put.name)
              .single;
          expect(put.body, 'payload');
          expect(put.auth, startsWith('Digest '));
        } else {
          await expectLater(
            operation(),
            throwsA(
              isA<WebDavAuthenticationError>().having(
                (e) => e.statusCode,
                'status',
                HttpStatus.unauthorized,
              ),
            ),
          );
          expect(
            visits.where((v) => v.method == WebDavMethod.put.name),
            isEmpty,
          );
          expect(visits, hasLength(2));
          expect(auth.closed, isFalse);
          await expectLater(
            operation(),
            throwsA(isA<WebDavAuthenticationError>()),
          );
          expect(visits, hasLength(2));
        }
      });
    }
  }

  for (final challenge in [
    'Digest realm="WebDAV", nonce="new", qop="auth", stale=true',
    'Digest realm="WebDAV", nonce="initial", qop="auth"',
    'Digest realm="WebDAV", nonce="new", Bearer realm="oauth"',
  ]) {
    test(
      'Digest business 401 is returned without replay: $challenge',
      () async {
        var puts = 0;
        handler = (request, body) async {
          final hasAuth =
              request.headers.value(HttpHeaders.authorizationHeader) != null;
          switch (request.method) {
            case 'PROPFIND' when hasAuth:
              request.response.statusCode = HttpStatus.multiStatus;
            case 'PUT':
              puts++;
              request.response.statusCode = puts == 1
                  ? HttpStatus.unauthorized
                  : HttpStatus.conflict;
              request.response.headers.set(
                HttpHeaders.wwwAuthenticateHeader,
                challenge,
              );
            default:
              request.response.statusCode = HttpStatus.unauthorized;
              request.response.headers.set(
                HttpHeaders.wwwAuthenticateHeader,
                'Digest realm="WebDAV", nonce="initial", qop="auth"',
              );
          }
        };
        final auth = client();
        final request = await auth
            .dispatch(root.resolve('file'))
            .create(data: 'important payload');
        final response = await request.close().timeout(
          const Duration(seconds: 1),
        );
        await response.response.drain<void>();
        expect(response.response.statusCode, HttpStatus.unauthorized);
        expect(puts, 1);
        expect(
          visits.where((v) => v.method == 'PUT').single.body,
          'important payload',
        );
        expect(visits.where((v) => v.method == 'PROPFIND'), hasLength(2));
      },
    );
  }

  test(
    'Digest signs query targets and preserves opaque with unique counts',
    () async {
      final counts = <String>[];
      final nonces = <String>[];
      const realm = 'WebDAV, "realm"';
      const opaque = 'opaque\\value';
      handler = (request, body) async {
        final header = request.headers.value(HttpHeaders.authorizationHeader);
        if (header == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.headers.set(
            HttpHeaders.wwwAuthenticateHeader,
            r'Digest realm="WebDAV, \"realm\"", nonce="fixed", qop="auth", opaque="opaque\\value"',
          );
          return;
        }
        final fields = AuthenticationChallenge.parse(header).parameters;
        expect(fields['realm'], realm);
        expect(fields['opaque'], opaque);
        expect(fields['uri'], request.uri.toString());
        expect(fields['nc'], matches(RegExp(r'^[0-9a-f]{8}$')));
        counts.add(fields['nc']!);
        nonces.add(fields['cnonce']!);
        String hash(String value) => md5.convert(utf8.encode(value)).toString();
        final ha1 = hash('user:$realm:password');
        final ha2 = hash('${request.method}:${request.uri}');
        expect(
          fields['response'],
          hash('$ha1:fixed:${fields['nc']}:${fields['cnonce']}:auth:$ha2'),
        );
        request.response.statusCode = HttpStatus.ok;
      };
      final auth = client();
      expect(
        await get(auth, root.resolve('file?version=1&name=a%20b')),
        HttpStatus.ok,
      );
      expect(
        await Future.wait(
          List.generate(4, (i) => get(auth, root.resolve('file?version=$i'))),
        ),
        everyElement(HttpStatus.ok),
      );
      expect(counts.toSet(), hasLength(6));
      expect(
        counts,
        containsAll([
          '00000001',
          '00000002',
          '00000003',
          '00000004',
          '00000005',
          '00000006',
        ]),
      );
      expect(nonces.toSet(), hasLength(6));
    },
  );
}

class _UnknownRouteClient extends Fake implements HttpClient {
  final HttpClient _client = HttpClient();
  Socket? lastSocket;

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(Uri, String?, int?)? factory,
  ) => _client.connectionFactory = (uri, host, port) async {
    final task = await factory!(uri, host, port);
    return ConnectionTask.fromSocket(
      task.socket.then((socket) {
        lastSocket = socket;
        return socket;
      }),
      task.cancel,
    );
  };

  @override
  Future<HttpClientRequest> openUrl(String method, Uri uri) async =>
      _UnknownRouteRequest(await _client.openUrl(method, uri));

  @override
  void close({bool force = false}) => _client.close(force: force);
}

class _UnknownRouteRequest extends Fake implements HttpClientRequest {
  final HttpClientRequest _request;

  _UnknownRouteRequest(this._request);

  @override
  Uri get uri => _request.uri;
  @override
  HttpHeaders get headers => _request.headers;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  set followRedirects(bool value) => _request.followRedirects = value;
  @override
  set persistentConnection(bool value) => _request.persistentConnection = value;
  @override
  void write(Object? value) => _request.write(value);
  @override
  Future<HttpClientResponse> close() => _request.close();
  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _request.abort(exception, stackTrace);
}

class _FailingOpenClient extends Fake implements HttpClient {
  final HttpClient _client = HttpClient();
  Exception? failure;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri uri) {
    final error = failure;
    return error == null ? _client.openUrl(method, uri) : Future.error(error);
  }

  @override
  void close({bool force = false}) => _client.close(force: force);
}
