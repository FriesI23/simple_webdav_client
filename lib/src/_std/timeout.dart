// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:collection';

import '../codec/timeout.dart';

class Timeout with ListMixin<double> {
  final TimeoutEncoder _encoder;
  final List<double>? _timeout;

  const Timeout(List<double>? timeout,
      {TimeoutEncoder encoder = const TimeoutEncoder()})
      : _timeout = timeout,
        _encoder = encoder;

  List<double> get _timeoutInst => _timeout ?? const [];

  @override
  int get length => _timeoutInst.length;

  @override
  set length(int newLength) => _timeoutInst.length = newLength;

  @override
  operator [](int index) => _timeoutInst[index];

  @override
  void operator []=(int index, value) => _timeoutInst[index] = value;

  @override
  String toString() => _encoder.convert(this);
}
