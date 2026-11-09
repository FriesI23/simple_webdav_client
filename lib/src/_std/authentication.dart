// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:http_parser/http_parser.dart' show AuthenticationChallenge;

import '../dav/element.dart';
import '../error.dart';
import '../io.dart';
import '../method.dart';
import 'depth.dart';
import 'propfind.dart';

/// Authentication selected by the package instead of a caller's SDK callback.
enum WebDavAuthenticationMode {
  /// Discovers Basic or supported pure Digest before business requests begin.
  auto,

  /// Sends Basic credentials immediately without probing the server.
  basic,
}

/// Credentials for one origin and an optional directory subtree.
///
/// [scope] must be an absolute HTTP(S) directory URI. [probeUri] defaults to
/// [scope]. Automatic mode discovers Basic (including mixed challenges) or
/// pure MD5 Digest with a read-only PROPFIND before opening business requests.
/// Basic is only allowed over HTTPS unless [allowInsecureBasic] is explicit.
/// This configuration must use a dedicated, previously unauthenticated client.
final class WebDavAuthenticationConfig {
  /// Absolute HTTP(S) directory URI limiting where credentials may be sent.
  final Uri scope;

  /// Initial read-only discovery URI within [scope], defaulting to [scope].
  final Uri probeUri;

  /// Login name used by the selected authentication scheme.
  final String username;

  /// Login secret, omitted from diagnostic string representations.
  final String password;

  /// Whether to discover authentication or send Basic preemptively.
  final WebDavAuthenticationMode mode;

  /// Explicitly permits Basic over HTTP instead of requiring HTTPS.
  final bool allowInsecureBasic;

  /// Deadline for the entire discovery operation, including SDK retries.
  final Duration discoveryTimeout;

  /// Validates and normalizes the credential scope and discovery settings.
  ///
  /// Throws [ArgumentError] for invalid settings and
  /// [WebDavAuthenticationError] when [probeUri] lies outside [scope].
  WebDavAuthenticationConfig({
    required Uri scope,
    Uri? probeUri,
    required this.username,
    required this.password,
    this.mode = WebDavAuthenticationMode.auto,
    this.allowInsecureBasic = false,
    this.discoveryTimeout = const Duration(seconds: 30),
  }) : scope = scope.normalizePath(),
       probeUri = (probeUri ?? scope).normalizePath() {
    if (!scope.isAbsolute ||
        !const ['http', 'https'].contains(scope.scheme) ||
        scope.host.isEmpty ||
        scope.userInfo.isNotEmpty ||
        scope.hasQuery ||
        scope.hasFragment ||
        !scope.path.endsWith('/') ||
        discoveryTimeout <= Duration.zero) {
      throw ArgumentError(
        'Authentication requires an HTTP(S) directory scope '
        'and a positive discovery timeout.',
      );
    }
    _checkUri(this.probeUri);
    if (username.contains(':')) {
      throw ArgumentError(
        'A Basic authentication username cannot contain ":".',
      );
    }
  }

  void _checkUri(Uri uri) {
    final normalized = uri.normalizePath();
    final segments = normalized.pathSegments;
    final unsafeSegment = segments.any(
      (s) => s == '.' || s == '..' || s.contains('/') || s.contains('\\'),
    );
    final root = scope.path.endsWith('/') ? scope.path : '${scope.path}/';
    if (uri.userInfo.isNotEmpty ||
        normalized.scheme != scope.scheme ||
        normalized.host != scope.host ||
        normalized.port != scope.port ||
        unsafeSegment ||
        !(normalized.path.startsWith(root) ||
            normalized.path == root.substring(0, root.length - 1))) {
      throw WebDavAuthenticationError(
        'Request is outside the credential scope',
        uri: uri,
      );
    }
  }

  @override
  String toString() =>
      'WebDavAuthenticationConfig(mode: ${mode.name}, scope: $scope)';
}

/// A bounded authentication/discovery failure. Credentials are never included.
final class WebDavAuthenticationError implements WebDavError, HttpException {
  /// Explanation of the failure without credential values.
  @override
  final String message;

  /// Failed request or discovery URI, with user information removed.
  @override
  final Uri uri;

  /// Last observed HTTP status, or null if no response was received.
  final int? statusCode;

  /// Records an authentication failure while redacting URI user information.
  WebDavAuthenticationError(this.message, {required Uri uri, this.statusCode})
    : uri = uri.replace(userInfo: '');

  @override
  String toString() =>
      'WebDavAuthenticationError: $message '
      '(status: $statusCode, uri: $uri)';
}

/// Coordinates authentication discovery and request setup for one transport.
///
/// This internal contract does not send or replay business requests. Its owner
/// remains responsible for closing the dedicated HTTP client.
abstract interface class WebDavAuthenticationSession {
  /// Creates the private implementation for [configuration] and [client].
  ///
  /// [client] must be dedicated to this session, without previously registered
  /// SDK site-authentication callbacks or credentials.
  factory WebDavAuthenticationSession(
    WebDavAuthenticationConfig configuration,
    HttpClient client,
  ) = _WebDavAuthenticationSession;

  /// Whether explicit closure or a discovery timeout has ended the session.
  bool get closed;

  /// Whether authentication initialization is currently in progress.
  bool get discovering;

  /// Ends the session and aborts outstanding discovery requests.
  ///
  /// The owner must also close the HTTP client, forcibly if [discovering].
  void close();

  /// Validates [uri] and completes authentication before opening its request.
  ///
  /// Concurrent calls share initialization and its cached success or failure.
  /// Throws [StateError] after closure and [WebDavAuthenticationError] for
  /// rejected scope or authentication discovery failures.
  Future<void> prepare(Uri uri);

  /// Applies the selected authentication and disables automatic redirects.
  ///
  /// Call after [prepare] completes, before writing or sending [request].
  /// Throws if the session is closed or the request is outside its scope.
  void configureRequest(HttpClientRequest request);
}

final class _WebDavAuthenticationSession
    implements WebDavAuthenticationSession {
  final WebDavAuthenticationConfig _configuration;
  final HttpClient _client;
  final _pending = <HttpClientRequest>{};
  Future<void>? _initializing;
  bool _basic = false;
  bool _closed = false;
  int? _lastStatus;
  Uri? _lastProbeUri;
  bool _discovering = false;

  _WebDavAuthenticationSession(this._configuration, this._client);

  @override
  bool get closed => _closed;

  @override
  bool get discovering => _discovering;

  @override
  void close() {
    _closed = true;
    for (final request in _pending.toList()) {
      request.abort();
    }
    _pending.clear();
  }

  void _checkOpen() {
    if (_closed) {
      throw StateError('The authenticated WebDAV client is closed.');
    }
  }

  @override
  Future<void> prepare(Uri uri) async {
    _checkOpen();
    _configuration._checkUri(uri);
    await (_initializing ??= _initialize());
    _checkOpen();
  }

  @override
  void configureRequest(HttpClientRequest request) {
    _checkOpen();
    _configuration._checkUri(request.uri);
    request.followRedirects = false;
    if (_basic) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Basic ${base64Encode(utf8.encode('${_configuration.username}:${_configuration.password}'))}',
      );
    }
  }

  Future<void> _initialize() async {
    _discovering = true;
    try {
      await _negotiate().timeout(_configuration.discoveryTimeout);
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
      _discovering = false;
    }
  }

  void _selectBasic(Uri uri, {int? statusCode}) {
    if (uri.scheme != 'https' && !_configuration.allowInsecureBasic) {
      throw WebDavAuthenticationError(
        'Basic authentication requires HTTPS',
        uri: uri,
        statusCode: statusCode,
      );
    }
    _basic = true;
  }

  Future<void> _negotiate() async {
    if (_configuration.mode == WebDavAuthenticationMode.basic) {
      _selectBasic(_configuration.probeUri);
      return;
    }
    var uri = _configuration.probeUri;
    while (true) {
      _checkOpen();
      final response = await _probe(uri);
      final status = response.statusCode;
      final headers = response.headers[HttpHeaders.wwwAuthenticateHeader];
      await response.drain<void>();
      _checkOpen();
      if (status >= HttpStatus.ok && status < HttpStatus.multipleChoices) {
        return;
      }
      if (status == HttpStatus.notFound && headers == null) {
        final parent = uri.resolve(uri.path.endsWith('/') ? '../' : './');
        if (parent.path != uri.path) {
          try {
            _configuration._checkUri(parent);
            uri = parent;
            continue;
          } on WebDavAuthenticationError {
            // Reached the configured scope. Never probe its parent.
          }
        }
      }
      if (status != HttpStatus.unauthorized || headers == null) {
        throw WebDavAuthenticationError(
          'Authentication discovery failed',
          uri: uri,
          statusCode: status,
        );
      }
      final List<AuthenticationChallenge> challenges;
      try {
        challenges = headers
            .expand(AuthenticationChallenge.parseHeader)
            .toList();
      } on FormatException {
        throw WebDavAuthenticationError(
          'Unsupported authentication challenge format',
          uri: uri,
          statusCode: status,
        );
      }
      if (challenges.any(
        (c) => c.scheme == 'basic' && c.parameters['realm'] != null,
      )) {
        _selectBasic(uri, statusCode: status);
        return;
      }
      if (challenges.length == 1 &&
          headers.length == 1 &&
          challenges.single.scheme == 'digest' &&
          _supportedDigest(challenges.single)) {
        await _warmDigest(uri, challenges.single);
        return;
      }
      throw WebDavAuthenticationError(
        'Unsupported authentication challenge',
        uri: uri,
        statusCode: status,
      );
    }
  }

  bool _supportedDigest(AuthenticationChallenge challenge) {
    final p = challenge.parameters;
    final qop = p['qop'];
    return p['realm'] != null &&
        p['nonce'] != null &&
        (p['algorithm'] ?? 'MD5').toLowerCase() == 'md5' &&
        // The SDK compares the complete qop value; it cannot select from lists.
        (qop == null || qop == 'auth');
  }

  Future<void> _warmDigest(Uri uri, AuthenticationChallenge challenge) async {
    var attempts = 0;
    _client.authenticate = (url, scheme, realm) async {
      _checkOpen();
      _configuration._checkUri(url);
      if (scheme != 'Digest' ||
          realm != challenge.parameters['realm'] ||
          attempts++ >= 2) {
        return false;
      }
      _client.addCredentials(
        _configuration.scope,
        realm ?? '',
        HttpClientDigestCredentials(
          _configuration.username,
          _configuration.password,
        ),
      );
      return true;
    };
    final response = await _probe(uri);
    final status = response.statusCode;
    await response.drain<void>();
    _checkOpen();
    if (status != HttpStatus.notFound &&
        !(status >= HttpStatus.ok && status < HttpStatus.multipleChoices)) {
      throw WebDavAuthenticationError(
        'Digest authentication failed',
        uri: uri,
        statusCode: status,
      );
    }
  }

  Future<HttpClientResponse> _probe(Uri uri) async {
    _checkOpen();
    _lastProbeUri = uri;
    final request = await _client.openUrl(WebDavMethod.propfind.name, uri);
    if (_closed) {
      request.abort();
      _checkOpen();
    }
    _pending.add(request);
    request.followRedirects = false;
    try {
      const param = PropfindPropRequestParam(
        depth: Depth.resource,
        props: [PropfindRequestProp.dav(WebDavElementNames.resourcetype)],
      );
      param.beforeAddRequestBody(request);
      request.write(param.toRequestBody());
      final response = await request.close();
      _lastStatus = response.statusCode;
      return response;
    } finally {
      _pending.remove(request);
    }
  }
}
