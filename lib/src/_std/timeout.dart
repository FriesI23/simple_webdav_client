// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:collection';

import '../codec/timeout.dart';

class DavTimeout with ListMixin<double> {
  final DavTimeoutEncoder _encoder;
  final List<double> _timeout;

  const DavTimeout(List<double> timeout,
      {DavTimeoutEncoder encoder = const DavTimeoutEncoder()})
      : _timeout = timeout,
        _encoder = encoder;

  @override
  int get length => _timeout.length;

  @override
  set length(int newLength) =>
      throw UnimplementedError("timeout length can't be changed.");

  @override
  void add(double element) => _timeout.add(element);

  @override
  operator [](int index) => _timeout[index];

  @override
  void operator []=(int index, value) => _timeout[index] = value;

  @override
  String toString() => _encoder.convert(this);
}
