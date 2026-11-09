// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

part of 'authentication.dart';

final class _AutomaticAuthenticationSession
    extends _WebDavAuthenticationSession {
  final _AuthenticationDiscovery _discovery;

  _AutomaticAuthenticationSession(
    super.configuration,
    HttpClient client, {
    Future<ConnectionTask<Socket>> Function(
      Uri uri,
      String? proxyHost,
      int? proxyPort,
    )?
    connectionFactory,
  }) : _discovery = _AuthenticationDiscovery(
         configuration,
         client,
         configuration.scope.scheme == 'http'
             ? _HttpRequestTargets(connectionFactory)
             : null,
       );

  @override
  bool get closed => super.closed || _discovery.closed;

  @override
  bool get discovering => _discovery.running;

  @override
  void close() {
    _discovery.close();
    super.close();
  }

  @override
  Future<_RequestAuthentication> _initialize() => _discovery.run();
}

final class _AuthenticationDiscovery {
  final WebDavAuthenticationConfig _configuration;
  final HttpClient _client;
  final _HttpRequestTargets? _requestTargets;
  HttpClientRequest? _pending;
  bool closed = false;
  bool running = false;
  int? _lastStatus;
  Uri? _lastProbeUri;

  _AuthenticationDiscovery(
    this._configuration,
    this._client,
    this._requestTargets,
  );

  void close() {
    closed = true;
    _requestTargets?.close();
    _pending?.abort();
  }

  void _checkOpen() {
    if (closed) {
      throw StateError('Authentication discovery is closed.');
    }
  }

  Future<_RequestAuthentication> run() async {
    running = true;
    try {
      return await _discover().timeout(
        _configuration.discoveryTimeout,
        onTimeout: () {
          close();
          _client.close(force: true);
          throw WebDavAuthenticationError(
            'Authentication discovery timed out',
            uri: _lastProbeUri ?? _configuration.probeUri,
            statusCode: _lastStatus,
          );
        },
      );
    } finally {
      running = false;
    }
  }

  Future<_RequestAuthentication> _discover() async {
    for (
      Uri? uri = _configuration.probeUri;
      uri != null;
      uri = _parentWithinScope(uri)
    ) {
      final response = await _probe(uri);
      switch (response.status) {
        case >= HttpStatus.ok && < HttpStatus.multipleChoices:
          return const _AnonymousAuthentication();
        case HttpStatus.notFound when response.challenges == null:
          continue;
        case HttpStatus.unauthorized:
          return _authenticate(response);
        default:
          throw response.failure('Authentication discovery failed');
      }
    }
    throw WebDavAuthenticationError(
      'Authentication discovery failed',
      uri: _lastProbeUri ?? _configuration.probeUri,
      statusCode: _lastStatus,
    );
  }

  Uri? _parentWithinScope(Uri uri) {
    final parent = uri.resolve(uri.path.endsWith('/') ? '../' : './');
    return parent.path != uri.path && _configuration._containsUri(parent)
        ? parent
        : null;
  }

  Future<_RequestAuthentication> _authenticate(
    _DiscoveryResponse response,
  ) async {
    final challenges = response.parseChallenges();
    for (final challenge in challenges) {
      if (challenge.scheme == 'basic' &&
          challenge.parameters['realm'] != null) {
        return _BasicAuthentication(
          _configuration,
          challenge: challenge,
          uri: response.uri,
          statusCode: response.status,
        );
      }
    }
    switch (challenges) {
      case [final challenge]
          when response.challenges!.length == 1 &&
              _DigestAuthentication.supports(challenge):
        _requestTargets?.enable(_client);
        return _verifyDigest(
          response.uri,
          _DigestAuthentication(_configuration, challenge, _requestTargets),
        );
      default:
        throw response.failure('Unsupported authentication challenge');
    }
  }

  Future<_RequestAuthentication> _verifyDigest(
    Uri uri,
    _DigestAuthentication authentication,
  ) async {
    final response = await _probe(uri, authentication);
    return switch (response.status) {
      HttpStatus.notFound ||
      >= HttpStatus.ok && < HttpStatus.multipleChoices => authentication,
      _ => throw response.failure('Digest authentication failed'),
    };
  }

  Future<_DiscoveryResponse> _probe(
    Uri uri, [
    _RequestAuthentication authentication = const _AnonymousAuthentication(),
  ]) async {
    _checkOpen();
    _lastProbeUri = uri;
    final request = await _client.openUrl(WebDavMethod.propfind.name, uri);
    if (closed) {
      request.abort();
      _checkOpen();
    }
    _pending = request;
    try {
      _configureTransportRequest(request);
      // Digest requires a new, observed connection after discovery.
      if (_requestTargets != null) request.persistentConnection = false;
      authentication.apply(request);
      const param = PropfindPropRequestParam(
        depth: Depth.resource,
        props: [PropfindRequestProp.dav(WebDavElementNames.resourcetype)],
      );
      param.beforeAddRequestBody(request);
      request.write(param.toRequestBody());
      final response = await request.close();
      _lastStatus = response.statusCode;
      final result = _DiscoveryResponse(
        uri,
        response.statusCode,
        response.headers[HttpHeaders.wwwAuthenticateHeader],
      );
      await response.drain<void>();
      _checkOpen();
      return result;
    } catch (_) {
      request.abort();
      rethrow;
    } finally {
      _pending = null;
    }
  }
}

final class _DiscoveryResponse {
  final Uri uri;
  final int status;
  final List<String>? challenges;

  const _DiscoveryResponse(this.uri, this.status, this.challenges);

  WebDavAuthenticationError failure(String message) =>
      WebDavAuthenticationError(message, uri: uri, statusCode: status);

  List<AuthenticationChallenge> parseChallenges() {
    try {
      return challenges?.expand(AuthenticationChallenge.parseHeader).toList() ??
          [];
    } on FormatException {
      throw failure('Unsupported authentication challenge format');
    }
  }
}

final class _AnonymousAuthentication extends _RequestAuthentication {
  const _AnonymousAuthentication();

  @override
  void apply(HttpClientRequest request) {}
}

// HTTP proxies use absolute-form targets; HTTPS uses origin-form inside TLS.
final class _HttpRequestTargets {
  final Future<ConnectionTask<Socket>> Function(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  )?
  _connectionFactory;
  final _routes = <(int, String, int), bool>{};
  bool _closed = false;

  _HttpRequestTargets(this._connectionFactory);

  void enable(HttpClient client) => client.connectionFactory = _connect;

  void close() {
    _closed = true;
    _routes.clear();
  }

  Future<ConnectionTask<Socket>> _connect(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) async {
    final task =
        await (_connectionFactory?.call(uri, proxyHost, proxyPort) ??
            Socket.startConnect(
              proxyHost ?? uri.host,
              proxyPort ??
                  (uri.port == 0 ? HttpClient.defaultHttpPort : uri.port),
            ));
    return ConnectionTask.fromSocket(
      task.socket.then((socket) {
        if (_closed) {
          socket.destroy();
          throw StateError('Authentication discovery is closed.');
        }
        final key = (
          socket.port,
          socket.remoteAddress.address,
          socket.remotePort,
        );
        _routes[key] = proxyHost != null;
        return socket;
      }),
      task.cancel,
    );
  }

  String target(HttpClientRequest request) {
    final connection = request.connectionInfo;
    final route = connection == null
        ? null
        : _routes.remove((
            connection.localPort,
            connection.remoteAddress.address,
            connection.remotePort,
          ));
    if (route == null) {
      throw WebDavAuthenticationError(
        'Cannot determine the Digest request target',
        uri: request.uri,
      );
    }
    return route
        ? request.uri.removeFragment().toString()
        : _originRequestTarget(request.uri);
  }
}

String _originRequestTarget(Uri uri) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

// MD5 Digest header signing as defined in RFC 7616 section 3.4.
final class _DigestAuthentication extends _RequestAuthentication {
  final String _username;
  final String _realm;
  final String _nonce;
  final String? _opaque;
  final String _ha1;
  final String? _usernameHash;
  final _DigestQop _qop;
  final _HttpRequestTargets? _requestTargets;
  final Random _random = Random.secure();
  int _nonceCount = 0;

  factory _DigestAuthentication(
    WebDavAuthenticationConfig configuration,
    AuthenticationChallenge challenge,
    _HttpRequestTargets? requestTargets,
  ) {
    final credentials = _credentialsForChallenge(configuration, challenge);
    return _DigestAuthentication._(
      credentials.username,
      credentials.password,
      challenge,
      requestTargets,
    );
  }

  _DigestAuthentication._(
    this._username,
    String password,
    AuthenticationChallenge challenge,
    this._requestTargets,
  ) : _realm = challenge.parameters['realm']!,
      _nonce = challenge.parameters['nonce']!,
      _opaque = challenge.parameters['opaque'],
      _ha1 = _hash('$_username:${challenge.parameters['realm']}:$password'),
      _usernameHash = challenge.parameters['userhash'] == 'true'
          ? _hash('$_username:${challenge.parameters['realm']}')
          : null,
      _qop = switch (challenge.parameters['qop']) {
        'auth' => _DigestQop.auth,
        _ => _DigestQop.none,
      };

  static bool supports(AuthenticationChallenge challenge) {
    final p = challenge.parameters;
    return challenge.scheme == 'digest' &&
        p['realm'] != null &&
        p['nonce'] != null &&
        (p['algorithm'] ?? 'MD5').toLowerCase() == 'md5' &&
        (p['qop'] == null || p['qop'] == 'auth') &&
        (p['charset'] == null || p['charset']!.toLowerCase() == 'utf-8') &&
        (p['userhash'] == null ||
            const ['true', 'false'].contains(p['userhash']));
  }

  static String _hash(String value) =>
      md5.convert(utf8.encode(value)).toString();

  static String _encodeExtendedUsername(String username) {
    // RFC 5987 uses percent-encoded spaces instead of form encoding's '+'.
    final encoded = Uri.encodeQueryComponent(username).replaceAll('+', '%20');
    return "UTF-8''$encoded";
  }

  @override
  void apply(HttpClientRequest request) {
    final target =
        _requestTargets?.target(request) ?? _originRequestTarget(request.uri);
    // PAC can select DIRECT or PROXY for the same endpoint on the next request.
    if (_requestTargets != null) request.persistentConnection = false;
    final ha2 = _hash('${request.method}:$target');
    final fields = <String, String>{
      if (_usernameHash != null)
        'username': _usernameHash
      else if (_username.codeUnits.any((unit) => unit > 0x7f))
        'username*': _encodeExtendedUsername(_username)
      else
        'username': _username,
      'realm': _realm,
      'nonce': _nonce,
      'uri': target,
      'algorithm': 'MD5',
      'opaque': ?_opaque,
      if (_usernameHash != null) 'userhash': 'true',
    };
    switch (_qop) {
      case _DigestQop.none:
        fields['response'] = _hash('$_ha1:$_nonce:$ha2');
      case _DigestQop.auth:
        _addAuthProof(fields, ha2);
    }
    final parameters = fields.entries
        .map((entry) {
          final value = switch (entry.key) {
            'username*' ||
            'userhash' ||
            'algorithm' ||
            'qop' ||
            'nc' => entry.value,
            _ =>
              '"${entry.value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"',
          };
          return '${entry.key}=$value';
        })
        .join(', ');
    request.headers.set(HttpHeaders.authorizationHeader, 'Digest $parameters');
  }

  void _addAuthProof(Map<String, String> fields, String ha2) {
    final cnonce = base64UrlEncode(
      List.generate(16, (_) => _random.nextInt(256)),
    );
    final nc = (++_nonceCount).toRadixString(16).padLeft(8, '0');
    fields.addAll({
      'qop': 'auth',
      'cnonce': cnonce,
      'nc': nc,
      'response': _hash('$_ha1:$_nonce:$nc:$cnonce:auth:$ha2'),
    });
  }
}

enum _DigestQop {
  /// Legacy Digest without the qop directive.
  none,

  /// Signs the method and target with a client nonce and request count.
  auth,
}
