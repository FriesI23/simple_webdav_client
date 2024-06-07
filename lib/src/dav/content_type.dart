// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

abstract final class XmlContentType {
  static final textXml = ContentType("text", "xml", charset: "utf-8");
  static final applicationXml =
      ContentType("application", "xml", charset: "utf-8");
}
