// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'method.dart';
import 'request.dart';
import 'response.dart';

abstract interface class WebDavClient {
  void close({bool force = false});

  bool get closed;

  void setAuthenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f);

  void setAuthenticateProxy(
      Future<bool> Function(
              String host, int port, String scheme, String? realm)?
          f);

  void addCredentials(Uri url, String realm, HttpClientCredentials credentials);

  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials);

  Future<WebDavRequest<WebDavResponse, P>>
      openUrl<P extends WebDavRequestParam>(
          {required WebDavMethod method, required Uri url, required P param});
}
