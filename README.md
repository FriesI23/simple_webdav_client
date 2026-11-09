# Simple WebDAV Client

[![Package][pubdev-package]](https://pub.dev/packages/simple_webdav_client)
![Likes][pubdev-likes]
![Points][pubdev-points]

A pure Dart WebDAV client for files, collections, properties, and resource locks.
The API supports asynchronous requests and customizable response parsing.

## Features

- File and collection operations: GET, HEAD, POST, PUT, DELETE, MKCOL, COPY, MOVE.
- Property retrieval and updates: PROPFIND, PROPPATCH.
- Resource locking: LOCK, UNLOCK.
- Basic and Digest authentication on native platforms.
- Custom response decoders and XML property parsers.

## Installation

Requires Dart 3.8 or later.

```sh
dart pub add simple_webdav_client
```

## Quick start

Retrieve a collection's properties and those of its immediate members:

```dart
import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/utils.dart' show Depth;

Future<void> main() async {
  final client = WebDavStdClient();
  final url = Uri.parse('https://example.com/dav/');

  try {
    final request = await client
        .dispatch(url)
        .findAllProps(depth: Depth.members);
    final response = await request.close();
    final result = await response.parse();
    print(result?.toDebugString());
  } finally {
    client.close();
  }
}
```

Dispatcher methods return a request. Call `close()` to send it, then `parse()`
for a WebDAV result. For raw response data, use the underlying
`response.response` stream instead. Consume each response body and close the
client when finished.

<details>
<summary>Example: chain request futures</summary>

```dart
await client
    .dispatch(url)
    .findAllProps(
      includes: [const PropfindRequestProp('author', 'urn:example:props')],
    )
    .then((request) => request.close())
    .then((response) => response.parse())
    .then((result) => print(result?.toDebugString()));
```

</details>

## Authentication

Use `WebDavStdClient.authenticated` for scoped Basic and MD5 Digest
authentication on **native platforms**:

```dart
final client = WebDavStdClient.authenticated(
  authentication: WebDavAuthenticationConfig(
    scope: Uri.parse('https://example.com/dav/'),
    username: 'user',
    password: 'app-password',
  ),
);
```

- **Mode:** `auto` performs read-only discovery by default. Set
  `mode: WebDavAuthenticationMode.basic` to send Basic credentials immediately.
- **Credentials:** restricted to the configured origin and directory subtree;
  Basic requires HTTPS by default.
- **Requests:** redirects are returned to the application; the package does not
  replay business requests.

<details>
<summary>Configuration options</summary>

| Configuration | Behavior |
| --- | --- |
| `scope` | Required HTTP(S) directory URI ending in `/`; limits credentials to that origin and directory subtree |
| `username`, `password` | Credentials for the selected scheme |
| `mode` | `WebDavAuthenticationMode.auto` (default) discovers authentication; `WebDavAuthenticationMode.basic` sends Basic credentials immediately without discovery |
| `probeUri` | Initial discovery URI within `scope`; defaults to `scope` |
| `discoveryTimeout` | Deadline for discovery requests and response bodies; defaults to 30 seconds |
| `allowInsecureBasic` | Defaults to `false`, requiring HTTPS for Basic; set to `true` to permit HTTP |

</details>

<details>
<summary>Supported schemes and Unicode handling</summary>

Automatic mode selects Basic or supported Digest from the server's challenge.
Bearer and OAuth are not supported.

| Capability | Basic | Digest |
| --- | --- | --- |
| Discovery | Basic-only or mixed challenges containing Basic | A single Digest challenge |
| Credential encoding | UTF-8, then Base64 | UTF-8 for digest calculation |
| NFC normalization | Username and password when the selected challenge declares `charset=UTF-8` | Same |
| Non-ASCII usernames | Included in the Base64 credentials | Sent using `username*` when username hashing is not enabled |
| Username hashing | Not applicable | Sends a hashed username and `userhash=true` when advertised by the server |
| Algorithm and `qop` | Not applicable | MD5 with no `qop` or `qop="auth"` |

The `charset=UTF-8` value is matched case-insensitively. Without that declaration,
including explicit Basic mode, credentials retain their original Unicode form.

</details>

<details>
<summary>Custom transport and lifecycle</summary>

- **Discovery:** automatic mode uses bounded, read-only PROPFIND requests before
  the first operation. Concurrent callers share initialization. After a
  transport failure or 5xx response, a later call can retry discovery; a
  discovery timeout closes the client.
- **Requests:** redirects are returned to the application, and the package does
  not replay business requests. SDK proxy-authentication retries can omit
  request bodies. Handle redirect and authentication responses in your app.
- **Custom transport:** pass a dedicated `HttpClient` through `client` for proxy,
  TLS, and connection settings. For custom HTTP Digest connections, use the
  constructor's `connectionFactory` parameter. HTTP Digest uses a fresh
  connection for each request; other modes and HTTPS retain the client's
  connection handling.
- **Errors and credentials:** transport exceptions propagate unchanged. Create
  a new client to change credentials or rediscover an expired Digest nonce.
  Keep SDK site-authentication callbacks and credentials off the managed client;
  SDK proxy-authentication APIs remain available.

</details>

<details>
<summary>SDK-managed authentication and browser support</summary>

`WebDavStdClient()` and `WebDavStdClient.withClient(...)` support native and
browser applications. On native platforms, use `setAuthenticate` and
`addCredentials` with these constructors for SDK-managed site authentication.

</details>

## Operations

Use `client.dispatch(url)` for common WebDAV operations:

| Operation | HTTP method | Dispatcher method |
| --- | --- | --- |
| Read selected properties | PROPFIND | `findProps(props: ...)` |
| Read all properties | PROPFIND | `findAllProps()` |
| Read property names | PROPFIND | `findPropNames()` |
| Set or remove properties | PROPPATCH | `updateProps(operations: ...)` |
| Download a file | GET | `get()` |
| Upload or replace a file | PUT | `create(data: ...)` |
| Create a collection | MKCOL | `createDir()` |
| Delete a resource | DELETE | `delete()`, `deleteDir()` |
| Copy a resource | COPY | `copy(to: ...)`, `copyDir(to: ...)` |
| Move a resource | MOVE | `move(to: ...)`, `moveDir(to: ...)` |
| Create a lock | LOCK | `createLock(info: ...)`, `createDirLock(info: ...)` |
| Renew a lock | LOCK | `renewLock(condition: ...)` |
| Remove a lock | UNLOCK | `unlock(token: ...)` |

The examples below use a configured `client` and a resource `url`. Import the
public APIs needed by each example:

```dart
import 'package:simple_webdav_client/client.dart';
import 'package:simple_webdav_client/dav.dart';
import 'package:simple_webdav_client/utils.dart';
```

### PROPFIND

Read selected property values, all properties, or property names. Use `Depth`
to control whether collection members are included.

<details>
<summary>Example</summary>

```dart
final request = await client
    .dispatch(url)
    .findProps(
      props: [const PropfindRequestProp('displayname', 'DAV:')],
      depth: Depth.resource,
    );
final response = await request.close();
print((await response.parse())?.toDebugString());

// Other request builders: findAllProps() and findPropNames().
```

</details>

### PROPPATCH

Set and remove custom properties in a single request.

<details>
<summary>Example</summary>

```dart
final request = await client
    .dispatch(url)
    .updateProps(
      operations: [
        const ProppatchRequestProp.set(
          name: 'author',
          namespace: 'urn:example:props',
          value: ProppatchRequestPropBaseValue('Alice'),
        ),
        const ProppatchRequestProp.remove(
          name: 'obsolete',
          namespace: 'urn:example:props',
        ),
      ],
    );
final response = await request.close();
print((await response.parse())?.toDebugString());
```

</details>

### MKCOL / PUT

Create a collection with `createDir()`, then upload a file with `create()`.

<details>
<summary>Example</summary>

```dart
final directory = url.resolve('notes/');
final directoryRequest = await client.dispatch(directory).createDir();
final directoryResponse = await directoryRequest.close();
await directoryResponse.response.drain<void>();

final fileRequest = await client
    .dispatch(directory.resolve('hello.txt'))
    .create(data: 'Hello, WebDAV!');
final fileResponse = await fileRequest.close();
print(fileResponse.response.statusCode);
await fileResponse.response.drain<void>();
```

</details>

### GET / HEAD / POST

Download data with `get()`. Use `openUrl` for HEAD and POST, pairing each
method with its corresponding request parameters.

<details>
<summary>Example</summary>

```dart
final download = await client.dispatch(url).get();
final downloadResponse = await download.close();
final bytes = await downloadResponse.response
    .expand((chunk) => chunk)
    .toList();
print('Downloaded ${bytes.length} bytes');

final head = await client.openUrl(
  method: WebDavMethod.head,
  url: url,
  param: const HeadRequestParam(),
);
final headResponse = await head.close();
print(headResponse.response.statusCode);
await headResponse.response.drain<void>();

final post = await client.openUrl(
  method: WebDavMethod.post,
  url: url,
  param: const PostRequestParam(data: 'message'),
);
final postResponse = await post.close();
await postResponse.response.drain<void>();
```

</details>

### DELETE

Delete a file with `delete()` or a collection with `deleteDir()`.

<details>
<summary>Example</summary>

```dart
final request = await client.dispatch(url).delete();
final response = await request.close();
print(response.response.statusCode);
await response.response.drain<void>();
```

</details>

### COPY

Copy a file to another URI. Use `copyDir()` for a collection.

<details>
<summary>Example</summary>

```dart
final request = await client
    .dispatch(url)
    .copy(to: url.resolve('copy.txt'), overwrite: false);
final response = await request.close();
print(response.response.statusCode);
await response.response.drain<void>();
```

</details>

### MOVE

Move a file to another URI. Use `moveDir()` for a collection.

<details>
<summary>Example</summary>

```dart
final request = await client
    .dispatch(url)
    .move(to: url.resolve('renamed.txt'), overwrite: false);
final response = await request.close();
print(response.response.statusCode);
await response.response.drain<void>();
```

</details>

### LOCK

Create a resource lock and use its token to renew it. Use `createDirLock()`
when locking a collection.

<details>
<summary>Example</summary>

```dart
final request = await client
    .dispatch(url)
    .createLock(info: const LockInfo(lockScope: LockScope.exclusive));
final response = await request.close();
final result = await response.parse();
final lockToken = result?.firstOrNull?.props
    .whereType<WebDavStdResourceProp<LockDiscovery>>()
    .firstOrNull
    ?.value
    ?.firstOrNull
    ?.lockToken;

if (lockToken != null) {
  final renewal = await client
      .dispatch(url)
      .renewLock(
        condition: IfOr.notag([
          IfAnd.notag([IfCondition.token(lockToken)]),
        ]),
      );
  final renewalResponse = await renewal.close();
  await renewalResponse.response.drain<void>();
}
```

</details>

### UNLOCK

Release a lock using the `Uri` token returned by the LOCK response.

<details>
<summary>Example</summary>

```dart
final request = await client.dispatch(url).unlock(token: lockToken);
final response = await request.close();
print(response.response.statusCode);
await response.response.drain<void>();
```

</details>

See [example/main.dart](example/main.dart) for file operations, custom properties,
and locking, or browse the [integration tests](test/intergration_test/methods_test/)
for individual methods.

## Custom response parsing

Pass `responseBodyDecoders` or `responseResultParser` to `openUrl` or `dispatch`
to customize response decoding and parsing. The
[example application](example/main.dart) demonstrates a parser for a custom XML
property.

Import public entrypoints such as `client.dart`, `dav.dart`, and `utils.dart`
when using these APIs.

<details>
<summary>Example: parse a custom XML property</summary>

```dart
BaseRespResultParser generateParser() {
  final propParsers = Map.of(kStdPropParserManager);
  propParsers[(name: "author", ns: "CUSTOM:")] = const StringPropParser();

  final propstatParser = BasePropstatElementParser(
    parserManger: WebDavResposneDataParserManger(parsers: propParsers),
    statusParser: const BaseHttpStatusElementParser(),
    errorParser: const BaseErrorElementParser(),
  );
  final responseParser = BaseResponseElementParser(
    hrefParser: const BaseHrefElementParser(),
    statusParser: const BaseHttpStatusElementParser(),
    propstatParser: propstatParser,
    errorParser: const BaseErrorElementParser(),
    locationParser: const BaseHrefElementParser(),
  );
  final multistatParser = BaseMultistatusElementParser(
    responseParser: responseParser,
  );

  final parsers = Map.of(kStdElementParserManager);
  parsers[(name: WebDavElementNames.multistatus, ns: kDavNamespaceUrlStr)] =
      multistatParser;

  return BaseRespResultParser(
    singleResDecoder: kStdResponseResultParser.singleResDecoder,
    multiResDecoder: BaseRespMultiResultParser(
      parserManger: WebDavResposneDataParserManger(parsers: parsers),
    ),
  );
}
```

Use the parser when creating requests:

```dart
final request = await client
    .dispatch(url, responseResultParser: generateParser())
    .findAllProps();
final response = await request.close();
print((await response.parse())?.toDebugString());
```

</details>

## Development

Development and formatting use Dart **3.8.3**, pinned in `.tool-versions`.
Run the following commands from the repository root:

```sh
make bootstrap
make check
```

| Command | Purpose |
| --- | --- |
| `make format` | Format Dart sources |
| `make analyze` | Run static analysis |
| `make test` | Run unit and local HTTP integration tests |
| `make gen` | Regenerate Mockito mocks |
| `make publish-dry-run` | Validate the package without publishing |

Use `make help` for all commands. Set `DART=/path/to/dart` to select a specific
SDK, for example `make check DART=/path/to/dart`.

Tests run against local HTTP servers and do not require Docker or an external
WebDAV service.

## Support

[!["Buy Me A Coffee"][buymeacoffee-badge]](https://www.buymeacoffee.com/d49cb87qgww)
[![Alipay][alipay-badge]][alipay-addr]
[![WechatPay][wechat-badge]][wechat-addr]

[![ETH][eth-badge]][eth-addr]
[![BTC][btc-badge]][btc-addr]

<!-- friesi23-projects:start -->

## More projects

| Project | Description |
| --- | --- |
| ![App](https://img.shields.io/badge/-02569B?style=flat-square&logo=flutter&logoColor=white) [Table Habit](https://github.com/FriesI23/mhabit) | Cross-platform habit tracker with scoring, charts, and WebDAV sync. |
| ![Dart Package](https://img.shields.io/badge/-0175C2?style=flat-square&logo=dart&logoColor=white) [Dart Transmission RPC](https://github.com/FriesI23/dart_transmission_rpc) | Dart client for the Transmission RPC API. |
| ![Flutter Plugin](https://img.shields.io/badge/-02569B?style=flat-square&logo=flutter&logoColor=white) [Native Natural Sort](https://github.com/FriesI23/native_natural_sort) | Locale-aware natural sorting for Flutter using native platform engines. |
| ![Flutter Package](https://img.shields.io/badge/-02569B?style=flat-square&logo=flutter&logoColor=white) [Simple Heatmap Calendar](https://github.com/FriesI23/simple_heatmap_calendar) | Customizable Flutter heatmap calendar with internationalization support. |
| ![Dart Package](https://img.shields.io/badge/-0175C2?style=flat-square&logo=dart&logoColor=white) [Win2IANA TimeZone Converter](https://github.com/FriesI23/win2iana_tz_converter) | Dart utilities for converting Windows and IANA time zone identifiers. |
| ![Flutter Package](https://img.shields.io/badge/-02569B?style=flat-square&logo=flutter&logoColor=white) [Adaptive Actions](https://github.com/FriesI23/adaptive_actions) | Adaptive Flutter action bars and overflow menus for Material and Cupertino. |
| ![Flutter Package](https://img.shields.io/badge/-02569B?style=flat-square&logo=flutter&logoColor=white) [Flutter Adaptive Sidebar](https://github.com/FriesI23/flutter_adaptive_sidebar) | Material and Cupertino sidebars for Flutter with a shared controller. |
| ![Flutter Plugin](https://img.shields.io/badge/-02569B?style=flat-square&logo=flutter&logoColor=white) [iOS Window Control Layout](https://github.com/FriesI23/ios_window_control_layout) | Keep Flutter layouts clear of iPadOS window controls. |
| ![Flutter Package](https://img.shields.io/badge/-02569B?style=flat-square&logo=flutter&logoColor=white) [Named HTML Color](https://github.com/FriesI23/named_html_color) | HTML named colors for Flutter. |

<!-- friesi23-projects:end -->

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
