// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'method.dart';
import 'response.dart';

abstract interface class WebDavRequest<T extends WebDavResponse,
    P extends WebDavRequestParam> {
  P? get param;
  WebDavMethod get method;

  Future<T> close();
}

abstract interface class WebDavRequestParam {
  void beforeAddRequestBody(HttpClientRequest request);
  String? toRequestBody();
}
