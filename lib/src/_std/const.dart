// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:convert';

import '../const.dart';
import '../dav/element.dart';
import 'decoder_mgr.dart';
import 'parser.dart';
import 'parser_mgr.dart';

const kStdDecoderManager = ResponseBodyDecoderManager(decoders: {});

const kStdElementParserManager = WebDavResposneDataParserManger(parsers: {
  (name: WebDavElementNames.error, ns: kDavNamespaceUrlStr): _errorParser,
  (name: WebDavElementNames.href, ns: kDavNamespaceUrlStr): _hrefParser,
  (name: WebDavElementNames.location, ns: kDavNamespaceUrlStr):
      _nestedHrefParser,
  (name: WebDavElementNames.multistatus, ns: kDavNamespaceUrlStr):
      _multistatusParser,
  (name: WebDavElementNames.propstat, ns: kDavNamespaceUrlStr): _propstatParser,
  (name: WebDavElementNames.response, ns: kDavNamespaceUrlStr): _responseParser,
  (name: WebDavElementNames.status, ns: kDavNamespaceUrlStr): _statusParser,
  ..._propParsers,
});

const kStdPropParserManager =
    WebDavResposneDataParserManger(parsers: _propParsers);

const kStdResponseResultParser = BaseRespResultParser(
  singleResDecoder:
      BaseRespSingleResultParser(parserManger: kStdElementParserManager),
  multiResDecoder:
      BaseRespMultiResultParser(parserManger: kStdElementParserManager),
);

const _errorParser = BaseErrorElementParser();
const _hrefParser = BaseHrefElementParser();
const _statusParser = BaseHttpStatusElementParser();
const _lockScopeParser = BaseLockScopeElementParser();
const _lockTypeParser = BaseWriteLockElementParser();

const _propstatParser = BasePropstatElementParser(
  parserManger: kStdPropParserManager,
  statusParser: _statusParser,
  errorParser: _errorParser,
);

const _nestedHrefParser = NestedHrefElementParser(hrefParser: _hrefParser);

const _lockDiscoveryParser = LockDiscoveryPropParser<Null>(
    pieceParser: BaseActiveLockElementParser(
  lockScopeParser: _lockScopeParser,
  lockTypeParser: _lockTypeParser,
  depthParser: DepthElementParser(),
  timeoutParser: TimeoutElementParser(),
  ownerParser: null,
  lockTokenParser: _nestedHrefParser,
  lockRootParser: _nestedHrefParser,
));

const _supporedtLockParser = SupportedLockPropParser(
    pieceParser: BaseLockEntryElementParser(
  lockScopeParser: _lockScopeParser,
  lockTypeParser: _lockTypeParser,
));

const _responseParser = BaseResponseElementParser(
    hrefParser: _hrefParser,
    statusParser: _statusParser,
    propstatParser: _propstatParser,
    errorParser: _errorParser,
    locationParser: _nestedHrefParser);

const _multistatusParser =
    BaseMultistatusElementParser(responseParser: _responseParser);

const Map<({String name, String? ns}), Converter> _propParsers = {
  (name: WebDavElementNames.creationdate, ns: kDavNamespaceUrlStr):
      DateTimePropParser(),
  (name: WebDavElementNames.displayname, ns: kDavNamespaceUrlStr):
      StringPropParser(),
  (name: WebDavElementNames.getcontentlanguage, ns: kDavNamespaceUrlStr):
      StringPropParser(),
  (name: WebDavElementNames.getcontentlength, ns: kDavNamespaceUrlStr):
      NumPropParser(),
  (name: WebDavElementNames.getcontenttype, ns: kDavNamespaceUrlStr):
      ContentTypePropParser(),
  (name: WebDavElementNames.getetag, ns: kDavNamespaceUrlStr):
      StringPropParser(),
  (name: WebDavElementNames.getlastmodified, ns: kDavNamespaceUrlStr):
      HttpDatePropParser(),
  (name: WebDavElementNames.lockdiscovery, ns: kDavNamespaceUrlStr):
      _lockDiscoveryParser,
  (name: WebDavElementNames.resourcetype, ns: kDavNamespaceUrlStr):
      ResourceTypePropParser(),
  (name: WebDavElementNames.supportedlock, ns: kDavNamespaceUrlStr):
      _supporedtLockParser,
};
