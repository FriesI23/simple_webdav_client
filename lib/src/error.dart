// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:xml/xml.dart';

abstract interface class WebDavError implements Exception {}

class WebDavResourceError implements WebDavError, HttpException, XmlException {
  @override
  final String message;
  @override
  final Uri? uri;

  const WebDavResourceError(this.message, {this.uri});
}

class WebDavXmlDecodeError with XmlFormatException implements WebDavError {
  @override
  final String message;
  @override
  final String? buffer;
  @override
  final int? position;

  WebDavXmlDecodeError(this.message, {this.buffer, this.position});
}

class WebDavParserDataError implements WebDavError {
  final String message;
  final XmlNode? data;

  const WebDavParserDataError(this.message, {this.data});
}
