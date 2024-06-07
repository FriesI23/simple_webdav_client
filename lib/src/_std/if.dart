// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

class IfOr {
  final Iterable<IfAnd> _tagList;

  const IfOr(List<IfAnd> list) : _tagList = list;

  @override
  String toString() => _tagList.map((e) => e.toString()).join('\n ');
}

class IfAnd {
  final Uri? _resourceTag;
  final List<IfCondition> _conditions;

  const IfAnd.tagged(Uri resource, List<IfCondition> conditions)
      : _resourceTag = resource,
        _conditions = conditions;

  const IfAnd.notag(List<IfCondition> conditions)
      : _resourceTag = null,
        _conditions = conditions;

  @override
  String toString() {
    final sb = StringBuffer();
    if (_resourceTag != null) sb.writeAll([_resourceTag.toString(), ' ']);
    sb.write("(");
    sb.writeAll(_conditions.map((e) => e.toString()), ' ');
    sb.write(")");
    return sb.toString();
  }
}

class IfCondition {
  final bool _not;
  final String? _etag;
  final Uri? _abspath;

  const IfCondition.token(Uri abspath)
      : _not = false,
        _etag = null,
        _abspath = abspath;

  const IfCondition.notToken(Uri abspath)
      : _not = true,
        _etag = null,
        _abspath = abspath;

  const IfCondition.etag(String etag)
      : _not = true,
        _etag = etag,
        _abspath = null;

  const IfCondition.notEtag(String etag)
      : _not = true,
        _etag = etag,
        _abspath = null;

  bool get isEtag => _etag != null ? true : false;

  String get value => _etag ?? _abspath?.toString() ?? '';

  @override
  String toString() {
    final sb = StringBuffer();
    if (_not) sb.write("Not ");
    sb.write(isEtag ? "[" : "<");
    sb.write(value);
    sb.write(isEtag ? "]" : ">");
    return sb.toString();
  }
}

mixin IfHeaderRequestMixin {
  IfOr? get condition;

  void addIfHeader(HttpHeaders headers) =>
      condition != null ? headers.add("If", condition.toString()) : null;
}
