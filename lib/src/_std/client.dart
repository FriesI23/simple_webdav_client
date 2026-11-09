// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../client.dart';
import '../io.dart';
import '../method.dart';
import '../request.dart';
import 'authentication.dart';
import 'client_dispatcher.dart';
import 'decoder_mgr.dart';
import 'parser.dart';
import 'request.dart';
import 'response.dart';

class WebDavStdClient implements WebDavClient {
  bool _closing = false;

  late final HttpClient client;
  WebDavAuthenticationSession? _authentication;

  WebDavStdClient([SecurityContext? context]) {
    client = HttpClient(context: context);
  }

  WebDavStdClient.withClient(this.client);

  /// Uses package-managed discovery, or explicitly preemptive Basic auth.
  ///
  /// An injected [client] must be dedicated to this instance, with no SDK
  /// authentication callback or credentials registered. Do not configure its
  /// site authentication directly after passing it here. Redirects are not
  /// followed automatically in this mode.
  ///
  /// Throws [UnsupportedError] on the Web because its transport cannot prevent
  /// credential forwarding on automatic redirects. Business 401 responses are
  /// returned without retries; create a new client to rediscover expired Digest
  /// credentials or nonces.
  WebDavStdClient.authenticated({
    required WebDavAuthenticationConfig authentication,
    HttpClient? client,
  }) {
    this.client = client ?? HttpClient();
    _authentication = WebDavAuthenticationSession(authentication, this.client);
  }

  @override
  void close({bool force = false}) {
    if (_closing) return;
    final abortDiscovery = _authentication?.discovering ?? false;
    _authentication?.close();
    client.close(force: force || abortDiscovery);
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
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {
    _checkLegacyAuthentication();
    client.authenticate = f;
  }

  void _checkLegacyAuthentication() {
    if (_authentication != null) {
      throw StateError(
        'SDK site authentication cannot be mixed with '
        'package-managed authentication.',
      );
    }
  }

  /// Sets the function to be called when a proxy is requesting authentication.
  ///
  /// Pass through setter of [HttpClient.authenticateProxy].
  @override
  void setAuthenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) => client.authenticateProxy = f;

  /// Add credentials to be used for authorizing requests.
  ///
  /// Pass through setter of [HttpClient.addCredentials].
  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {
    _checkLegacyAuthentication();
    client.addCredentials(url, realm, credentials);
  }

  /// Add credentials to be used for authorizing proxies.
  ///
  /// Pass through setter of [HttpClient.addProxyCredentials].
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) => client.addProxyCredentials(host, port, realm, credentials);

  @override
  bool get closed => _closing || (_authentication?.closed ?? false);

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
  }) async {
    final authentication = _authentication;
    await authentication?.prepare(url);
    final request = await client.openUrl(method.name, url);
    try {
      authentication?.configureRequest(request);
      return WebDavStdRequest<P>(
        request: request,
        param: param,
        responseBodyDecoders: responseBodyDecoders,
        responseResultParser: responseResultParser,
      );
    } catch (_) {
      request.abort();
      rethrow;
    }
  }

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
  }) => WebDavStdRequestDispatcher(
    client: this,
    from: from,
    respDecoder: responseBodyDecoders,
    respParser: responseResultParser,
  );
}
