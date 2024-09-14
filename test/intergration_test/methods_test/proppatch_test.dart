// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';

import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/dav.dart';
import 'package:simple_webdav_client/utils.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:xml/xml.dart';

import '../server.dart';

final class Authors implements ToXmlCapable {
  final List<String> authors;
  final String ns;

  const Authors(this.authors, this.ns);

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    for (var author in authors) {
      context.element("Author", namespace: ns, nest: () {
        context.text(author);
      });
    }
  }
}

void main() {
  group("test proppatch", () {
    late final TestUsagedHttpServer server;
    late final WebDavStdClient client;
    late final Uri addr;

    setUpAll(() async {
      server = TestUsagedHttpServer();
      await server.open();
      client = WebDavClient.std();
      addr = Uri(scheme: 'http', host: "localhost", port: server.bindPort);
    });

    tearDownAll(() async {
      client.close();
      await server.close();
    });

    setUp(() {
      server.expectedResponse = null;
      server.serverSideChecker = null;
    });

    test(
        "RFC4918 9.2.2 PROPPATCH, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.2.2",
        () async {
      final ns = "http://ns.example.com/standards/z39.50/";

      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:propertyupdate xmlns:a1="DAV:" xmlns:a2="http://ns.example.com/standards/z39.50/">
  <a1:set>
    <a1:prop>
      <a2:Authors>
        <a2:Author>Jim Whitehead</a2:Author>
        <a2:Author>Roy Fielding</a2:Author>
      </a2:Authors>
    </a1:prop>
  </a1:set>
  <a1:remove>
    <a1:prop>
      <a2:Copyright-Owner/>
    </a1:prop>
  </a1:remove>
</a1:propertyupdate>
'''
          .trim();

      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<D:multistatus xmlns:D="DAV:"
        xmlns:Z="http://ns.example.com/standards/z39.50/">
  <D:response>
    <D:href>http://www.example.com/bar.html</D:href>
    <D:propstat>
      <D:prop><Z:Authors/></D:prop>
      <D:status>HTTP/1.1 424 Failed Dependency</D:status>
    </D:propstat>
    <D:propstat>
      <D:prop><Z:Copyright-Owner/></D:prop>
      <D:status>HTTP/1.1 409 Conflict</D:status>
    </D:propstat>
    <D:responsedescription>
      Copyright Owner cannot be deleted or altered.
    </D:responsedescription>
  </D:response>
</D:multistatus>
'''
          .trim();

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.multiStatus;
        event.response.headers.contentType =
            ContentType.parse('application/xml; charset="utf-8"');
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      final propParsers = Map.of(kStdPropParserManager);
      propParsers[(name: "Authors", ns: ns)] =
          const TestUsageXmlStringPropParser();
      propParsers[(name: "Copyright-Owner", ns: ns)] =
          const TestUsageXmlStringPropParser();

      final propstatParser = BasePropstatElementParser(
          parserManger: WebDavResposneDataParserManger(parsers: propParsers),
          statusParser: const BaseHttpStatusElementParser(),
          errorParser: const BaseErrorElementParser());
      final responseParser = BaseResponseElementParser(
          hrefParser: const BaseHrefElementParser(),
          statusParser: const BaseHttpStatusElementParser(),
          propstatParser: propstatParser,
          errorParser: const BaseErrorElementParser(),
          locationParser: const BaseHrefElementParser());
      final multistatParser =
          BaseMultistatusElementParser(responseParser: responseParser);

      final parsers = Map.of(kStdElementParserManager);
      parsers[(name: WebDavElementNames.multistatus, ns: kDavNamespaceUrlStr)] =
          multistatParser;

      final resultParser = BaseRespMultiResultParser(
          parserManger: WebDavResposneDataParserManger(parsers: parsers));

      final request = await client
          .dispatch(addr, responseResultParser: resultParser)
          .updateProps(operations: [
        ProppatchRequestProp.set(
            name: "Authors",
            namespace: ns,
            value: Authors(["Jim Whitehead", "Roy Fielding"], ns)),
        ProppatchRequestProp.remove(name: "Copyright-Owner", namespace: ns),
      ]);

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.headers["Depth"], isNull);
        expect(event.headers.contentType.toString(),
            equals(XmlContentType.applicationXml.toString()));
        final body = await utf8.decodeStream(event);
        expect(XmlDocument.parse(body).toXmlString(pretty: true), requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final response = await request.close();
      expect(response.body, isNull);
      final result = await response.parse();
      expect(response.body, equals(responseBody));
      expect(result!.length, 1);
      expect(result.first.status, HttpStatus.multiStatus);
      expect(result.first.path, Uri.parse("http://www.example.com/bar.html"));
      expect(result.first.error, isNull);
      expect(result.first.props.length, 2);
      expect(
          result.first.desc, 'Copyright Owner cannot be deleted or altered.');
      final prop1 = result.first.find("Authors", emptyNamespace: false).first;
      expect(prop1.name, "Authors");
      expect(prop1.namespace, equals(Uri.parse(ns)));
      expect(prop1.status, HttpStatus.failedDependency);
      expect(prop1.value, '');
      final prop2 = result.first.find("Copyright-Owner", namespace: ns).first;
      expect(prop2.name, "Copyright-Owner");
      expect(prop2.namespace, equals(Uri.parse(ns)));
      expect(prop2.status, HttpStatus.conflict);
      expect(prop2.value, '');
    });
  });
}
