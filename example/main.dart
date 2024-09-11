// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:io';

import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/dav.dart';
import 'package:simple_webdav_client/utils.dart';

BaseRespResultParser generateParser() {
  final propParsers = Map.of(kStdPropParserManager);
  propParsers[(name: "author", ns: "CUSTOM:")] = const StringPropParser();

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

  return BaseRespResultParser(
      singleResDecoder: kStdResponseResultParser.singleResDecoder,
      multiResDecoder: BaseRespMultiResultParser(
          parserManger: WebDavResposneDataParserManger(parsers: parsers)));
}

void main() async {
  final Uri newFilePath;
  final Uri newDirPath;
  final WebDavStdClient client;

  BaseRespResultParser parser;

  client = WebDavClient.std();
  client.addCredentials(Uri.parse('http://localhost'), "WebDAV",
      HttpClientDigestCredentials("admin", "123456"));
  parser = generateParser();

  newFilePath = Uri.parse("http://localhost/new-file.txt");
  final dispatcher = client.dispatch(newFilePath, responseResultParser: parser);
  print('[Step1]: put new file at $newFilePath');
  await dispatcher
      .create(data: "test data")
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  print('[Step2]: set custom prop on $newFilePath');
  await dispatcher
      .updateProps(operations: [
        ProppatchRequestProp.set(
            name: "author",
            namespace: "CUSTOM:",
            value: ProppatchRequestPropBaseValue("zigzag"))
      ])
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  print('[Step3]: get prop names from $newFilePath');
  await dispatcher
      .findPropNames()
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  print('[Step4]: get props attributes from $newFilePath');
  await dispatcher
      .findAllProps(includes: [PropfindRequestProp('author', 'CUSTOM:')])
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  newDirPath = Uri.parse("http://localhost/path/");
  print('\n');
  print('[Step5]: make new dir $newDirPath');
  await client
      .dispatch(newDirPath)
      .createDir()
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  final copyedFilePath = Uri.parse("http://localhost/path/new-file-copyed.txt");
  print('[Step6]: copy $newFilePath to $copyedFilePath');
  await client
      .dispatch(newFilePath)
      .copy(to: copyedFilePath)
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));
  await client
      .dispatch(newFilePath)
      .copy(to: Uri.parse("http://localhost/path/new-file-copyed-bak.txt"))
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  print('[Step7]: remove custom prop on $newFilePath');
  await dispatcher
      .updateProps(operations: [
        ProppatchRequestProp.remove(name: "author", namespace: "CUSTOM:")
      ])
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  print('[Step8]: get props attributes from $newFilePath');
  await dispatcher
      .findProps(props: [
        PropfindRequestProp('author', 'CUSTOM:'),
        PropfindRequestProp.dav("getlastmodified"),
        PropfindRequestProp.dav("getetag")
      ])
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  final movedFilePath = Uri.parse("http://localhost/path/new-file-moved.txt");
  print('[Step9]: move $copyedFilePath to $movedFilePath');
  await client
      .dispatch(copyedFilePath)
      .move(to: movedFilePath)
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  print('[Step10]: get props attributes from $newFilePath');
  await client
      .dispatch(movedFilePath, responseResultParser: parser)
      .findProps(props: [
        PropfindRequestProp('author', 'CUSTOM:'),
        PropfindRequestProp.dav("getlastmodified"),
        PropfindRequestProp.dav("getetag")
      ])
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  print('[Step11]: delete dir $newDirPath');
  await client
      .dispatch(newDirPath)
      .deleteDir()
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));
  await client
      .dispatch(newDirPath)
      .get()
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  print('\n');
  print('[Step12]: lock file $newFilePath');

  Uri? lockToken;
  await dispatcher
      .createLock(info: LockInfo(lockScope: LockScope.exclusive))
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) {
    print(result?.toDebugString());
    lockToken = result?.firstOrNull?.props
        .whereType<WebDavStdResourceProp<LockDiscovery>>()
        .firstOrNull
        ?.value
        ?.firstOrNull
        ?.lockToken;
  });

  print('\n');
  print('[Step13]: delete file $newFilePath');
  await client
      .dispatch(newFilePath)
      .delete()
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));
  await client
      .dispatch(newFilePath)
      .get()
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));

  if (lockToken != null) {
    print('\n');
    print('[Step13]: unlock file $newFilePath');
    await client
        .dispatch(newFilePath)
        .unlock(token: lockToken!)
        .then((request) => request.close())
        .then((response) => response.parse())
        .then((result) => print(result?.toDebugString()));
  }

  print('\n');
  print('[Step15]: delete file $newFilePath');
  await client
      .dispatch(newFilePath)
      .delete()
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));
  await client
      .dispatch(newFilePath)
      .get()
      .then((request) => request.close())
      .then((response) => response.parse())
      .then((result) => print(result?.toDebugString()));
}
