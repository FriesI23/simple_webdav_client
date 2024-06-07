// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dav/resource.dart';
import 'method.dart';

abstract interface class WebDavResponse<T extends WebDavResponseResultView> {
  Uri get path;
  WebDavMethod get method;

  Future<T?> parse();
}

abstract interface class WebDavResponseResultView<R extends WebDavResource>
    implements Iterable<R> {
  bool contain(Uri path);

  String toDebugString();
}

abstract interface class WebDavResponseResult<R extends WebDavResource>
    implements WebDavResponseResultView<R> {
  bool add(R resource);
  R? remove(Uri path);
  R? find(Uri path);
  void clear();
}
