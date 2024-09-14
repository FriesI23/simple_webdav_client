// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';

import 'package:xml/xml.dart';

import '../codec/timeout.dart';
import '../const.dart';
import '../dav/element.dart';
import '../error.dart';
import '../io.dart';
import '../utils.dart';
import 'depth.dart';
import 'error.dart';
import 'parser_mgr.dart';
import 'prop.dart';
import 'resource.dart';
import 'response.dart';

class ResponseResultParserParam {
  final Uri path;
  final int status;
  final HttpHeaders headers;
  final String data;

  const ResponseResultParserParam({
    required this.path,
    required this.status,
    required this.headers,
    required this.data,
  });
}

/// Parser used for the response body, see [WebDavStdResponse.parse].
///
/// Three parsers are implemented by default:
///
/// - [BaseRespResultParser]
/// - [BaseRespSingleResultParser]
/// - [BaseRespMultiResultParser]
typedef ResponseResultParser<O extends WebDavStdResResultView>
    = Converter<ResponseResultParserParam, O>;

/// Parser used for <error> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.5].
///
/// There's a parser implemented by default:
///
/// - [BaseErrorElementParser]
///
/// ```bnf
/// <!ELEMENT error ANY >
/// ```
typedef ErrorElementParser = Converter<XmlElement, WebDavStdResError?>;

/// Parser used for <prop> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.18]
///
/// There's a parser implemented by default:
///
/// - [DateTimePropParser]
/// - [HttpDatePropParser]
/// - [StringPropParser]
/// - [NumPropParser]
/// - [ContentTypePropParser]
/// - [ResourceTypePropParser]
/// - [SupportedLockPropParser]
/// - [LockDiscoveryPropParser]
///
/// ```bnf
/// <!ELEMENT prop ANY >
/// ```
typedef PropElementParser<T extends WebDavStdResourceProp> = Converter<
    ({XmlElement node, int status, WebDavStdResError? error, String? desc}),
    T?>;

/// Parser used for <propstat> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.22].
///
/// There's a parser implemented by default:
///
/// - [BasePropstatElementParser]
///
/// ```bnf
/// <!ELEMENT propstat (prop, status, error?, responsedescription?) >
/// ```
typedef PropstatElementParser = Converter<
    ({XmlElement node, WebDavStdResource resource}),
    Iterable<WebDavStdResourceProp>>;

/// Parser used for <response> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.24].
///
/// There's a parser implemented by default:
///
/// - [BaseResponseElementParser]
///
/// ```bnf
/// <!ELEMENT response (href, ((href*, status)|(propstat+)),
///                     error?, responsedescription? , location?) >
/// ```
typedef ResponseElementParser
    = Converter<XmlElement, Iterable<WebDavStdResource>>;

/// Parser used for <multistatus> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.16].
///
/// There's a parser implemented by default:
///
/// - [BaseMultistatusElementParser]
///
/// ```bnf
/// <!ELEMENT multistatus (response*, responsedescription?)  >
/// ```
typedef MultiStatusElementParser
    = Converter<XmlElement, WebDavStdResResultView?>;

/// Parser used for <href> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.7].
///
/// There're two parsers implemented by default:
///
/// - [BaseHrefElementParser]
/// - [NestedHrefElementParser]
///
/// ```bnf
/// <!ELEMENT multistatus (response*, responsedescription?)  >
/// ```
typedef HrefElementParser = Converter<XmlElement, Uri?>;

/// Parser used for <status> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.28].
///
/// There's a parser implemented by default:
///
/// - [BaseHttpStatusElementParser]
///
/// ```bnf
/// ; value: status-line [RFC2616#6.1]
/// <!ELEMENT status (#PCDATA) >
/// ```
typedef HttpStatusElementParser = Converter<XmlElement, int?>;

/// Parser used for <lockscope> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.13].
///
/// There's a parser implemented by default:
///
/// - [BaseLockScopeElementParser]
///
/// ```bnf
/// <!ELEMENT lockscope (exclusive | shared) >
/// ```
typedef LockScopeElementParser = Converter<XmlElement, LockScope?>;

/// Parser used for <locktype> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.15].
///
/// There's a parser implemented by default:
///
/// - [BaseWriteLockElementParser]
///
/// ```bnf
/// <!ELEMENT locktype (write) >
/// ```
typedef WriteLockElementParser = Converter<XmlElement, bool?>;

/// Parser used for <lockentry> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.10].
///
/// There's a parser implemented by default:
///
/// - [BaseLockEntryElementParser]
///
/// ```bnf
/// <!ELEMENT lockentry (lockscope, locktype) >
/// ```
typedef LockEntryElementParser = Converter<XmlElement, LockEntry?>;

/// Parser used for <activelock> element,
/// see [https://datatracker.ietf.org/doc/html/rfc4918#section-14.1].
///
/// There's a parser implemented by default:
///
/// - [BaseActiveLockElementParser]
///
/// ```bnf
/// <!ELEMENT activelock (lockscope, locktype, depth, owner?, timeout?,
///           locktoken?, lockroot)>
/// ```
typedef ActiveLockElementParser<O> = Converter<XmlElement, ActiveLock<O>?>;

/// Mixed parser, supports both single resource and multistatus XML responses.
final class BaseRespResultParser
    extends ResponseResultParser<WebDavStdResResultView> {
  final ResponseResultParser<WebDavStdResResultView> singleResDecoder;
  final ResponseResultParser<WebDavStdResResultView> multiResDecoder;

  const BaseRespResultParser({
    required this.singleResDecoder,
    required this.multiResDecoder,
  });

  @override
  WebDavStdResResultView convert(ResponseResultParserParam input) {
    final status = input.status;
    switch (status) {
      case (HttpStatus.multiStatus):
        return multiResDecoder.convert(input);
      default:
        return singleResDecoder.convert(input);
    }
  }
}

/// Single resource response parser, supports empty body or
/// a root element with 'error', 'propstat', or 'prop'.
final class BaseRespSingleResultParser
    extends ResponseResultParser<WebDavStdResResultView> {
  final WebDavResposneDataParserManger parserManger;

  const BaseRespSingleResultParser({
    required this.parserManger,
  });

  (WebDavStdResError?, String?, Iterable<WebDavStdResourceProp>) convertProp(
      XmlElement root, WebDavStdResource resource) {
    switch ((root.namespaceUri, root.localName)) {
      case (null, "error"):
      case (kDavNamespaceUrlStr, "error"):
        final error = parserManger.error?.convert(root);
        return (error, null, const []);
      case (kDavNamespaceUrlStr, "propstat"):
        final props =
            parserManger.propstat?.convert((node: root, resource: resource));
        if (props == null) break;
        return (null, null, props);
      case (kDavNamespaceUrlStr, "prop"):
        final props = root
            .findElements("*", namespace: root.namespaceUri)
            .map((e) => parserManger
                    .fetchPropParser(e.localName, e.namespaceUri)
                    ?.convert((
                  node: e,
                  status: resource.status,
                  error: resource.error,
                  desc: resource.desc
                )))
            .whereNotNull();
        return (null, null, props);
    }
    return (null, null, const []);
  }

  WebDavStdResource convertResource(
    XmlElement? root, {
    required Uri path,
    required int status,
    required Uri? redirect,
  }) {
    final WebDavStdResError? error;
    final String? desc;
    final Iterable<WebDavStdResourceProp> props;

    switch ((root?.namespaceUri, root?.localName)) {
      case (kDavNamespaceUrlStr, "response"):
        final resource = parserManger.response?.convert(root!).firstOrNull;
        error = resource?.error;
        desc = resource?.desc;
        props = resource?.props ?? const [];
      case (_, _):
        final resourceTemplate =
            WebDavStdResource(path: path, status: status, redirect: redirect);
        (error, desc, props) = root != null
            ? convertProp(root, resourceTemplate)
            : const (null, null, <WebDavStdResourceProp>[]);
    }

    return WebDavStdResource.fromProps(
        path: path,
        status: status,
        error: error,
        desc: desc,
        redirect: redirect,
        props: props);
  }

  @override
  WebDavStdResResultView convert(ResponseResultParserParam input) {
    final redirect = input.headers.value(HttpHeaders.locationHeader);
    final doc = (input.headers.contentType?.isXml ?? false)
        ? XmlDocument.parse(input.data)
        : null;
    return WebDavStdResponseResult()
      ..add(convertResource(doc?.rootElement,
          path: input.path,
          status: input.status,
          redirect: redirect != null ? Uri.tryParse(redirect) : null));
  }
}

final class BaseRespMultiResultParser
    extends ResponseResultParser<WebDavStdResResultView> {
  final WebDavResposneDataParserManger parserManger;

  const BaseRespMultiResultParser({
    required this.parserManger,
  });

  @override
  WebDavStdResResultView convert(ResponseResultParserParam input) {
    final doc = (input.headers.contentType?.isXml ?? false)
        ? XmlDocument.parse(input.data)
        : null;
    final multistatusParser = parserManger.multistatus;
    return doc != null && multistatusParser != null
        ? multistatusParser.convert(doc.rootElement) ??
            WebDavStdResponseResult()
        : WebDavStdResponseResult();
  }
}

/// Parser for [multistatus] element, required [ResponseElementParser].
///
/// ```xml
/// <multistatus>
///   <response> ... </response>
///   <response> ... </response>
/// </multistatus>
/// ```
final class BaseMultistatusElementParser extends MultiStatusElementParser {
  final ResponseElementParser _responseParser;

  const BaseMultistatusElementParser({
    required ResponseElementParser responseParser,
  }) : _responseParser = responseParser;

  @override
  WebDavStdResResultView convert(XmlElement input) {
    return WebDavStdResponseResult.fromMap(
      Map.fromEntries(input
          .findElements(WebDavElementNames.response,
              namespace: input.namespaceUri)
          .map((e) => _responseParser.convert(e))
          .expand((e) => e)
          .map((e) => MapEntry(e.path, e))),
    );
  }
}

/// Parser for [response] element, required parsers for child elements.
///
/// for single resource:
/// ```xml
/// <response>
///   <href> ... </href>
///   <propstat> ... </propstat>
///   <propstat> ... </propstat>
///   <error> ... </error>
///   <location> ... </location>
/// </response>
/// ```
///
/// for multi resources:
/// ```xml
/// <response>
///   <href> ... </href>
///   <href> ... </href>
///   <status> ... </status>
///   <error> ... </error>
///   <location> ... </location>
/// </response>
/// ```
final class BaseResponseElementParser extends ResponseElementParser {
  final HrefElementParser hrefParser;
  final HttpStatusElementParser statusParser;
  final PropstatElementParser propstatParser;
  final ErrorElementParser? errorParser;
  final HrefElementParser? locationParser;

  const BaseResponseElementParser({
    required this.hrefParser,
    required this.statusParser,
    required this.propstatParser,
    required this.errorParser,
    required this.locationParser,
  });

  @override
  Iterable<WebDavStdResource> convert(XmlElement input) {
    final pathNode = input.getElement(WebDavElementNames.href,
        namespace: input.namespaceUri);
    if (pathNode == null) {
      throw WebDavParserDataError(
          "response node must contain ${WebDavElementNames.href}");
    }
    final statusNode = input.getElement(WebDavElementNames.status,
        namespace: input.namespaceUri);
    final errorNode = input.getElement(WebDavElementNames.error,
        namespace: input.namespaceUri);
    final locationNode = input.getElement(WebDavElementNames.location,
        namespace: input.namespaceUri);
    final descNode = input.getElement(WebDavElementNames.responsedescription,
        namespace: input.namespaceUri);

    final status = statusNode != null
        ? statusParser.convert(statusNode)
        : HttpStatus.multiStatus;
    final error = errorNode != null ? errorParser?.convert(errorNode) : null;
    final redirect =
        locationNode != null ? locationParser?.convert(locationNode) : null;
    final desc = descNode?.innerText.trim();

    switch (status) {
      case null:
        return const [];
      case HttpStatus.multiStatus:
        final path = hrefParser.convert(pathNode);
        if (path == null) return const [];
        final resourceTemplate =
            WebDavStdResource(path: path, status: status, redirect: redirect);
        return [
          WebDavStdResource.fromProps(
            path: path,
            status: status,
            error: error,
            redirect: redirect,
            desc: desc,
            props: input
                .findElements(WebDavElementNames.propstat,
                    namespace: input.namespaceUri)
                .map((e) => propstatParser
                    .convert((node: e, resource: resourceTemplate)))
                .expand((e) => e),
          )
        ];
      default:
        return input
            .findElements(WebDavElementNames.href,
                namespace: input.namespaceUri)
            .map((e) => hrefParser.convert(e))
            .whereNotNull()
            .map((e) => WebDavStdResource(
                path: e,
                status: status,
                error: error,
                redirect: redirect,
                desc: desc));
    }
  }
}

/// Parser for [href] element.
///
/// ```xml
/// <href>http://example.com</href>
/// ```
final class BaseHrefElementParser extends HrefElementParser {
  const BaseHrefElementParser();

  @override
  Uri? convert(XmlElement input) {
    return Uri.tryParse(input.innerText.trim());
  }
}

/// Parser for nested [href] elements.
///
/// ```xml
/// <location><href>http://example.com</href></location>
/// ```
class NestedHrefElementParser extends HrefElementParser {
  final HrefElementParser _hrefParser;

  const NestedHrefElementParser({
    required HrefElementParser hrefParser,
  }) : _hrefParser = hrefParser;

  @override
  Uri? convert(XmlElement input) {
    final hrefNode = input.getElement(WebDavElementNames.href,
        namespace: input.namespaceUri);
    return hrefNode != null ? _hrefParser.convert(hrefNode) : null;
  }
}

/// Parser for [error] element.
///
/// ```xml
/// <error> ... </error>
/// ```
final class BaseErrorElementParser extends ErrorElementParser {
  const BaseErrorElementParser();

  @override
  WebDavStdResError convert(XmlElement input) {
    return WebDavStdResError("",
        conditions: input
            .findElements("*", namespace: input.namespaceUri)
            .map((e) => StdResErrorCond.fromName(e.localName))
            .whereNotNull()
            .toList());
  }
}

/// Parser for [status] element.
///
/// ```xml
/// <status> ... </status>
/// ```
final class BaseHttpStatusElementParser extends HttpStatusElementParser {
  const BaseHttpStatusElementParser();

  @override
  int? convert(XmlElement input) {
    return int.tryParse(input.innerText.trim().split(" ")[1]);
  }
}

/// Parser for the [propstat] element, requires parsers for [status],
/// [error], and [prop].
/// Parsers for [prop] are specifically managed by [BasePropstatElementParser].
///
/// ```xml
/// <propstat>
///   <error> ... </error>
///   <status> ... </status>
///   <prop>
///     <p1/><p2/><p3/>
///   </prop>
/// </propstat>
/// ```
final class BasePropstatElementParser extends PropstatElementParser {
  final HttpStatusElementParser _statusParser;
  final ErrorElementParser? _errorParser;
  final WebDavResposneDataParserManger _parserManager;

  const BasePropstatElementParser({
    required WebDavResposneDataParserManger parserManger,
    required HttpStatusElementParser statusParser,
    required ErrorElementParser? errorParser,
  })  : _parserManager = parserManger,
        _errorParser = errorParser,
        _statusParser = statusParser;

  @override
  Iterable<WebDavStdResourceProp> convert(
      ({XmlElement node, WebDavStdResource resource}) input) {
    final statusNode = input.node.getElement(WebDavElementNames.status,
        namespace: input.node.namespaceUri);
    final errorNode = input.node.getElement(WebDavElementNames.error,
        namespace: input.node.namespaceUri);
    final propNode = input.node.getElement(WebDavElementNames.prop,
        namespace: input.node.namespaceUri);
    final descNode = input.node.getElement(
        WebDavElementNames.responsedescription,
        namespace: input.node.namespaceUri);
    final status =
        statusNode != null ? _statusParser.convert(statusNode) : null;
    if (status == null && input.resource.status == HttpStatus.multiStatus) {
      throw WebDavParserDataError("Can't parse status", data: input.node);
    }
    final error = errorNode != null ? _errorParser?.convert(errorNode) : null;
    final desc = descNode?.innerText;
    if (propNode == null) return const [];
    return propNode.childElements
        .map((e) => _parserManager
                .fetchPropParser<WebDavStdResourceProp>(
                    e.localName, e.namespaceUri)
                ?.convert((
              node: e,
              status: status ?? input.resource.status,
              error: error ?? input.resource.error,
              desc: desc ?? input.resource.desc,
            )))
        .whereNotNull();
  }
}

abstract class _PropElementParser<T>
    extends PropElementParser<WebDavStdResourceProp<T>> {
  const _PropElementParser();

  T? convertValue(XmlElement node);

  @override
  WebDavStdResourceProp<T> convert(
      ({
        String? desc,
        WebDavStdResError? error,
        XmlElement node,
        int status
      }) input) {
    final nsurl = input.node.namespaceUri;
    return WebDavStdResourceProp<T>(
      name: input.node.localName.trim(),
      namespace: nsurl != null ? Uri.tryParse(nsurl) : null,
      status: input.status,
      desc: input.desc,
      error: input.error,
      value: convertValue(input.node),
      lang: input.node.getAttribute(kXmlLangAttrName),
    );
  }
}

/// Parser for [RFC3339] defined properties.
///
/// - [cretiondata](https://datatracker.ietf.org/doc/html/rfc4918#section-15.1)
final class DateTimePropParser extends _PropElementParser<DateTime> {
  const DateTimePropParser();

  @override
  DateTime? convertValue(XmlElement node) =>
      DateTime.tryParse(node.innerText.trim());
}

/// Parser for [RFC1123] defined properties.
///
/// - [getlastmodified](https://datatracker.ietf.org/doc/html/rfc4918#section-15.7)
final class HttpDatePropParser extends _PropElementParser<DateTime> {
  const HttpDatePropParser();

  @override
  DateTime? convertValue(XmlElement node) {
    final str = node.innerText.trim();
    return str.isNotEmpty ? HttpDate.parse(str) : null;
  }
}

/// Parser for string properties.
///
/// - [displayname](https://datatracker.ietf.org/doc/html/rfc4918#section-15.2)
/// - [getcontentlanguage](https://datatracker.ietf.org/doc/html/rfc4918#section-15.3)
/// - [getetag](https://datatracker.ietf.org/doc/html/rfc4918#section-15.6)
final class StringPropParser extends _PropElementParser<String> {
  const StringPropParser();

  @override
  String convertValue(XmlElement node) => node.innerText.trim();
}

/// Parser for number properties.
///
/// - [getcontentlength](https://datatracker.ietf.org/doc/html/rfc4918#section-15.4)
final class NumPropParser extends _PropElementParser<num> {
  const NumPropParser();

  @override
  num? convertValue(XmlElement node) => num.tryParse(node.innerText.trim());
}

/// Parser for html content type.
///
/// - [getcontenttype](https://datatracker.ietf.org/doc/html/rfc4918#section-15.5)
final class ContentTypePropParser extends _PropElementParser<ContentType> {
  const ContentTypePropParser();

  @override
  ContentType? convertValue(XmlElement node) {
    final str = node.innerText.trim();
    return str.isNotEmpty ? ContentType.parse(str) : null;
  }
}

/// Parser for resource types.
///
/// - [resourcetype](https://datatracker.ietf.org/doc/html/rfc4918#section-15.9)
final class ResourceTypePropParser extends _PropElementParser<ResourceTypes> {
  const ResourceTypePropParser();

  @override
  ResourceTypes convertValue(XmlElement node) =>
      ResourceTypes(node.childElements
          .map((e) => (name: e.localName, ns: e.namespaceUri))
          .toList());
}

/// Parser for [lockscope] element.
///
/// ```xml
/// <lockscope><shared/></lockscope>
/// ```
final class BaseLockScopeElementParser extends LockScopeElementParser {
  const BaseLockScopeElementParser();

  @override
  LockScope? convert(XmlElement input) {
    final scopeNode = input.getElement("*", namespace: input.namespaceUri);
    if (scopeNode == null) return null;
    return LockScope.fromName(scopeNode.localName.toLowerCase());
  }
}

/// Parser for [locktype] element.
///
/// ```xml
/// <locktype><write/></locktype>
/// ```
final class BaseWriteLockElementParser extends WriteLockElementParser {
  const BaseWriteLockElementParser();

  @override
  bool convert(XmlElement input) =>
      input.getElement("write", namespace: input.namespaceUri) != null;
}

/// Parser for supported locks.
///
/// - [supportedlock](https://datatracker.ietf.org/doc/html/rfc4918#section-15.10)
final class SupportedLockPropParser extends _PropElementParser<SupportedLock> {
  final LockEntryElementParser pieceParser;

  const SupportedLockPropParser({required this.pieceParser});

  @override
  SupportedLock convertValue(XmlElement node) => SupportedLock.from(node
      .findElements(WebDavElementNames.lockentry, namespace: node.namespaceUri)
      .map((e) => pieceParser.convert(e))
      .whereNotNull()
      .toList());
}

/// Parser for [lockentry] element, required parsers for [lockscope] and
/// [locktype].
///
/// ```xml
/// <lockentry>
///   <lockscope> ... </lockscope>
///   <locktype> ... </locktype>
/// </lockentry>
/// ```
final class BaseLockEntryElementParser extends LockEntryElementParser {
  final LockScopeElementParser lockScopeParser;
  final WriteLockElementParser lockTypeParser;

  const BaseLockEntryElementParser(
      {required this.lockScopeParser, required this.lockTypeParser});

  @override
  LockEntry? convert(XmlElement input) {
    final lockScopeNode = input.getElement(WebDavElementNames.lockscope,
        namespace: input.namespaceUri);
    final lockTypeNode = input.getElement(WebDavElementNames.locktype,
        namespace: input.namespaceUri);
    if (!(lockScopeNode != null && lockTypeNode != null)) return null;
    final lockScope = lockScopeParser.convert(lockScopeNode);
    if (lockScope == null) {
      throw WebDavParserDataError("Can't parse ${WebDavElementNames.lockscope}",
          data: input);
    }
    return LockEntry(
        lockScope: lockScope,
        isWriteLock: lockTypeParser.convert(lockTypeNode) ?? false);
  }
}

/// Parser for lock discovery.
///
/// - [lockdiscovery](https://datatracker.ietf.org/doc/html/rfc4918#section-15.8)
final class LockDiscoveryPropParser<O>
    extends _PropElementParser<LockDiscovery<O>> {
  final ActiveLockElementParser<O> pieceParser;

  const LockDiscoveryPropParser({required this.pieceParser});

  @override
  LockDiscovery<O> convertValue(XmlElement node) => LockDiscovery.from(node
      .findElements(WebDavElementNames.activelock, namespace: node.namespaceUri)
      .map((e) => pieceParser.convert(e))
      .whereNotNull()
      .toList());
}

/// Parser for [activelock] element, required parsers for [lockscope],
/// [locktype], [depth], [owner], [timeout], [locktoken] and [lockroot].
///
/// ```xml
/// <activelock>
///   <lockscope> ... </lockscope>
///   <locktype> ... </locktype>
///   <depth> ... </depth>
///   <owner> ... </owner>
///   <timeout> ... </timeout>
///   <locktoken> ... </locktoken>
///   <lockroot> ... </lockroot>
/// </activelock>
/// ```
final class BaseActiveLockElementParser<O> extends ActiveLockElementParser<O> {
  final LockScopeElementParser lockScopeParser;
  final WriteLockElementParser lockTypeParser;
  final Converter<XmlElement, Depth?> depthParser;
  final Converter<XmlElement, O?>? ownerParser;
  final Converter<XmlElement, double?>? timeoutParser;
  final NestedHrefElementParser? lockTokenParser;
  final NestedHrefElementParser lockRootParser;

  const BaseActiveLockElementParser({
    required this.lockScopeParser,
    required this.lockTypeParser,
    required this.depthParser,
    required this.ownerParser,
    required this.timeoutParser,
    required this.lockTokenParser,
    required this.lockRootParser,
  });

  @override
  ActiveLock<O>? convert(XmlElement input) {
    final lockScopeNode = input.getElement(WebDavElementNames.lockscope,
        namespace: input.namespaceUri);
    final lockTypeNode = input.getElement(WebDavElementNames.locktype,
        namespace: input.namespaceUri);
    final depthNode = input.getElement(WebDavElementNames.depth,
        namespace: input.namespaceUri);
    final ownerNode = input.getElement(WebDavElementNames.owner,
        namespace: input.namespaceUri);
    final timeoutNode = input.getElement(WebDavElementNames.timeout,
        namespace: input.namespaceUri);
    final lockTokenNode = input.getElement(WebDavElementNames.locktoken,
        namespace: input.namespaceUri);
    final lockRootNode = input.getElement(WebDavElementNames.lockroot,
        namespace: input.namespaceUri);
    if (!(lockScopeNode != null && lockTypeNode != null && depthNode != null)) {
      return null;
    }
    final lockScope = lockScopeParser.convert(lockScopeNode);
    if (lockScope == null) {
      throw WebDavParserDataError("Can't parse ${WebDavElementNames.lockscope}",
          data: input);
    }
    final depth = depthParser.convert(depthNode);
    if (depth == null) {
      throw WebDavParserDataError("Can't parse ${WebDavElementNames.depth}",
          data: input);
    }
    return ActiveLock(
      lockScope: lockScope,
      isWriteLock: lockTypeParser.convert(lockTypeNode) ?? false,
      depth: depth,
      owner: ownerNode != null ? ownerParser?.convert(ownerNode) : null,
      timeout: timeoutNode != null ? timeoutParser?.convert(timeoutNode) : null,
      lockToken: lockTokenNode != null
          ? lockTokenParser?.convert(lockTokenNode)
          : null,
      lockRoot:
          lockRootNode != null ? lockRootParser.convert(lockRootNode) : null,
    );
  }
}

/// Parser for [depth] element.
///
/// ```xml
/// <depth> 1 </depth>
/// ```
final class DepthElementParser extends Converter<XmlElement, Depth?> {
  const DepthElementParser();

  @override
  Depth? convert(XmlElement input) =>
      Depth.fromName(input.innerText.trim().toLowerCase());
}

/// Parser for [timeout] element.
///
/// ```xml
/// <timeout> Second-123 </timeout>
/// ```
final class TimeoutElementParser extends Converter<XmlElement, double?> {
  const TimeoutElementParser();

  @override
  double? convert(XmlElement input) {
    try {
      return const TimeTypeCodec().decode(input.innerText.trim());
    } catch (_) {
      return null;
    }
  }
}
