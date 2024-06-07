// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../error.dart';

abstract interface class WebDavResource<P extends WebDavResourceProp,
    E extends WebDavResourceError> {
  Uri? get path;
  int? get status;
  E? get error;
  String? get desc;
  Uri? get redirect;

  Iterable<P> get props;
  int get length;
  bool get isEmpty;
  bool get isNotEmpty;

  String toDebugString();
}

abstract interface class WebDavResourceProp<V, E extends WebDavResourceError> {
  String? get name;
  Uri? get namespace;
  int? get status;
  V? get value;
  E? get error;
  String? get desc;
  String? get lang;

  String toDebugString();
}
