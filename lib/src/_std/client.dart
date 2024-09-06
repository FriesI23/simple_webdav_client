// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import '../client.dart';
import '../method.dart';
import '../request.dart';
import 'client_dispatcher.dart';
import 'decoder_mgr.dart';
import 'parser.dart';
import 'request.dart';
import 'response.dart';

class WebDavStdClient implements WebDavClient {
  bool _closing = false;

  late final HttpClient client;

  WebDavStdClient([SecurityContext? context]) {
    client = HttpClient(context: context);
  }

  @override
  void close({bool force = false}) {
    if (_closing) return;
    client.close(force: force);
    _closing = true;
  }

  @override
  void setAuthenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      client.authenticate = f;

  @override
  void setAuthenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      client.authenticateProxy = f;

  @override
  void addCredentials(
          Uri url, String realm, HttpClientCredentials credentials) =>
      client.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(String host, int port, String realm,
          HttpClientCredentials credentials) =>
      client.addProxyCredentials(host, port, realm, credentials);

  @override
  bool get closed => _closing;

  @override
  Future<WebDavStdRequest<P>> openUrl<P extends WebDavRequestParam>({
    required WebDavMethod method,
    required Uri url,
    required P param,
    ResponseBodyDecoderManager? responseBodyDecoders,
    ResponseResultParser<WebDavStdResResultView>? responseResultParser,
  }) =>
      client.openUrl(method.name, url).then((request) => WebDavStdRequest<P>(
          request: request,
          param: param,
          responseBodyDecoders: responseBodyDecoders,
          responseResultParser: responseResultParser));

  WebDavStdRequestDispatcher dispatch(Uri from) =>
      WebDavStdRequestDispatcher(client: this, from: from);
}
