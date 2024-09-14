// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT
//
// Output (Example):
// -----------------------------------
// [Step1]: put new file at http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:201,
//     props(0):
//   }
// }
//
//
// [Step2]: set custom prop on http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // /new-file.txt
//   WebDavStdResource{
//     path:/new-file.txt | status:207,
//     props(1):
//       [custom:]author: WebDavStdResourceProp<String>{name:author,ns:custom:,status:200,value:},
//   }
// }
//
//
// [Step3]: get prop names from http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // /new-file.txt
//   WebDavStdResource{
//     path:/new-file.txt | status:207,
//     props(9):
//       [custom:]author: WebDavStdResourceProp<String>{name:author,ns:custom:,status:200,value:},
//       [dav:]resourcetype: WebDavStdResourceProp<ResourceTypes>{name:resourcetype,ns:dav:,status:200,value:()},
//       [dav:]creationdate: WebDavStdResourceProp<DateTime>{name:creationdate,ns:dav:,status:200,value:null},
//       [dav:]getcontentlength: WebDavStdResourceProp<num>{name:getcontentlength,ns:dav:,status:200,value:null},
//       [dav:]getlastmodified: WebDavStdResourceProp<DateTime>{name:getlastmodified,ns:dav:,status:200,value:null},
//       [dav:]getetag: WebDavStdResourceProp<String>{name:getetag,ns:dav:,status:200,value:},
//       [dav:]supportedlock: WebDavStdResourceProp<List<LockEntry>>{name:supportedlock,ns:dav:,status:200,value:[]},
//       [dav:]lockdiscovery: WebDavStdResourceProp<List<ActiveLock<Null>>>{name:lockdiscovery,ns:dav:,status:200,value:[]},
//       [dav:]getcontenttype: WebDavStdResourceProp<ContentType>{name:getcontenttype,ns:dav:,status:200,value:null},
//   }
// }
//
//
// [Step4]: get props attributes from http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // /new-file.txt
//   WebDavStdResource{
//     path:/new-file.txt | status:207,
//     props(9):
//       [custom:]author: WebDavStdResourceProp<String>{name:author,ns:custom:,status:200,value:zigzag},
//       [dav:]resourcetype: WebDavStdResourceProp<ResourceTypes>{name:resourcetype,ns:dav:,status:200,value:()},
//       [dav:]creationdate: WebDavStdResourceProp<DateTime>{name:creationdate,ns:dav:,status:200,value:2024-09-14 07:15:01.000Z},
//       [dav:]getcontentlength: WebDavStdResourceProp<num>{name:getcontentlength,ns:dav:,status:200,value:0},
//       [dav:]getlastmodified: WebDavStdResourceProp<DateTime>{name:getlastmodified,ns:dav:,status:200,value:2024-09-14 07:15:01.000Z},
//       [dav:]getetag: WebDavStdResourceProp<String>{name:getetag,ns:dav:,status:200,value:"0-6220f191f7916"},
//       [dav:]supportedlock: WebDavStdResourceProp<List<LockEntry>>{name:supportedlock,ns:dav:,status:200,value:[Instance of 'LockEntry', Instance of 'LockEntry']},
//       [dav:]lockdiscovery: WebDavStdResourceProp<List<ActiveLock<Null>>>{name:lockdiscovery,ns:dav:,status:200,value:[]},
//       [dav:]getcontenttype: WebDavStdResourceProp<ContentType>{name:getcontenttype,ns:dav:,status:200,value:text/plain},
//   }
// }
//
//
// [Step5]: make new dir http://localhost/path/
// WebDavStdResponseResult{
//   // http://localhost/path/
//   WebDavStdResource{
//     path:http://localhost/path/ | status:201,
//     props(0):
//   }
// }
//
//
// [Step6]: copy http://localhost/new-file.txt to http://localhost/path/new-file-copyed.txt
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:201,
//     props(0):
//   }
// }
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:201,
//     props(0):
//   }
// }
//
//
// [Step7]: remove custom prop on http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // /new-file.txt
//   WebDavStdResource{
//     path:/new-file.txt | status:207,
//     props(1):
//       [custom:]author: WebDavStdResourceProp<String>{name:author,ns:custom:,status:200,value:},
//   }
// }
//
//
// [Step8]: get props attributes from http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // /new-file.txt
//   WebDavStdResource{
//     path:/new-file.txt | status:207,
//     props(3):
//       [dav:]getlastmodified: WebDavStdResourceProp<DateTime>{name:getlastmodified,ns:dav:,status:200,value:2024-09-14 07:15:01.000Z},
//       [dav:]getetag: WebDavStdResourceProp<String>{name:getetag,ns:dav:,status:200,value:"0-6220f191f7916"},
//       [custom:]author: WebDavStdResourceProp<String>{name:author,ns:custom:,status:404,value:},
//   }
// }
//
//
// [Step9]: move http://localhost/path/new-file-copyed.txt to http://localhost/path/new-file-moved.txt
// WebDavStdResponseResult{
//   // http://localhost/path/new-file-copyed.txt
//   WebDavStdResource{
//     path:http://localhost/path/new-file-copyed.txt | status:201,
//     props(0):
//   }
// }
//
//
// [Step10]: get props attributes from http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // /path/new-file-moved.txt
//   WebDavStdResource{
//     path:/path/new-file-moved.txt | status:207,
//     props(3):
//       [custom:]author: WebDavStdResourceProp<String>{name:author,ns:custom:,status:200,value:zigzag},
//       [dav:]getlastmodified: WebDavStdResourceProp<DateTime>{name:getlastmodified,ns:dav:,status:200,value:2024-09-14 07:15:01.000Z},
//       [dav:]getetag: WebDavStdResourceProp<String>{name:getetag,ns:dav:,status:200,value:"0-6220f1920bcc2"},
//   }
// }
//
//
// [Step11]: delete dir http://localhost/path/
// WebDavStdResponseResult{
//   // http://localhost/path/
//   WebDavStdResource{
//     path:http://localhost/path/ | status:204,
//     props(0):
//   }
// }
// WebDavStdResponseResult{
//   // http://localhost/path/
//   WebDavStdResource{
//     path:http://localhost/path/ | status:404,
//     props(0):
//   }
// }
//
//
// [Step12]: lock file http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:200,
//     props(1):
//       [dav:]lockdiscovery: WebDavStdResourceProp<List<ActiveLock<Null>>>{name:lockdiscovery,ns:dav:,status:200,value:[Instance of 'ActiveLock<Null>']},
//   }
// }
//
//
// [Step13]: delete file http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:423,
//     props(0):
//   }
// }
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:200,
//     props(0):
//   }
// }
//
//
// [Step13]: unlock file http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:204,
//     props(0):
//   }
// }
//
//
// [Step15]: delete file http://localhost/new-file.txt
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:204,
//     props(0):
//   }
// }
// WebDavStdResponseResult{
//   // http://localhost/new-file.txt
//   WebDavStdResource{
//     path:http://localhost/new-file.txt | status:404,
//     props(0):
//   }
// }
//
// Exited.
//

import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/dav.dart';
import 'package:simple_webdav_client/utils.dart';
import 'package:universal_io/io.dart';

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
