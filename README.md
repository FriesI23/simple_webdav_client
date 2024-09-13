# Simple WebDAV Client

![Package][pubdev-package]
![Likes][pubdev-likes]
![Popularity][pubdev-popularity]
![Points][pubdev-points]

`simple_webdav_client` is a Dart WebDAV client with full RFC 4918 support,
including file operations (PUT/GET/CREATE/DELETE/MKCOL/MOVE/COPY),
property management (PROPFIND/PROPUPDATE), and locking (LOCK/UNLOCK).
Ideal for these needing complete WebDAV functionality.

Client's API invocation style is similar to `HttpClient` and works more easily with async programming.
refer to [here](./example/main.dart) for more exmaples.

## Features

Following methods have been implemented:

- [x] [PROPFIND](#propfind)
- [x] [PROPPATCH](#proppatch)
- [x] [MKCOL](#mkcolput)
- [x] [GET](#getheadpost)
- [x] [HEAD](#getheadpost)
- [x] [POST](#getheadpost)
- [x] [DELETE](#delete)
- [x] [PUT](#mkcolput)
- [x] [COPY](#copy)
- [x] [MOVE](#move)
- [x] [LOCK](#lock)
- [x] [UNLOCK](#unlock)

### Propfind

Used to retrieve properties defined on the resource identified by the Request-URI.
see [RFC4918#9.1](https://datatracker.ietf.org/doc/html/rfc4918#section-9.1) for more information.

You can make a direct request or use the dispatcher's API to make a request
(following related sections will not be repeated).

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    // Use [PropfindPropRequestParam] to specify the properties to be requested,
    // [PropfindAllRequestParam] to retrieve as many live properties as possible,
    // and [PropfindNameRequestParam] to retrieve all property names.
    param: PropfindPropRequestParam(...),
);
// api
client.dispatch(url).findProps(...);
client.dispatch(url).findAllProps(...);
client.dispatch(url).findPropNames(...);
```

### Proppatch

Used to set and/or remove properties defined on the resource identified by the request-URI.
see [RFC4918#9.2](https://datatracker.ietf.org/doc/html/rfc4918#section-9.2) for more information.

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    param: ProppatchRequestParam(...),
);
// api
client.dispatch(url).updateProps(...);
```

### Mkcol/Put

Creates new (collection) resource at the location specified by the Request-URI.
see [RFC4918#9.3 - MKCOL](https://datatracker.ietf.org/doc/html/rfc4918#section-9.3) and
[RFC4918#9.7 - PUT](https://datatracker.ietf.org/doc/html/rfc4918#section-9.7)
for more information.

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    // mkcol: MkcolRequestParam
    // put: PutRequestParam
    param: MkcolRequestParam(...),
);
// api
client.dispatch(url).create(...);
client.dispatch(url).createDir(...);
```

### Get/Head/Post

Same as the HTTP methods defined in [RFC7231](https://datatracker.ietf.org/doc/html/rfc7231).

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    // get: GetRequestParam
    // head: HeadRequestParam
    // post: PostRequestParam
    param: GetRequestParam(...),
);
// api: get
client.dispatch(url).get(...);
```

### Delete

Deletes resource identified by the Request-URI.
see [RFC4918#9.6](https://datatracker.ietf.org/doc/html/rfc4918#section-9.6) for more information.

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    param: DeleteRequestParam(...),
);
// api
client.dispatch(url).delete(...);
client.dispatch(url).deleteDir(...);
```

### Copy

Create a copy of the source resource.
see [RFC4918#9.8](https://datatracker.ietf.org/doc/html/rfc4918#section-9.8) for more information.

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    param: CopyRequestParam(...),
);
// api
client.dispatch(url).copy(...);
client.dispatch(url).copyDir(...);
```

### Move

Move a resource to a new location.
see [RFC4918#9.9](https://datatracker.ietf.org/doc/html/rfc4918#section-9.9) for more information.

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    param: MoveRequestParam(...),
);
// api
client.dispatch(url).move(...);
client.dispatch(url).moveDir(...);
```

### Lock

Used to Request lock on a resource.
see [RFC4918#9.10](https://datatracker.ietf.org/doc/html/rfc4918#section-9.10) for more information.

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    param: LockRequestParam(...),
);
// api
client.dispatch(url).createLock(...);
client.dispatch(url).createDirLock(...);
client.dispatch(url).renewLock(...);
```

### Unlock

Removes the lock identified by the token in Lock-Token.
see [RFC4918#9.11](https://datatracker.ietf.org/doc/html/rfc4918#section-9.11) for more information.

```dart
// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    param: UnlockRequestParam(...),
);
// api
client.dispatch(url).unlock(...);
```

## Usage

Check test cases in dir:[intergration_test/methods_test](./test/intergration_test/methods_test/)
and [example/main.dart](./example/main.dart) for more examples.

### 1. Example - full request

```dart
WebDavClient.std().dispatch(newFilePath)
    .findAllProps(includes: [PropfindRequestProp('author', 'CUSTOM:')])
    .then((request) => request.close())
    .then((response) => response.parse())
    .then((result) => print(result?.toDebugString()));
```

### 2. Example - request with custom parser

```dart
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

final parser = generateParser();

// openUrl
client.openUrl(
    method: WebDavMethod.propfind,
    url: url,
    param: ...,
    responseResultParser: parser
);
// dispatch
WebDavClient.std().dispatch(newFilePath, responseResultParser: parser);
```

## Donate

[!["Buy Me A Coffee"][buymeacoffee-badge]](https://www.buymeacoffee.com/d49cb87qgww)
[![Alipay][alipay-badge]][alipay-addr]
[![WechatPay][wechat-badge]][wechat-addr]

[![ETH][eth-badge]][eth-addr]
[![BTC][btc-badge]][btc-addr]

## License

```text
MIT License

Copyright (c) 2024 Fries_I23

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

[pubdev-package]: https://img.shields.io/pub/v/simple_webdav_client.svg
[pubdev-likes]: https://img.shields.io/pub/likes/simple_webdav_client?logo=dart
[pubdev-popularity]: https://img.shields.io/pub/popularity/simple_webdav_client?logo=dart
[pubdev-points]: https://img.shields.io/pub/points/simple_webdav_client?logo=dart
[buymeacoffee-badge]: https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black
[alipay-badge]: https://img.shields.io/badge/alipay-00A1E9?style=for-the-badge&logo=alipay&logoColor=white
[alipay-addr]: https://raw.githubusercontent.com/FriesI23/mhabit/main/docs/README/images/donate-alipay.jpg
[wechat-badge]: https://img.shields.io/badge/WeChat-07C160?style=for-the-badge&logo=wechat&logoColor=white
[wechat-addr]: https://raw.githubusercontent.com/FriesI23/mhabit/main/docs/README/images/donate-wechatpay.png
[eth-badge]: https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=Ethereum&logoColor=white
[eth-addr]: https://etherscan.io/address/0x35FC877Ef0234FbeABc51ad7fC64D9c1bE161f8F
[btc-badge]: https://img.shields.io/badge/Bitcoin-000000?style=for-the-badge&logo=bitcoin&logoColor=white
[btc-addr]: https://blockchair.com/bitcoin/address/bc1qz2vjews2fcscmvmcm5ctv47mj6236x9p26zk49
