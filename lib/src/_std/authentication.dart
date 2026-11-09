// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' show md5;
import 'package:http_parser/http_parser.dart' show AuthenticationChallenge;
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../dav/element.dart';
import '../error.dart';
import '../io.dart';
import '../method.dart';
import 'depth.dart';
import 'propfind.dart';

part 'authentication_auto.dart';
part 'authentication_basic.dart';

/// How package-managed site authentication chooses an Authorization header.
///
/// These modes authenticate to the WebDAV server. Proxy authentication remains
/// the responsibility of the underlying [HttpClient].
enum WebDavAuthenticationMode {
  /// Selects Basic or supported Digest through read-only discovery.
  ///
  /// Probes with PROPFIND before the first operation; concurrent callers share
  /// discovery. Selects Basic from mixed challenges or Digest from a single
  /// challenge (MD5 with no `qop` or `qop="auth"`). A successful anonymous probe
  /// keeps requests anonymous.
  auto,

  /// Sends Basic credentials immediately without probing the server.
  ///
  /// Use for known Basic servers or when anonymous discovery does not expose
  /// the required authentication. Requires HTTPS unless
  /// [WebDavAuthenticationConfig.allowInsecureBasic] is enabled.
  basic,
}

/// Credentials and authentication settings for a WebDAV directory.
///
/// Use with `WebDavStdClient.authenticated` on native platforms to manage
/// Authorization instead of SDK site credentials and authentication callbacks.
/// Supports Basic and MD5 Digest; proxy authentication remains SDK-managed.
///
/// [scope] limits requests and credentials to one origin and directory subtree.
/// Basic requires HTTPS unless [allowInsecureBasic] is enabled. See [mode] for
/// discovery and preemptive Basic options.
final class WebDavAuthenticationConfig {
  /// Absolute HTTP(S) directory URI limiting where credentials may be sent.
  ///
  /// Must end in `/` and contain no user information, query or fragment.
  /// Out-of-scope requests fail before they are opened.
  final Uri scope;

  /// Initial read-only discovery URI within [scope], defaulting to [scope].
  ///
  /// In automatic mode, choose a resource exposing the required authentication.
  /// A 404 without a challenge makes discovery try parents within [scope].
  final Uri probeUri;

  /// Login name used by the selected authentication scheme.
  final String username;

  /// Login secret, omitted from diagnostic string representations.
  final String password;

  /// Whether to discover authentication or send Basic preemptively.
  ///
  /// Defaults to [WebDavAuthenticationMode.auto].
  final WebDavAuthenticationMode mode;

  /// Explicitly permits Basic over HTTP instead of requiring HTTPS.
  ///
  /// Defaults to false; enabling this sends Basic credentials without TLS.
  final bool allowInsecureBasic;

  /// Deadline for all read-only discovery requests and their response bodies.
  ///
  /// Defaults to 30 seconds and must be positive. Expiry closes the client.
  /// Does not apply to business requests or explicit Basic mode.
  final Duration discoveryTimeout;

  /// Validates and normalizes the credential scope and discovery settings.
  ///
  /// Opens no connection. To skip discovery for a known Basic server:
  ///
  /// ```dart
  /// final authentication = WebDavAuthenticationConfig(
  ///   scope: Uri.parse('https://example.com/dav/'),
  ///   username: 'user',
  ///   password: 'app-password',
  ///   mode: WebDavAuthenticationMode.basic,
  /// );
  /// ```
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
    if (!_containsUri(uri)) {
      throw WebDavAuthenticationError(
        'Request is outside the credential scope',
        uri: uri,
      );
    }
  }

  bool _containsUri(Uri uri) {
    final normalized = uri.normalizePath();
    final segments = normalized.pathSegments;
    final unsafeSegment = segments.any(
      (s) => s == '.' || s == '..' || s.contains('/') || s.contains('\\'),
    );
    final root = scope.path.endsWith('/') ? scope.path : '${scope.path}/';
    return uri.userInfo.isEmpty &&
        normalized.scheme == scope.scheme &&
        normalized.host == scope.host &&
        normalized.port == scope.port &&
        !unsafeSegment &&
        (normalized.path.startsWith(root) ||
            normalized.path == root.substring(0, root.length - 1));
  }

  @override
  String toString() =>
      'WebDavAuthenticationConfig(mode: ${mode.name}, scope: $scope)';
}

/// An authentication policy, challenge or discovery failure.
final class WebDavAuthenticationError implements WebDavError, HttpException {
  /// Explanation of the failure without credential values.
  @override
  final String message;

  /// Failed request or discovery URI, with user information removed.
  @override
  final Uri uri;

  /// Last observed HTTP status, or null if no response was received.
  final int? statusCode;

  /// Creates an authentication error with an optional HTTP [statusCode].
  WebDavAuthenticationError(this.message, {required Uri uri, this.statusCode})
    : uri = uri.replace(userInfo: '');

  @override
  String toString() =>
      'WebDavAuthenticationError: $message '
      '(status: $statusCode, uri: $uri)';
}

/// Coordinates authentication discovery and request setup for one HTTP client.
///
/// The owner is responsible for closing the HTTP client.
abstract interface class WebDavAuthenticationSession {
  /// Creates a session using [configuration] and a dedicated [client].
  ///
  /// [client] must have no SDK site-authentication callbacks or credentials.
  /// [connectionFactory] is an optional socket factory for [client], including
  /// HTTP Digest connections.
  ///
  /// Throws [UnsupportedError] on the Web.
  factory WebDavAuthenticationSession(
    WebDavAuthenticationConfig configuration,
    HttpClient client, {
    Future<ConnectionTask<Socket>> Function(
      Uri uri,
      String? proxyHost,
      int? proxyPort,
    )?
    connectionFactory,
  }) {
    if (!const bool.fromEnvironment('dart.library.io')) {
      throw UnsupportedError(
        'Package-managed authentication requires native IO '
        'to prevent automatic credential forwarding on redirects.',
      );
    }
    if (connectionFactory != null) {
      client.connectionFactory = connectionFactory;
    }
    return switch (configuration.mode) {
      WebDavAuthenticationMode.basic => _BasicAuthenticationSession(
        configuration,
      ),
      WebDavAuthenticationMode.auto => _AutomaticAuthenticationSession(
        configuration,
        client,
        connectionFactory: connectionFactory,
      ),
    };
  }

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
  /// Concurrent calls share the same initialization result.
  /// After a transport failure or a 5xx discovery response, a later call retries
  /// initialization unless the session has closed.
  /// Throws [StateError] after closure and [WebDavAuthenticationError] for
  /// scope violations or discovery failures. Transport exceptions propagate
  /// unchanged.
  Future<void> prepare(Uri uri);

  /// Applies the selected authentication and disables automatic redirects.
  ///
  /// Call after [prepare] completes, before writing or sending [request].
  /// Throws [StateError] after closure or [WebDavAuthenticationError] when
  /// the request is outside the credential scope.
  void configureRequest(HttpClientRequest request);
}

abstract base class _WebDavAuthenticationSession
    implements WebDavAuthenticationSession {
  final WebDavAuthenticationConfig _configuration;
  bool _closed = false;
  Future<_RequestAuthentication>? _initializing;
  late _RequestAuthentication _authentication;

  _WebDavAuthenticationSession(this._configuration);

  @override
  bool get closed => _closed;

  @override
  bool get discovering => false;

  @override
  void close() => _closed = true;

  void _checkOpen() {
    if (closed) {
      throw StateError('The authenticated WebDAV client is closed.');
    }
  }

  @override
  Future<void> prepare(Uri uri) async {
    _checkOpen();
    _configuration._checkUri(uri);
    final initializing = _initializing ??= _initialize();
    try {
      _authentication = await initializing;
    } catch (error) {
      final status = error is WebDavAuthenticationError
          ? error.statusCode
          : null;
      final retryable =
          error is! WebDavAuthenticationError ||
          (status != null && status >= 500 && status < 600);
      if (retryable && identical(_initializing, initializing)) {
        _initializing = null;
      }
      rethrow;
    }
    _checkOpen();
  }

  Future<_RequestAuthentication> _initialize();

  @override
  void configureRequest(HttpClientRequest request) {
    _checkOpen();
    _configuration._checkUri(request.uri);
    _configureTransportRequest(request);
    _authentication.apply(request);
  }
}

sealed class _RequestAuthentication {
  const _RequestAuthentication();

  void apply(HttpClientRequest request);
}

({String username, String password}) _credentialsForChallenge(
  WebDavAuthenticationConfig configuration,
  AuthenticationChallenge? challenge,
) {
  final normalize = challenge?.parameters['charset']?.toLowerCase() == 'utf-8';
  return (
    username: normalize
        ? unorm.nfc(configuration.username)
        : configuration.username,
    password: normalize
        ? unorm.nfc(configuration.password)
        : configuration.password,
  );
}

void _configureTransportRequest(HttpClientRequest request) {
  request.followRedirects = false;
  if (request.uri.scheme == 'https') {
    // Proxy credentials belong to CONNECT, not requests inside the tunnel.
    request.headers.removeAll(HttpHeaders.proxyAuthorizationHeader);
  }
}
