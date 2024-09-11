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

  WebDavStdClient.withClient(this.client);

  @override
  void close({bool force = false}) {
    if (_closing) return;
    client.close(force: force);
    _closing = true;
  }

  /// Sets the function to be called when a site is requesting authentication.
  ///
  /// Pass through setter of [HttpClient.authenticate]. This callback called
  /// when server returns Unauthorized (401). [addCredentials] can be called
  /// in this callback method to authorize client.
  /// Return [false] when authorization cannot be provided."
  ///
  /// Example:
  ///
  /// ```dart
  /// client.setAuthenticate((url, scheme, realm) {
  ///   client.addCredentials(...);
  ///   return Future.value(true);
  /// });
  /// ```
  @override
  void setAuthenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      client.authenticate = f;

  /// Sets the function to be called when a proxy is requesting authentication.
  ///
  /// Pass through setter of [HttpClient.authenticateProxy].
  @override
  void setAuthenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      client.authenticateProxy = f;

  /// Add credentials to be used for authorizing requests.
  ///
  /// Pass through setter of [HttpClient.addCredentials].
  @override
  void addCredentials(
          Uri url, String realm, HttpClientCredentials credentials) =>
      client.addCredentials(url, realm, credentials);

  /// Add credentials to be used for authorizing proxies.
  ///
  /// Pass through setter of [HttpClient.addProxyCredentials].
  @override
  void addProxyCredentials(String host, int port, String realm,
          HttpClientCredentials credentials) =>
      client.addProxyCredentials(host, port, realm, credentials);

  @override
  bool get closed => _closing;

  /// Opens a WebDAV connection.
  ///
  /// Example:
  ///
  /// ```dart
  /// client.openUrl(
  ///   method: WebDavMethod.propupdate,
  ///   url: Url.parse("http://example.com"),
  ///   param: ProppatchRequestParam(
  ///     ops: [
  ///       ProppatchRequestProp.set(
  ///         name: "author",
  ///         namespace: "CUSTOM:",
  ///         value: ProppatchRequestPropBaseValue("zigzag"))
  ///     ]
  ///   ),
  /// ).then((request) => request.close())
  ///  .then((response) => response.parse())
  ///  .then((result) => print(result?.toDebugString()));
  /// ```
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

  /// Creates a [WebDavStdRequestDispatcher] for handling WebDAV requests.
  ///
  /// Provide [responseBodyDecoders] to customize Http Response's body.
  ///
  /// Provide [responseResultParser] to customize XmlDocument if response's
  /// content type is xml.
  ///
  /// Example: `client.dispatch(someUri).create(...)`
  WebDavStdRequestDispatcher dispatch(
    Uri from, {
    ResponseBodyDecoderManager? responseBodyDecoders,
    ResponseResultParser<WebDavStdResResultView>? responseResultParser,
  }) =>
      WebDavStdRequestDispatcher(
          client: this,
          from: from,
          respDecoder: responseBodyDecoders,
          respParser: responseResultParser);
}
