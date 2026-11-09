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

  /// Creates a client using SDK-managed HTTP transport and authentication.
  ///
  /// Configure native site authentication with [setAuthenticate] and
  /// [addCredentials], or use [WebDavStdClient.authenticated] for managed auth.
  WebDavStdClient([SecurityContext? context]) {
    client = HttpClient(context: context);
  }

  /// Creates a client using an existing [HttpClient], including its SDK
  /// authentication, proxy and TLS settings.
  ///
  /// Calling [close] also closes [client]. See [WebDavStdClient.authenticated]
  /// for package-managed site authentication.
  WebDavStdClient.withClient(this.client);

  /// Creates a native WebDAV client with scoped Basic or Digest authentication.
  ///
  /// Sets Authorization directly, replacing [HttpClient.authenticate] and
  /// [HttpClient.addCredentials] for site authentication. Supports mixed server
  /// challenges containing Basic. [authentication] selects automatic discovery
  /// or preemptive Basic and limits requests to one origin and directory subtree.
  ///
  /// ```dart
  /// import 'package:simple_webdav_client/client.dart';
  ///
  /// final dav = WebDavStdClient.authenticated(
  ///   authentication: WebDavAuthenticationConfig(
  ///     scope: Uri.parse('https://example.com/dav/'),
  ///     username: 'user',
  ///     password: 'app-password',
  ///   ),
  /// );
  /// // Use dav.dispatch(...) and close dav when finished.
  /// ```
  ///
  /// > For SDK-managed site authentication, use [WebDavStdClient.new] or
  /// > [WebDavStdClient.withClient] with [setAuthenticate] / [addCredentials].
  /// > With this constructor, supply server credentials in
  /// > [WebDavAuthenticationConfig]; both methods throw [StateError].
  ///
  /// Proxy authentication remains SDK-managed: configure [HttpClient.findProxy],
  /// [setAuthenticateProxy] and [addProxyCredentials] separately. An injected
  /// [client] retains its proxy and TLS settings, must have no SDK site
  /// credentials or authentication callback, and is also closed by [close].
  ///
  /// For custom HTTP Digest connections, supply [connectionFactory] here.
  /// HTTP Digest uses a fresh connection per request; other modes and HTTPS
  /// retain the client's connection handling.
  ///
  /// Automatic discovery completes before the first business request. An
  /// anonymous successful probe keeps requests anonymous; choose an appropriate
  /// probe URI or explicit Basic if authentication is needed for the operation.
  /// Redirects are returned to the caller, and business requests are not replayed
  /// by the package. SDK proxy-authentication retries can omit request bodies.
  /// Transport exceptions propagate unchanged. Create a new client to change
  /// credentials or rediscover an expired Digest nonce.
  ///
  /// Throws [UnsupportedError] on the Web.
  WebDavStdClient.authenticated({
    required WebDavAuthenticationConfig authentication,
    HttpClient? client,
    Future<ConnectionTask<Socket>> Function(
      Uri uri,
      String? proxyHost,
      int? proxyPort,
    )?
    connectionFactory,
  }) {
    this.client = client ?? HttpClient();
    _authentication = WebDavAuthenticationSession(
      authentication,
      this.client,
      connectionFactory: connectionFactory,
    );
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
  /// Returns `false` when authorization cannot be provided.
  /// Throws [StateError] when using [WebDavStdClient.authenticated].
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
        'SDK authentication cannot be mixed with '
        'package-managed authentication.',
      );
    }
  }

  /// Sets the function to be called when a proxy is requesting authentication.
  ///
  /// Delegates to [HttpClient.authenticateProxy].
  /// Also available with [WebDavStdClient.authenticated]; use
  /// [addProxyCredentials] to supply proxy credentials from this callback.
  @override
  void setAuthenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {
    client.authenticateProxy = f;
  }

  /// Add credentials to be used for authorizing requests.
  ///
  /// Delegates to [HttpClient.addCredentials].
  /// Throws [StateError] when using [WebDavStdClient.authenticated].
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
  /// Delegates to [HttpClient.addProxyCredentials].
  /// Also available with [WebDavStdClient.authenticated]. Proxy credentials
  /// are independent of server credentials in [WebDavAuthenticationConfig].
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {
    client.addProxyCredentials(host, port, realm, credentials);
  }

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
