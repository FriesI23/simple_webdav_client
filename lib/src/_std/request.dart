// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:xml/xml.dart';

import '../io.dart';
import '../method.dart';
import '../request.dart';
import '../utils.dart';
import 'const.dart';
import 'decoder_mgr.dart';
import 'namespace_mgr.dart';
import 'parser.dart';
import 'response.dart';

class WebDavStdRequest<P extends WebDavRequestParam>
    implements WebDavRequest<WebDavStdResponse<WebDavStdResResultView>, P> {
  final HttpClientRequest request;
  final ResponseBodyDecoderManager? responseBodyDecoders;
  final ResponseResultParser<WebDavStdResResultView>? responseResultParser;
  @override
  final P? param;

  WebDavStdRequest({
    required this.request,
    required this.param,
    this.responseBodyDecoders,
    this.responseResultParser,
  });

  @override
  Future<WebDavStdResponse<WebDavStdResResultView>> close() {
    param?.beforeAddRequestBody(request);
    final body = param?.toRequestBody();
    if (body != null) request.write(body);
    return request.close().then((response) => WebDavStdResponse(
          response: response,
          path: request.uri,
          method: method,
          bodyDecoders: responseBodyDecoders ?? kStdDecoderManager,
          resultParser: responseResultParser ?? kStdResponseResultParser,
        ));
  }

  @override
  WebDavMethod get method => WebDavMethod.fromName(request.method);
}

abstract mixin class ToXmlMixin implements ToXmlCapable {
  XmlBuilder processXmlData() {
    final builder = XmlBuilder(optimizeNamespaces: false)
      ..processing('xml', 'version="1.0" encoding="utf-8"');
    toXml(builder, StdNamespaceManger());
    return builder;
  }
}
