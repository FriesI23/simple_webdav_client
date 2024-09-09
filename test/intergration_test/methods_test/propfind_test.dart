// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/dav.dart';
import 'package:simple_webdav_client/utils.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import '../server.dart';

void main() {
  group("test propfind", () {
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
      server.close();
    });

    setUp(() {
      server.expectedResponse = null;
      server.serverSideChecker = null;
    });

    test(
        "RFC4918 9.1.3 Retrieving Named Properties, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.1.3",
        () async {
      final ns = "http://ns.example.com/boxschema/";

      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:propfind xmlns:a1="DAV:" xmlns:a2="http://ns.example.com/boxschema/">
  <a1:prop>
    <a2:bigbox/>
    <a2:author/>
    <a2:DingALing/>
    <a2:Random/>
  </a1:prop>
</a1:propfind>
'''
          .trim();

      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<D:multistatus xmlns:D="DAV:">
  <D:response xmlns:R="http://ns.example.com/boxschema/">
    <D:href>http://www.example.com/file</D:href>
    <D:propstat>
      <D:prop>
        <R:bigbox>
          <R:BoxType>Box type A</R:BoxType>
        </R:bigbox>
        <R:author>
          <R:Name>J.J. Johnson</R:Name>
        </R:author>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
    <D:propstat>
      <D:prop><R:DingALing/><R:Random/></D:prop>
      <D:status>HTTP/1.1 403 Forbidden</D:status>
      <D:responsedescription> The user does not have access to the
DingALing property.
      </D:responsedescription>
    </D:propstat>
  </D:response>
  <D:responsedescription> There has been an access violation error.
  </D:responsedescription>
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
      propParsers[(name: "bigbox", ns: ns)] =
          const TestUsageXmlStringPropParser();
      propParsers[(name: "author", ns: ns)] =
          const TestUsageXmlStringPropParser();
      propParsers[(name: "DingALing", ns: ns)] =
          const TestUsageXmlStringPropParser();
      propParsers[(name: "Random", ns: ns)] =
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
          .findProps(props: [
        PropfindRequestProp("bigbox", ns),
        PropfindRequestProp("author", ns),
        PropfindRequestProp("DingALing", ns),
        PropfindRequestProp("Random", ns)
      ]);

      Future<void> serverSideChecker(HttpRequest event) async {
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
      expect(result.first.path, Uri.parse("http://www.example.com/file"));
      expect(result.first.error, isNull);
      expect(result.first.props.length, 4);
      final props = result.first.props.toList();
      // bigbox
      expect(props[0].name, "bigbox");
      expect(props[0].namespace, equals(Uri.parse(ns)));
      expect(props[0].status, HttpStatus.ok);
      expect(props[0].value, "<R:BoxType>Box type A</R:BoxType>");
      // author
      expect(props[1].name, "author");
      expect(props[1].namespace, equals(Uri.parse(ns)));
      expect(props[1].status, HttpStatus.ok);
      expect(props[1].value, "<R:Name>J.J. Johnson</R:Name>");
      // DingALing
      expect(props[2].name, "DingALing");
      expect(props[2].namespace, equals(Uri.parse(ns)));
      expect(props[2].status, HttpStatus.forbidden);
      expect(props[2].value, "");
      // Random
      expect(props[3].name, "Random");
      expect(props[3].namespace, equals(Uri.parse(ns)));
      expect(props[3].status, HttpStatus.forbidden);
      expect(props[3].value, "");
    });
    test(
        "RFC4918 9.1.4 Using 'propname' to Retrieve All Property Names, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.1.4",
        () async {
      final ns = "http://ns.example.com/boxschema/";

      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:propfind xmlns:a1="DAV:">
  <a1:propname/>
</a1:propfind>
'''
          .trim();

      final responseBody = '''
<?xml version="1.0" encoding="utf-8"?>
<multistatus xmlns="DAV:">
  <response>
    <href>http://www.example.com/container/</href>
    <propstat>
      <prop xmlns:R="http://ns.example.com/boxschema/">
        <R:bigbox/>
        <R:author/>
        <creationdate/>
        <displayname/>
        <resourcetype/>
        <supportedlock/>
      </prop>
      <status>HTTP/1.1 200 OK</status>
    </propstat>
  </response>
  <response>
    <href>http://www.example.com/container/front.html</href>
    <propstat>
      <prop xmlns:R="http://ns.example.com/boxschema/">
        <R:bigbox/>
        <creationdate/>
        <displayname/>
        <getcontentlength/>
        <getcontenttype/>
        <getetag/>
        <getlastmodified/>
        <resourcetype/>
        <supportedlock/>
      </prop>
      <status>HTTP/1.1 200 OK</status>
    </propstat>
  </response>
</multistatus>
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
      propParsers[(name: "bigbox", ns: ns)] =
          const TestUsageXmlStringPropParser();
      propParsers[(name: "author", ns: ns)] =
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
          .findPropNames();

      Future<void> serverSideChecker(HttpRequest event) async {
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
      expect(result!.length, 2);
      final resourceList = result.toList();
      List<WebDavStdResourceProp> props;
      List resourceCases;
      // resource1: http://www.example.com/container/
      expect(resourceList[0].status, HttpStatus.multiStatus);
      expect(
        resourceList[0].path,
        Uri.parse("http://www.example.com/container/"),
      );
      expect(resourceList[0].error, isNull);
      expect(resourceList[0].props.length, 6);
      // resource1's props
      props = resourceList[0].props.toList();
      resourceCases = [
        ("bigbox", ns, HttpStatus.ok, ''),
        ("author", ns, HttpStatus.ok, ''),
        ("creationdate", kDavNamespaceUrlStr, HttpStatus.ok, isNull),
        ("displayname", kDavNamespaceUrlStr, HttpStatus.ok, ''),
        (
          "resourcetype",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          TypeMatcher<ResourceTypes>()
        ),
        (
          "supportedlock",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          TypeMatcher<SupportedLock>()
        ),
      ];
      for (var i = 0; i < resourceCases.length; i++) {
        expect(props[i].name, resourceCases[i].$1,
            reason: "failed in resource ${props[i].name}");
        expect(props[i].namespace, equals(Uri.parse(resourceCases[i].$2)),
            reason: "failed in resource ${props[i].name}");
        expect(props[i].status, resourceCases[i].$3,
            reason: "failed in resource ${props[i].name}");
        expect(props[i].value, resourceCases[i].$4,
            reason: "failed in resource ${props[i].name}");
        if (props[i].value is Iterable) expect(props[i].value, isEmpty);
      }
      // resource2: http://ns.example.com/boxschema/
      expect(resourceList[1].status, HttpStatus.multiStatus);
      expect(
        resourceList[1].path,
        Uri.parse("http://www.example.com/container/front.html"),
      );
      expect(resourceList[1].error, isNull);
      expect(resourceList[1].props.length, 9);
      // resource2's props
      props = resourceList[1].props.toList();
      resourceCases = [
        ("bigbox", ns, HttpStatus.ok, ''),
        ("creationdate", kDavNamespaceUrlStr, HttpStatus.ok, isNull),
        ("displayname", kDavNamespaceUrlStr, HttpStatus.ok, ''),
        ("getcontentlength", kDavNamespaceUrlStr, HttpStatus.ok, isNull),
        ("getcontenttype", kDavNamespaceUrlStr, HttpStatus.ok, isNull),
        ("getetag", kDavNamespaceUrlStr, HttpStatus.ok, ''),
        ("getlastmodified", kDavNamespaceUrlStr, HttpStatus.ok, isNull),
        (
          "resourcetype",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          TypeMatcher<ResourceTypes>()
        ),
        (
          "supportedlock",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          TypeMatcher<SupportedLock>()
        ),
      ];
      for (var i = 0; i < resourceCases.length; i++) {
        expect(props[i].name, resourceCases[i].$1,
            reason: "failed in resource ${props[i].name}");
        expect(props[i].namespace, equals(Uri.parse(resourceCases[i].$2)),
            reason: "failed in resource ${props[i].name}");
        expect(props[i].status, resourceCases[i].$3,
            reason: "failed in resource ${props[i].name}");
        expect(props[i].value, resourceCases[i].$4,
            reason: "failed in resource ${props[i].name}");
        if (props[i].value is Iterable) expect(props[i].value, isEmpty);
      }
    });
  });
}
