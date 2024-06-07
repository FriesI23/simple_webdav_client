// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

/// Depth Header, value may be 0, 1 or infinity.
///
/// see: https://datatracker.ietf.org/doc/html/rfc4918#section-10.2
enum Depth {
  /// Depth: 0, only to the resource.
  resource('0'),

  /// Depth: 1, resource and its internal members only.
  members('1'),

  /// Depth: infinity, resource and all its members.
  all('infinity');

  static const headerKey = "Depth";

  final String name;

  const Depth(this.name);

  static Depth? fromName(String value) =>
      Depth.values.where((e) => e.name == value).firstOrNull;
}
