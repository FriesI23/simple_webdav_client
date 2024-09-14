// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../io.dart';
import '../request.dart';
import 'if.dart';

class MkcolRequestParam
    with IfHeaderRequestMixin
    implements WebDavRequestParam {
  @override
  final IfOr? condition;

  const MkcolRequestParam({this.condition});

  @override
  void beforeAddRequestBody(HttpClientRequest request) {
    addIfHeader(request.headers);
  }

  @override
  String? toRequestBody() => null;
}
