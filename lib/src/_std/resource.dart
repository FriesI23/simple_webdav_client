// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../dav/resource.dart';
import 'error.dart';

class WebDavStdResource
    implements WebDavResource<WebDavStdResourceProp, WebDavStdResError> {
  @override
  final Uri path;
  @override
  final int status;
  @override
  final WebDavStdResError? error;
  @override
  final String? desc;
  @override
  final Uri? redirect;

  final Map<({String? ns, String name}), WebDavStdResourceProp> _props;

  const WebDavStdResource({
    required this.path,
    required this.status,
    this.error,
    this.desc,
    this.redirect,
    Map<({String? ns, String name}), WebDavStdResourceProp> props = const {},
  }) : _props = props;

  @override
  bool get isEmpty => _props.isEmpty;

  @override
  bool get isNotEmpty => _props.isNotEmpty;

  @override
  int get length => _props.length;

  @override
  Iterable<WebDavStdResourceProp> get props => _props.values;

  @override
  String toDebugString() {
    final sb = StringBuffer();
    "WebDavStdResource{path:$path,status:$status,"
        "${error != null ? 'error:$error,' : ''}"
        "${desc != null ? 'desc:desc,' : ''}"
        "props(${_props.length}):${_props.keys.toList()}"
        "}";
    sb.writeln("WebDavStdResource{");
    sb.write("  path:$path,status:$status,");
    if (error != null) sb.write("  err:$error,");
    if (desc != null) sb.write("  desc:$desc");
    sb.writeln("  props(${_props.length}):");
    for (var entry in _props.entries) {
      sb.write("    ");
      if (entry.key.ns != null) sb.write("[${entry.key.ns}]");
      sb.write("${entry.key.name}: ");
      sb.writeln("${entry.value.toDebugString()},");
    }
    sb.write("}");
    return sb.toString();
  }
}

class WebDavStdResourceProp<V>
    implements WebDavResourceProp<V, WebDavStdResError> {
  @override
  final String name;
  @override
  final Uri? namespace;
  @override
  final int status;
  @override
  final String? desc;
  @override
  final WebDavStdResError? error;
  @override
  final V? value;
  @override
  final String? lang;

  const WebDavStdResourceProp({
    required this.name,
    this.namespace,
    required this.status,
    this.desc,
    this.error,
    this.value,
    this.lang,
  });

  @override
  String toDebugString() {
    final sb = StringBuffer();
    sb.write("WebDavStdResourceProp<$V>{");
    sb.write("name:$name,");
    if (namespace != null) sb.write("ns:$namespace,");
    sb.write("status:$status,");
    if (desc != null) sb.write("desc:$desc,");
    if (error != null) sb.write("err:$error,");
    sb.write("value:$value");
    sb.write("}");
    return sb.toString();
  }
}
