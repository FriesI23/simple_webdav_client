// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

/// Methods available in WebDAV defined in RFC4918.
/// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9
enum WebDavMethod {
  propfind("PROPFIND"),
  proppatch("PROPPATCH"),
  mkcol("MKCOL"),
  get("GET"),
  head("HEAD"),
  post("POST"),
  delete("DELETE"),
  put("PUT"),
  copy("COPY"),
  move("MOVE"),
  lock("LOCK"),
  unlock("UNLOCK"),
  unknown("");

  final String name;

  const WebDavMethod(this.name);

  static WebDavMethod fromName(String name) => WebDavMethod.values
      .singleWhere((e) => e.name == name, orElse: () => unknown);
}
