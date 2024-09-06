// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/dav.dart';
import 'package:simple_webdav_client/src/_std/error.dart';
import 'package:simple_webdav_client/utils.dart';
import 'package:xml/src/xml/nodes/element.dart';
import 'package:xml/xml.dart';

class TestUsagedHttpServer {
  late HttpServer server;
  final int bindPort;

  Future<void> Function(HttpRequest event)? serverSideChecker;
  Future<bool> Function(HttpRequest event)? expectedResponse;

  TestUsagedHttpServer({this.bindPort = 45678});

  Future<void> open() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, bindPort);
    server.listen((event) async {
      if (WebDavMethod.fromName(event.method) == WebDavMethod.unknown) {
        event.response.statusCode = HttpStatus.methodNotAllowed;
        event.response.close();
        return;
      }
      await serverSideChecker?.call(event);
      final result = expectedResponse?.call(event) ?? Future.value(false);
      if (await result) event.response.close();
    });
  }

  Future<void> close() async => server.close();
}

final class TestUsageXmlStringPropParser
    extends PropElementParser<WebDavStdResourceProp<String>> {
  const TestUsageXmlStringPropParser();

  @override
  WebDavStdResourceProp<String>? convert(
      ({
        String? desc,
        WebDavStdResError? error,
        XmlElement node,
        int status
      }) input) {
    final nsurl = input.node.namespaceUri;
    return WebDavStdResourceProp<String>(
      name: input.node.localName.trim(),
      namespace: nsurl != null ? Uri.tryParse(nsurl) : null,
      status: input.status,
      desc: input.desc,
      error: input.error,
      value: input.node.innerXml.trim(),
      lang: input.node.getAttribute(kXmlLangAttrName),
    );
  }
}
