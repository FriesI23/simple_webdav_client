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

  _BasicAuthentication(
    WebDavAuthenticationConfig configuration, {
    Uri? uri,
    int? statusCode,
  }) : _header =
           'Basic ${base64Encode(utf8.encode('${configuration.username}:${configuration.password}'))}' {
    if (configuration.scope.scheme != 'https' &&
        !configuration.allowInsecureBasic) {
      throw WebDavAuthenticationError(
        'Basic authentication requires HTTPS',
        uri: uri ?? configuration.probeUri,
        statusCode: statusCode,
      );
    }
  }

  @override
  void apply(HttpClientRequest request) =>
      request.headers.set(HttpHeaders.authorizationHeader, _header);
}
