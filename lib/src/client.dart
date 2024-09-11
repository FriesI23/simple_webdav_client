// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import '_std/client.dart';
import 'method.dart';
import 'request.dart';
import 'response.dart';

abstract interface class WebDavClient {
  /// Create WebDAV Client which comlies with [RFC4918].
  static WebDavStdClient std({SecurityContext? context}) =>
      WebDavStdClient(context);

  /// Create WebDAV Client which comlies with [RFC4918] by passing
  /// in [HttpClient].
  static WebDavStdClient stdFromClient(HttpClient client) =>
      WebDavStdClient.withClient(client);

  /// Close connection
  void close({bool force = false});

  /// Checks whether this client is closed.
  bool get closed;

  /// Sets the function to be called when a site is requesting authentication.
  void setAuthenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f);

  /// Sets the function to be called when a proxy is requesting authentication.
  void setAuthenticateProxy(
      Future<bool> Function(
              String host, int port, String scheme, String? realm)?
          f);

  /// Add credentials to be used for authorizing requests.
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials);

  /// Add credentials to be used for authorizing proxies.
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials);

  /// Opens a WebDAV connection.
  Future<WebDavRequest<WebDavResponse, P>>
      openUrl<P extends WebDavRequestParam>(
          {required WebDavMethod method, required Uri url, required P param});
}
