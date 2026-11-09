// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

part of 'authentication.dart';

final class _AutomaticAuthenticationSession
    extends _WebDavAuthenticationSession {
  final _AuthenticationDiscovery _discovery;

  _AutomaticAuthenticationSession(super.configuration, HttpClient client)
    : _discovery = _AuthenticationDiscovery(configuration, client);

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
  HttpClientRequest? _pending;
  bool closed = false;
  bool running = false;
  int? _lastStatus;
  Uri? _lastProbeUri;

  _AuthenticationDiscovery(this._configuration, this._client);

  void close() {
    closed = true;
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
      return await _discover().timeout(_configuration.discoveryTimeout);
    } on TimeoutException {
      close();
      _client.close(force: true);
      throw WebDavAuthenticationError(
        'Authentication discovery timed out',
        uri: _lastProbeUri ?? _configuration.probeUri,
        statusCode: _lastStatus,
      );
    } on IOException catch (error) {
      if (error is WebDavAuthenticationError) rethrow;
      throw WebDavAuthenticationError(
        'Authentication discovery request failed',
        uri: _lastProbeUri ?? _configuration.probeUri,
        statusCode: _lastStatus,
      );
    } finally {
      running = false;
    }
  }

  Future<_RequestAuthentication> _discover() async {
    // Each 404 moves strictly toward the scope root; null is the exit.
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
    switch (challenges) {
      case final values
          when values.any(
            (c) => c.scheme == 'basic' && c.parameters['realm'] != null,
          ):
        return _BasicAuthentication(
          _configuration,
          uri: response.uri,
          statusCode: response.status,
        );
      case [final challenge]
          when response.challenges!.length == 1 &&
              _DigestAuthentication.supports(challenge):
        return _verifyDigest(
          response.uri,
          _DigestAuthentication(_configuration, challenge),
        );
      default:
        throw response.failure('Unsupported authentication challenge');
    }
  }

  Future<_RequestAuthentication> _verifyDigest(
    Uri uri,
    _DigestAuthentication authentication,
  ) async {
    // Exactly one authenticated, read-only probe. A 401 ends discovery.
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
      request.followRedirects = false;
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

// SDK Digest signing is coupled to automatic transport retries. Generate only
// the header here, using crypto for MD5 and RFC 7616 section 3.4 for the proof.
final class _DigestAuthentication extends _RequestAuthentication {
  final String _username;
  final String _realm;
  final String _nonce;
  final String? _opaque;
  final String _ha1;
  final _DigestQop _qop;
  final Random _random = Random.secure();
  int _nonceCount = 0;

  _DigestAuthentication(
    WebDavAuthenticationConfig configuration,
    AuthenticationChallenge challenge,
  ) : _username = configuration.username,
      _realm = challenge.parameters['realm']!,
      _nonce = challenge.parameters['nonce']!,
      _opaque = challenge.parameters['opaque'],
      _ha1 = _hash(
        '${configuration.username}:${challenge.parameters['realm']}:${configuration.password}',
      ),
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
        p['userhash'] != 'true';
  }

  static String _hash(String value) =>
      md5.convert(utf8.encode(value)).toString();

  @override
  void apply(HttpClientRequest request) {
    final path = request.uri.path.isEmpty ? '/' : request.uri.path;
    final target = request.uri.hasQuery ? '$path?${request.uri.query}' : path;
    final ha2 = _hash('${request.method}:$target');
    final fields = <String, String>{
      'username': _username,
      'realm': _realm,
      'nonce': _nonce,
      'uri': target,
      'algorithm': 'MD5',
      'opaque': ?_opaque,
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
            'algorithm' || 'qop' || 'nc' => entry.value,
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
