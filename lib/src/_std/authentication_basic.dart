// Copyright (c) 2026 Fries_I23
// SPDX-License-Identifier: MIT

part of 'authentication.dart';

final class _BasicAuthenticationSession extends _WebDavAuthenticationSession {
  _BasicAuthenticationSession(super.configuration);

  @override
  Future<_RequestAuthentication> _initialize() async =>
      _BasicAuthentication(_configuration);
}

final class _BasicAuthentication extends _RequestAuthentication {
  final String _header;

  factory _BasicAuthentication(
    WebDavAuthenticationConfig configuration, {
    AuthenticationChallenge? challenge,
    Uri? uri,
    int? statusCode,
  }) {
    if (configuration.scope.scheme != 'https' &&
        !configuration.allowInsecureBasic) {
      throw WebDavAuthenticationError(
        'Basic authentication requires HTTPS',
        uri: uri ?? configuration.probeUri,
        statusCode: statusCode,
      );
    }
    final credentials = _credentialsForChallenge(configuration, challenge);
    return _BasicAuthentication._(
      'Basic ${base64Encode(utf8.encode('${credentials.username}:${credentials.password}'))}',
    );
  }

  const _BasicAuthentication._(this._header);

  @override
  void apply(HttpClientRequest request) =>
      request.headers.set(HttpHeaders.authorizationHeader, _header);
}
