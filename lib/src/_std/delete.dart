// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import '../request.dart';
import 'depth.dart';
import 'if.dart';

final class DeleteRequestParam
    with IfHeaderRequestMixin
    implements WebDavRequestParam {
  @override
  final IfOr? condition;

  final Depth? depth;

  const DeleteRequestParam({this.depth, this.condition});

  const DeleteRequestParam.only({this.condition}) : depth = Depth.resource;
  const DeleteRequestParam.recursive({this.condition}) : depth = Depth.all;

  @override
  void beforeAddRequestBody(HttpClientRequest request) {
    final depth = this.depth;
    if (depth != null) {
      request.headers.add(Depth.headerKey, depth.name);
    }
  }

  @override
  String? toRequestBody() => null;
}
