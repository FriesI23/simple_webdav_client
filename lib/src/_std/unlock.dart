// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import '../request.dart';

final class UnlockRequestParam implements WebDavRequestParam {
  final Uri lockToken;

  const UnlockRequestParam({required this.lockToken});

  @override
  void beforeAddRequestBody(HttpClientRequest request) {
    request.headers.add("Lock-Token", "<$lockToken>");
  }

  @override
  String? toRequestBody() => null;
}
