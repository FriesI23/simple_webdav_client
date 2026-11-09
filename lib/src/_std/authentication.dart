// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' show md5;
import 'package:http_parser/http_parser.dart' show AuthenticationChallenge;

import '../dav/element.dart';
import '../error.dart';
import '../io.dart';
import '../method.dart';
import 'depth.dart';
import 'propfind.dart';

part 'authentication_auto.dart';
part 'authentication_basic.dart';

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
/// Package-managed authentication is only available on native platforms.
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

  /// Deadline for all read-only discovery requests and their response bodies.
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
  /// SDK site-authentication callbacks or credentials. Throws [UnsupportedError]
  /// on the Web, where the transport cannot disable automatic redirects.
  factory WebDavAuthenticationSession(
    WebDavAuthenticationConfig configuration,
    HttpClient client,
  ) {
    if (!const bool.fromEnvironment('dart.library.io')) {
      throw UnsupportedError(
        'Package-managed authentication requires native IO '
        'to prevent automatic credential forwarding on redirects.',
      );
    }
    return switch (configuration.mode) {
      WebDavAuthenticationMode.basic => _BasicAuthenticationSession(
        configuration,
      ),
      WebDavAuthenticationMode.auto => _AutomaticAuthenticationSession(
        configuration,
        client,
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

// Shared scope checks, lifecycle and cached initialization do not depend on
// whether authentication was configured explicitly or discovered.
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
    _authentication = await (_initializing ??= _initialize());
    _checkOpen();
  }

  Future<_RequestAuthentication> _initialize();

  @override
  void configureRequest(HttpClientRequest request) {
    _checkOpen();
    _configuration._checkUri(request.uri);
    request.followRedirects = false;
    _authentication.apply(request);
  }
}

// No strategy registers SDK credentials: a business 401 must remain a response,
// never an SDK retry that silently drops the original body.
sealed class _RequestAuthentication {
  const _RequestAuthentication();

  void apply(HttpClientRequest request);
}
