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

final class BaseStringParser extends Converter<XmlElement, String> {
  const BaseStringParser();

  @override
  String convert(XmlElement input) => input.innerText;
}

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
      await server.close();
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
      // resource2: http://www.example.com/container/front.html
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
    test(
        "RFC4918 9.1.5 Using So-called 'allprop', "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.1.5",
        () async {
      final ns = "http://ns.example.com/boxschema/";

      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:propfind xmlns:a1="DAV:">
  <a1:allprop/>
</a1:propfind>
'''
          .trim();

      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>/container/</D:href>
    <D:propstat>
      <D:prop xmlns:R="http://ns.example.com/boxschema/">
        <R:bigbox><R:BoxType>Box type A</R:BoxType></R:bigbox>
        <R:author><R:Name>Hadrian</R:Name></R:author>
        <D:creationdate>1997-12-01T17:42:21-08:00</D:creationdate>
        <D:displayname>Example collection</D:displayname>
        <D:resourcetype><D:collection/></D:resourcetype>
        <D:supportedlock>
          <D:lockentry>
            <D:lockscope><D:exclusive/></D:lockscope>
            <D:locktype><D:write/></D:locktype>
          </D:lockentry>
          <D:lockentry>
            <D:lockscope><D:shared/></D:lockscope>
            <D:locktype><D:write/></D:locktype>
          </D:lockentry>
        </D:supportedlock>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
  </D:response>
  <D:response>
    <D:href>/container/front.html</D:href>
    <D:propstat>
      <D:prop xmlns:R="http://ns.example.com/boxschema/">
        <R:bigbox><R:BoxType>Box type B</R:BoxType>
        </R:bigbox>
        <D:creationdate>1997-12-01T18:27:21-08:00</D:creationdate>
        <D:displayname>Example HTML resource</D:displayname>
        <D:getcontentlength>4525</D:getcontentlength>
        <D:getcontenttype>text/html</D:getcontenttype>
        <D:getetag>"zzyzx"</D:getetag>
        <D:getlastmodified
          >Mon, 12 Jan 1998 09:25:56 GMT</D:getlastmodified>
        <D:resourcetype/>
        <D:supportedlock>
          <D:lockentry>
            <D:lockscope><D:exclusive/></D:lockscope>
            <D:locktype><D:write/></D:locktype>
          </D:lockentry>
          <D:lockentry>
            <D:lockscope><D:shared/></D:lockscope>
            <D:locktype><D:write/></D:locktype>
          </D:lockentry>
        </D:supportedlock>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
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
          .findAllProps(depth: Depth.members);

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.headers['Depth']!.first, "1");
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

      // resource1: /container/
      expect(resourceList[0].status, HttpStatus.multiStatus);
      expect(
        resourceList[0].path,
        Uri.parse("/container/"),
      );
      expect(resourceList[0].error, isNull);
      expect(resourceList[0].props.length, 6);

      // resource1's props
      props = resourceList[0].props.toList();
      resourceCases = [
        ("bigbox", ns, HttpStatus.ok, '<R:BoxType>Box type A</R:BoxType>'),
        ("author", ns, HttpStatus.ok, '<R:Name>Hadrian</R:Name>'),
        (
          "creationdate",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          equals(DateTime.parse("1997-12-01T17:42:21-08:00"))
        ),
        (
          "displayname",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          'Example collection'
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

      void resource1PropCase() {
        final resourceType = props[4] as WebDavStdResourceProp<ResourceTypes>;
        expect(resourceType.name, "resourcetype");
        expect(resourceType.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
        expect(resourceType.status, HttpStatus.ok);
        expect(resourceType.value, TypeMatcher<ResourceTypes>());
        expect(resourceType.value!.length, 1);
        expect(resourceType.value!.isCollection, isTrue);
        final supportedLock = props[5] as WebDavStdResourceProp<SupportedLock>;
        expect(supportedLock.name, "supportedlock");
        expect(supportedLock.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
        expect(supportedLock.status, HttpStatus.ok);
        expect(supportedLock.value, TypeMatcher<SupportedLock>());
        expect(supportedLock.value!.length, 2);
        expect(supportedLock.value!.first.lockScope, LockScope.exclusive);
        expect(supportedLock.value!.first.isWriteLock, isTrue);
        expect(supportedLock.value!.last.lockScope, LockScope.shared);
        expect(supportedLock.value!.last.isWriteLock, isTrue);
      }

      resource1PropCase();

      // resource2: /container/front.html
      expect(resourceList[1].status, HttpStatus.multiStatus);
      expect(
        resourceList[1].path,
        Uri.parse("/container/front.html"),
      );
      expect(resourceList[1].error, isNull);
      expect(resourceList[1].props.length, 9);

      // resource2's props
      props = resourceList[1].props.toList();
      resourceCases = [
        ("bigbox", ns, HttpStatus.ok, '<R:BoxType>Box type B</R:BoxType>'),
        (
          "creationdate",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          DateTime.parse("1997-12-01T18:27:21-08:00")
        ),
        (
          "displayname",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          'Example HTML resource'
        ),
        ("getcontentlength", kDavNamespaceUrlStr, HttpStatus.ok, 4525),
        (
          "getcontenttype",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          TypeMatcher<ContentType>()
        ),
        ("getetag", kDavNamespaceUrlStr, HttpStatus.ok, '"zzyzx"'),
        (
          "getlastmodified",
          kDavNamespaceUrlStr,
          HttpStatus.ok,
          HttpDate.parse("Mon, 12 Jan 1998 09:25:56 GMT")
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

      void resource2PropCase() {
        final resourceType = props[7] as WebDavStdResourceProp<ResourceTypes>;
        expect(resourceType.name, "resourcetype");
        expect(resourceType.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
        expect(resourceType.status, HttpStatus.ok);
        expect(resourceType.value, TypeMatcher<ResourceTypes>());
        expect(resourceType.value!, isEmpty);
        expect(resourceType.value!.isCollection, isFalse);
        final supportedLock = props[8] as WebDavStdResourceProp<SupportedLock>;
        expect(supportedLock.name, "supportedlock");
        expect(supportedLock.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
        expect(supportedLock.status, HttpStatus.ok);
        expect(supportedLock.value, TypeMatcher<SupportedLock>());
        expect(supportedLock.value!.length, 2);
        expect(supportedLock.value!.first.lockScope, LockScope.exclusive);
        expect(supportedLock.value!.first.isWriteLock, isTrue);
        expect(supportedLock.value!.last.lockScope, LockScope.shared);
        expect(supportedLock.value!.last.isWriteLock, isTrue);
      }

      resource2PropCase();
    });
    test(
        "RFC4918 9.1.5 Using 'allprop' with 'include', "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.1.6",
        () async {
      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:propfind xmlns:a1="DAV:">
  <a1:allprop/>
  <a1:include>
    <a1:supported-live-property-set/>
    <a1:supported-report-set/>
  </a1:include>
</a1:propfind>
'''
          .trim();

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.multiStatus;
        event.response.headers.contentType =
            ContentType.parse('application/xml; charset="utf-8"');
        event.response.contentLength = "".length;
        event.response.write("");
        return true;
      }

      server.expectedResponse = expectedResponse;

      final request = await client
          .dispatch(addr)
          .findAllProps(depth: Depth.members, includes: [
        PropfindRequestProp("supported-live-property-set", kDavNamespaceUrlStr),
        PropfindRequestProp("supported-report-set", kDavNamespaceUrlStr),
      ]);

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.headers['Depth']!.first, "1");
        expect(event.headers.contentType.toString(),
            equals(XmlContentType.applicationXml.toString()));
        final body = await utf8.decodeStream(event);
        expect(XmlDocument.parse(body).toXmlString(pretty: true), requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      await request.close();
    });
    test(
        "RFC4918 15.8.1 Retrieving DAV:lockdiscovery, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-15.8.1",
        () async {
      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:propfind xmlns:a1="DAV:">
  <a1:prop>
    <a1:lockdiscovery/>
  </a1:prop>
</a1:propfind>
'''
          .trim();

      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<D:multistatus xmlns:D='DAV:'>
  <D:response>
    <D:href>http://www.example.com/container/</D:href>
    <D:propstat>
      <D:prop>
        <D:lockdiscovery>
          <D:activelock>
            <D:locktype><D:write/></D:locktype>
            <D:lockscope><D:exclusive/></D:lockscope>
            <D:depth>0</D:depth>
            <D:owner>Jane Smith</D:owner>
            <D:timeout>Infinite</D:timeout>
            <D:locktoken>
              <D:href>urn:uuid:f81de2ad-7f3d-a1b2-4f3c-00a0c91a9d76</D:href>
            </D:locktoken>
            <D:lockroot>
              <D:href>http://www.example.com/container/</D:href>
            </D:lockroot>
          </D:activelock>
        </D:lockdiscovery>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
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

      final activeLockParser = BaseActiveLockElementParser(
          lockScopeParser: BaseLockScopeElementParser(),
          lockTypeParser: BaseWriteLockElementParser(),
          depthParser: DepthElementParser(),
          ownerParser: BaseStringParser(),
          timeoutParser: TimeoutElementParser(),
          lockTokenParser:
              NestedHrefElementParser(hrefParser: BaseHrefElementParser()),
          lockRootParser:
              NestedHrefElementParser(hrefParser: BaseHrefElementParser()));
      final lockdiscoveryParser =
          LockDiscoveryPropParser(pieceParser: activeLockParser);
      final propParsers = Map.of(kStdPropParserManager);
      propParsers[(name: "lockdiscovery", ns: kDavNamespaceUrlStr)] =
          lockdiscoveryParser;

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
        PropfindRequestProp.dav("lockdiscovery"),
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
      expect(result.first.path, Uri.parse("http://www.example.com/container/"));
      expect(result.first.error, isNull);
      expect(result.first.props.length, 1);
      final props = result.first.props.toList();
      // bigbox
      expect(props[0].name, "lockdiscovery");
      expect(props[0].namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(props[0].status, HttpStatus.ok);
      final locks = props[0] as WebDavStdResourceProp<LockDiscovery<String>>;
      expect(locks.status, HttpStatus.ok);
      expect(locks.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(locks.desc, isNull);
      expect(locks.error, isNull);
      expect(locks.value!.length, 1);
      final lock = locks.value!.first;
      expect(lock.isWriteLock, isTrue);
      expect(lock.lockScope, LockScope.exclusive);
      expect(lock.depth, Depth.resource);
      expect(lock.owner, equals("Jane Smith"));
      expect(lock.timeout, equals(double.infinity));
      expect(lock.lockToken,
          equals(Uri.parse("urn:uuid:f81de2ad-7f3d-a1b2-4f3c-00a0c91a9d76")));
      expect(lock.lockRoot,
          equals(Uri.parse("http://www.example.com/container/")));
    });
    test(
        "RFC4918 15.10.1 Retrieving DAV:lockdiscovery, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-15.10.1",
        () async {
      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:propfind xmlns:a1="DAV:">
  <a1:prop>
    <a1:supportedlock/>
  </a1:prop>
</a1:propfind>
'''
          .trim();

      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>http://www.example.com/container/</D:href>
    <D:propstat>
      <D:prop>
        <D:supportedlock>
          <D:lockentry>
            <D:lockscope><D:exclusive/></D:lockscope>
            <D:locktype><D:write/></D:locktype>
          </D:lockentry>
          <D:lockentry>
            <D:lockscope><D:shared/></D:lockscope>
            <D:locktype><D:write/></D:locktype>
          </D:lockentry>
        </D:supportedlock>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
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

      final request = await client.dispatch(addr).findProps(props: [
        PropfindRequestProp.dav("supportedlock"),
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
      expect(result.first.path, Uri.parse("http://www.example.com/container/"));
      expect(result.first.error, isNull);
      expect(result.first.props.length, 1);
      final props = result.first.props.toList();
      // bigbox
      expect(props[0].name, "supportedlock");
      expect(props[0].namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(props[0].status, HttpStatus.ok);
      final locks = props[0] as WebDavStdResourceProp<SupportedLock>;
      expect(locks.status, HttpStatus.ok);
      expect(locks.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(locks.desc, isNull);
      expect(locks.error, isNull);
      expect(locks.value!.length, 2);
      final l1 = locks.value!.first;
      expect(l1.isWriteLock, isTrue);
      expect(l1.lockScope, LockScope.exclusive);
      final l2 = locks.value!.last;
      expect(l2.isWriteLock, isTrue);
      expect(l2.lockScope, LockScope.shared);
    });
  });
}
