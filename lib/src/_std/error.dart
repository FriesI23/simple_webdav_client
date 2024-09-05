// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../error.dart';

enum StdResErrorCond {
  lockTokenMatchesRequestUri("lock-token-matches-request-uri"),
  lockTokenSubmitted("lock-token-submitted"),
  noConflictingLock("no-conflicting-lock"),
  noExternalEntities("no-external-entities"),
  preservedLiveProperties("preserved-live-properties"),
  propfindFiniteDepth("propfind-finite-depth"),
  cannotModifyProtectedProperty("cannot-modify-protected-property");

  static StdResErrorCond? fromName(String name) =>
      StdResErrorCond.values.where((e) => e.name == name).firstOrNull;

  final String name;

  const StdResErrorCond(this.name);
}

class WebDavStdResError extends WebDavResourceError {
  final List<StdResErrorCond> conditions;

  WebDavStdResError(super.message, {this.conditions = const []});

  @override
  String toString() => "StdResErrorCond{$message, "
      "cond=[${conditions.map((e) => e.name).join(",")}]}";
}
