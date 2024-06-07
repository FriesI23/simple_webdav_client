// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

abstract interface class Prop<T> {
  String get name;
  String? get namespace;
  T? get value;
}
