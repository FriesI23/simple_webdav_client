// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../dav/content_type.dart';
import '../io.dart';
import '../request.dart';
import '../utils.dart';
import 'depth.dart';
import 'if.dart';
import 'request.dart';

class CommonCopyMoveRequestParam
    with IfHeaderRequestMixin
    implements WebDavRequestParam {
  @override
  final IfOr? condition;

  final Uri destination;
  final Depth? depth;
  final bool? overwrite;

  const CommonCopyMoveRequestParam(
      {required this.destination, this.depth, this.overwrite, this.condition});

  @override
  void beforeAddRequestBody(HttpClientRequest request) {
    request.headers.add("Destination", destination.toString());
    final depth = this.depth;
    if (depth != null) {
      request.headers.add(Depth.headerKey, depth.name);
    }
    final overwrite = this.overwrite;
    if (overwrite != null) {
      request.headers.add("Overwrite", overwrite ? "T" : "F");
    }
    addIfHeader(request.headers);
  }

  @override
  String? toRequestBody() => null;
}

class CommonDataRequestParam<T>
    with IfHeaderRequestMixin
    implements WebDavRequestParam {
  @override
  final IfOr? condition;

  final T? data;

  const CommonDataRequestParam({required this.data, this.condition});

  @override
  void beforeAddRequestBody(HttpClientRequest request) {
    addIfHeader(request.headers);
  }

  @override
  String? toRequestBody() => data?.toString();
}

abstract class CommonPropfindRequestParam
    with ToXmlMixin
    implements WebDavRequestParam, ToXmlCapable {
  final Depth? depth;

  const CommonPropfindRequestParam({this.depth});

  @override
  void beforeAddRequestBody(HttpClientRequest request) {
    request.headers.contentType = XmlContentType.applicationXml;
    final depth = this.depth;
    if (depth != null) {
      request.headers.add(Depth.headerKey, depth.name);
    }
  }
}
