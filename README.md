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
refer to [here](./example/main.dart) for more examples.

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

### Authentication

Use `WebDavStdClient.authenticated` for automatic Basic or Digest authentication
on native platforms. This constructor throws `UnsupportedError` on the Web,
where the current transport cannot disable automatic redirects. The legacy
constructors remain available on all supported platforms.
Basic can also be selected when the server offers both Basic and Bearer.
Bearer/OAuth authentication is not supported. Digest requires MD5 with no qop
or `qop="auth"`.

```dart
final client = WebDavStdClient.authenticated(
  authentication: WebDavAuthenticationConfig(
    scope: Uri.parse('https://example.com/dav/'),
    username: 'user',
    password: 'app-password',
  ),
);
```

`scope` limits credentials to the given origin and directory. Set
`mode: WebDavAuthenticationMode.basic` to use Basic directly. Basic requires
HTTPS by default; set `allowInsecureBasic: true` for an HTTP server.

Authenticated clients do not follow redirects automatically. Do not combine
this constructor with `setAuthenticate` or `addCredentials`.

Discovery walks from `probeUri` up to `scope` on unauthenticated 404 responses.
Digest uses at most one additional authenticated, read-only PROPFIND to verify
credentials. Business requests are never retried automatically: a 401 is returned
to the caller. Create a new client to rediscover authentication after a Digest
nonce expires or credentials change.

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

## Development

The package supports Dart **3.8.0 or later**. Development and formatting use
**Dart 3.8.3**, pinned in `.tool-versions`. No Flutter SDK is required.
With the Dart plugin installed in asdf, run `asdf install` to install that SDK.
The commands below require GNU Make and a POSIX shell (Git Bash on Windows).

```sh
make bootstrap
make check
```

| Command | Purpose |
| --- | --- |
| `make bootstrap` | Resolve dependencies using the committed lockfile |
| `make gen` | Regenerate Mockito mocks; follow with `make format` |
| `make format` | Format library, test, generated, and example Dart files |
| `make format-check` | Check formatting without changing files |
| `make fix` | Apply Dart fixes and format; review the diff before committing |
| `make analyze` | Require zero analyzer errors, warnings, and infos |
| `make test` | Run all unit and local HTTP integration tests |
| `make publish-dry-run` | Validate the package without publishing |
| `make check` | Resolve, check formatting, analyze, and run all tests |
| `make aio` | Resolve, regenerate mocks, apply fixes, format, and run all checks |

Override the Dart executable with `make check DART=/path/to/dart`.
For a standalone JSON test report, use
`make test MACHINE_OUT=test-results/package_test.log`; `make test CI=1` uses
the GitHub console reporter. Test failures return a nonzero exit code.
The full test suite starts its own loopback HTTP servers and needs no Docker
container or external WebDAV service. The interactive example is separate.

Style rules extend Dart's recommended lints with a pure Dart subset of mHabit's
rules for final/const declarations, return types, imports, and simpler code.
Analysis includes tests, examples, and generated mocks. Keep public APIs and
behavior unchanged when fixing style; any necessary local suppression must
explain the existing contract it preserves. Do not edit generated mocks by hand.

CI checks generated-code reproducibility, formatting, analysis, tests, and
publishing validation on the pinned SDK. Separate jobs analyze and test on
Dart 3.8.0 and the latest stable SDK, plus downgraded dependencies on 3.8.0.
Only the pinned SDK enforces formatting. PRs, main-branch pushes, manual checks,
and tag publishing share these gates; a release tag publishes only after they
all pass.

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
