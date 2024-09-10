// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';
import 'dart:io';

import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/dav.dart';
import 'package:simple_webdav_client/utils.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import '../server.dart';

final class Owner implements ToXmlCapable {
  final Uri url;

  const Owner(this.url);

  @override
  void toXml(XmlBuilder context, NamespaceManager nsmgr) {
    context.element("href", namespace: kDavNamespaceUrlStr, nest: () {
      context.text(url.toString());
    });
  }
}

void main() {
  group("test lock", () {
    late final BaseRespResultParser resultParser;
    late final TestUsagedHttpServer server;
    late WebDavStdClient client;
    late Uri addr;

    setUpAll(() async {
      server = TestUsagedHttpServer();
      await server.open();

      addr = Uri(scheme: 'http', host: "localhost", port: server.bindPort);

      final activeLockParser = BaseActiveLockElementParser(
          lockScopeParser: BaseLockScopeElementParser(),
          lockTypeParser: BaseWriteLockElementParser(),
          depthParser: DepthElementParser(),
          ownerParser: BaseHrefElementParser(),
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

      resultParser = BaseRespResultParser(
          singleResDecoder: BaseRespSingleResultParser(
              parserManger:
                  WebDavResposneDataParserManger(parsers: propParsers)),
          multiResDecoder: kStdResponseResultParser.multiResDecoder);
    });

    tearDownAll(() async {
      await server.close();
    });

    setUp(() {
      client = WebDavClient.std();
      server.expectedResponse = null;
      server.serverSideChecker = null;
    });

    tearDown(() {
      client.close();
    });

    test(
        "RFC4918 9.10.7 Simple Lock Request, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.10.7",
        () async {
      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:lockinfo xmlns:a1="DAV:">
  <a1:lockscope>
    <a1:exclusive/>
  </a1:lockscope>
  <a1:locktype>
    <a1:write/>
  </a1:locktype>
  <a1:owner>
    <a1:href>http://example.org/~ejw/contact.html</a1:href>
  </a1:owner>
</a1:lockinfo>
'''
          .trim();

      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<D:prop xmlns:D="DAV:">
  <D:lockdiscovery>
    <D:activelock>
      <D:locktype><D:write/></D:locktype>
      <D:lockscope><D:exclusive/></D:lockscope>
      <D:depth>infinity</D:depth>
      <D:owner>
        <D:href>http://example.org/~ejw/contact.html</D:href>
      </D:owner>
      <D:timeout>Second-604800</D:timeout>
      <D:locktoken>
          <D:href>urn:uuid:e71d4fae-5dec-22d6-fea5-00a0c91e6be4</D:href>
      </D:locktoken>
      <D:lockroot>
        <D:href>http://example.com/workspace/webdav/proposal.doc</D:href>
      </D:lockroot>
    </D:activelock>
  </D:lockdiscovery>
</D:prop>
'''
          .trim();
      addr = Uri(
          scheme: addr.scheme,
          host: addr.host,
          port: addr.port,
          path: "/workspace/webdav/proposal.doc");
      final lockToken = "urn:uuid:e71d4fae-5dec-22d6-fea5-00a0c91e6be4";

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.ok;
        event.response.headers.contentType =
            ContentType.parse('application/xml; charset="utf-8"');
        event.response.headers.add("Lock-Token", "<$lockToken>");
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      final uri = Uri(
          scheme: addr.scheme,
          host: addr.host,
          port: addr.port,
          path: "/workspace/webdav/");
      final credentials = HttpClientDigestCredentials("ejw", "");
      final realm = "ejw@example.com";
      client.addCredentials(uri, realm, credentials);

      final request = await client
          .dispatch(addr, responseResultParser: resultParser)
          .createLock(
              info: LockInfo(
                  lockScope: LockScope.exclusive,
                  owner:
                      Owner(Uri.parse("http://example.org/~ejw/contact.html"))),
              timeout: DavTimeout([double.infinity, 4100000000]));

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.headers["Depth"]!.first, "0");
        expect(event.headers.contentType.toString(),
            equals(XmlContentType.applicationXml.toString()));
        expect(event.headers["Timeout"]!.first,
            equals("Infinite, Second-4100000000"));
        final body = await utf8.decodeStream(event);
        expect(XmlDocument.parse(body).toXmlString(pretty: true), requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final response = await request.close();
      expect(response.body, isNull);
      expect(response.response.headers["Lock-Token"]!.first, "<$lockToken>");
      final result = await response.parse();
      expect(response.body, equals(responseBody));
      expect(result!.length, 1);
      final resource = result.first;
      expect(resource.status, HttpStatus.ok);
      expect(resource.path, addr);
      expect(resource.desc, isNull);
      expect(resource.error, isNull);
      expect(resource.props.length, 1);
      final locks =
          resource.props.first as WebDavStdResourceProp<LockDiscovery<Uri>>;
      expect(locks.status, HttpStatus.ok);
      expect(locks.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(locks.desc, isNull);
      expect(locks.error, isNull);
      expect(locks.value!.length, 1);
      final lock = locks.value!.first;
      expect(lock.isWriteLock, isTrue);
      expect(lock.lockScope, LockScope.exclusive);
      expect(lock.depth, Depth.all);
      expect(lock.owner,
          equals(Uri.parse("http://example.org/~ejw/contact.html")));
      expect(lock.timeout, equals(604800));
      expect(lock.lockToken, equals(Uri.parse(lockToken)));
      expect(
          lock.lockRoot,
          equals(
              Uri.parse("http://example.com/workspace/webdav/proposal.doc")));
    });
    test(
        "RFC4918 9.10.8 Refreshing a Write Lock, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.10.8",
        () async {
      final requestBody = '';
      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<D:prop xmlns:D="DAV:">
<D:lockdiscovery>
  <D:activelock>
    <D:locktype><D:write/></D:locktype>
    <D:lockscope><D:exclusive/></D:lockscope>
    <D:depth>infinity</D:depth>
    <D:owner>
      <D:href>http://example.org/~ejw/contact.html</D:href>
    </D:owner>
    <D:timeout>Second-604800</D:timeout>
    <D:locktoken>
      <D:href>urn:uuid:e71d4fae-5dec-22d6-fea5-00a0c91e6be4</D:href>
    </D:locktoken>
    <D:lockroot>
      <D:href>http://example.com/workspace/webdav/proposal.doc</D:href>
    </D:lockroot>
  </D:activelock>
</D:lockdiscovery>
</D:prop>
'''
          .trim();
      addr = Uri(
          scheme: addr.scheme,
          host: addr.host,
          port: addr.port,
          path: "/workspace/webdav/proposal.doc");
      final lockToken = "urn:uuid:e71d4fae-5dec-22d6-fea5-00a0c91e6be4";

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.ok;
        event.response.headers.contentType =
            ContentType.parse('application/xml; charset="utf-8"');
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      final uri = Uri(
          scheme: addr.scheme,
          host: addr.host,
          port: addr.port,
          path: "/workspace/webdav/");
      final credentials = HttpClientDigestCredentials("ejw", "");
      final realm = "ejw@example.com";
      client.addCredentials(uri, realm, credentials);

      final request = await client
          .dispatch(addr, responseResultParser: resultParser)
          .renewLock(
              condition: IfOr.notag([
                IfAnd.notag([IfCondition.token(Uri.parse(lockToken))])
              ]),
              timeout: DavTimeout([double.infinity, 4100000000]));

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.headers["Depth"], isNull);
        expect(event.headers["If"]!.first,
            "(<urn:uuid:e71d4fae-5dec-22d6-fea5-00a0c91e6be4>)");
        expect(event.headers["Timeout"]!.first,
            equals("Infinite, Second-4100000000"));
        expect(event.headers.contentType, isNull);
        final body = await utf8.decodeStream(event);
        expect(body, requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final response = await request.close();
      expect(response.body, isNull);
      expect(response.response.headers["Lock-Token"], isNull);
      final result = await response.parse();
      expect(response.body, equals(responseBody));
      expect(result!.length, 1);
      final resource = result.first;
      expect(resource.status, HttpStatus.ok);
      expect(resource.path, addr);
      expect(resource.desc, isNull);
      expect(resource.error, isNull);
      expect(resource.props.length, 1);
      final locks =
          resource.props.first as WebDavStdResourceProp<LockDiscovery<Uri>>;
      expect(locks.status, HttpStatus.ok);
      expect(locks.namespace, equals(Uri.parse(kDavNamespaceUrlStr)));
      expect(locks.desc, isNull);
      expect(locks.error, isNull);
      expect(locks.value!.length, 1);
      final lock = locks.value!.first;
      expect(lock.isWriteLock, isTrue);
      expect(lock.lockScope, LockScope.exclusive);
      expect(lock.depth, Depth.all);
      expect(lock.owner,
          equals(Uri.parse("http://example.org/~ejw/contact.html")));
      expect(lock.timeout, equals(604800));
      expect(lock.lockToken, equals(Uri.parse(lockToken)));
      expect(
          lock.lockRoot,
          equals(
              Uri.parse("http://example.com/workspace/webdav/proposal.doc")));
    });
    test(
        "RFC4918 9.10.9 Multi-Resource Lock Request, "
        "see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.10.9",
        () async {
      final requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<a1:lockinfo xmlns:a1="DAV:">
  <a1:lockscope>
    <a1:exclusive/>
  </a1:lockscope>
  <a1:locktype>
    <a1:write/>
  </a1:locktype>
  <a1:owner>
    <a1:href>http://example.org/~ejw/contact.html</a1:href>
  </a1:owner>
</a1:lockinfo>
'''
          .trim();

      final responseBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>http://example.com/webdav/secret</D:href>
    <D:status>HTTP/1.1 403 Forbidden</D:status>
  </D:response>
  <D:response>
    <D:href>http://example.com/webdav/</D:href>
    <D:status>HTTP/1.1 424 Failed Dependency</D:status>
  </D:response>
</D:multistatus>
'''
          .trim();
      addr = Uri(
          scheme: addr.scheme,
          host: addr.host,
          port: addr.port,
          path: "/webdav/");

      Future<bool> expectedResponse(HttpRequest event) async {
        event.response.statusCode = HttpStatus.multiStatus;
        event.response.headers.contentType =
            ContentType.parse('application/xml; charset="utf-8"');
        event.response.contentLength = responseBody.length;
        event.response.write(responseBody);
        return true;
      }

      server.expectedResponse = expectedResponse;

      final uri = Uri(
          scheme: addr.scheme,
          host: addr.host,
          port: addr.port,
          path: "/workspace/webdav/");
      final credentials = HttpClientDigestCredentials("ejw", "");
      final realm = "ejw@example.com";
      client.addCredentials(uri, realm, credentials);

      final request = await client
          .dispatch(addr, responseResultParser: resultParser)
          .createDirLock(
              info: LockInfo(
                  lockScope: LockScope.exclusive,
                  owner:
                      Owner(Uri.parse("http://example.org/~ejw/contact.html"))),
              timeout: DavTimeout([double.infinity, 4100000000]));

      Future<void> serverSideChecker(HttpRequest event) async {
        expect(event.headers["Depth"]!.first, "infinity");
        expect(event.headers.contentType.toString(),
            equals(XmlContentType.applicationXml.toString()));
        expect(event.headers["Timeout"]!.first,
            equals("Infinite, Second-4100000000"));
        final body = await utf8.decodeStream(event);
        expect(XmlDocument.parse(body).toXmlString(pretty: true), requestBody);
      }

      server.serverSideChecker = serverSideChecker;

      final response = await request.close();
      expect(response.body, isNull);
      expect(response.response.headers["Lock-Token"], isNull);
      final result = await response.parse();
      expect(response.body, equals(responseBody));
      expect(result!.length, 2);
      final r1 = result.first;
      expect(r1.path, Uri.parse("http://example.com/webdav/secret"));
      expect(r1.status, HttpStatus.forbidden);
      expect(r1.props, isEmpty);
      expect(r1.desc, isNull);
      expect(r1.error, isNull);
      final r2 = result.last;
      expect(r2.path, Uri.parse("http://example.com/webdav/"));
      expect(r2.status, HttpStatus.failedDependency);
      expect(r2.props, isEmpty);
      expect(r2.desc, isNull);
      expect(r2.error, isNull);
    });
  });
}
