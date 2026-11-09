// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http_parser/http_parser.dart' show AuthenticationChallenge;
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
  }) {
    final result = WebDavStdClient.authenticated(
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

  test('discovery transport errors include the failed URI', () async {
    final unavailable = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final uri = root.replace(port: unavailable.port);
    await unavailable.close(force: true);
    final auth = client(scope: uri);
    await expectLater(
      get(auth, uri),
      throwsA(
        isA<WebDavAuthenticationError>()
            .having((e) => e.uri, 'uri', uri)
            .having((e) => e.statusCode, 'status', isNull),
      ),
    );
    expect(visits, isEmpty);
  });

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
    for (final password in ['password', 'wrong']) {
      test('pure Digest verifies before PUT ($password, qop: $qop)', () async {
        final challenge =
            'Digest realm="WebDAV", nonce="fixed-nonce", algorithm=MD5${qop == null ? '' : ', qop="$qop"'}';
        handler = (request, body) async {
          final header =
              request.headers.value(HttpHeaders.authorizationHeader) ?? '';
          final fields = header.isEmpty
              ? <String, String>{}
              : AuthenticationChallenge.parse(header).parameters;
          String hash(String s) => md5.convert(utf8.encode(s)).toString();
          final ha1 = hash('user:WebDAV:password');
          final ha2 = hash('${request.method}:${request.uri}');
          final expected = qop == null
              ? hash('$ha1:fixed-nonce:$ha2')
              : hash(
                  '$ha1:fixed-nonce:${fields['nc']}:${fields['cnonce']}:auth:$ha2',
                );
          if (fields['response'] != expected) {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.headers.set(
              HttpHeaders.wwwAuthenticateHeader,
              challenge,
            );
          } else {
            request.response.statusCode =
                request.method == WebDavMethod.put.name
                ? HttpStatus.created
                : HttpStatus.multiStatus;
          }
        };
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
