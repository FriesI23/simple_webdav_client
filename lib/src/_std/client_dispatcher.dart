// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../method.dart';
import '../utils.dart';
import 'client.dart';
import 'copy.dart';
import 'decoder_mgr.dart';
import 'delete.dart';
import 'depth.dart';
import 'get.dart';
import 'if.dart';
import 'lock.dart';
import 'mkcol.dart';
import 'move.dart';
import 'parser.dart';
import 'propfind.dart';
import 'proppatch.dart';
import 'put.dart';
import 'request.dart';
import 'response.dart';
import 'timeout.dart';
import 'unlock.dart';

abstract interface class WebDavStdRequestDispatcher {
  factory WebDavStdRequestDispatcher({
    required WebDavStdClient client,
    required Uri from,
    ResponseBodyDecoderManager? respDecoder,
    ResponseResultParser<WebDavStdResResultView>? respParser,
  }) =>
      StdRequestDispatcherImpl(client, from,
          respDecoder: respDecoder, respParser: respParser);

  /// Retrieves properties defined on resource identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.1 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.1.3
  Future<WebDavStdRequest<PropfindPropRequestParam<P>>>
      findProps<P extends PropfindRequestProp>(
          {required Iterable<P> props, Depth? depth});

  /// Retrieves all properties values defined on resource
  /// (defined in [RFC4918], at a minimum) identified by [from].
  ///
  /// Use [includes] to obtain additional live properties.
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.1 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.1.5
  Future<WebDavStdRequest<PropfindAllRequestParam<P>>>
      findAllProps<P extends PropfindRequestProp>(
          {Iterable<P> includes, Depth? depth});

  /// Retrieves all properties name defined on resource
  /// (defined in [RFC4918], at a minimum) identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.1 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.1.4
  Future<WebDavStdRequest<PropfindNameRequestParam>> findPropNames(
      {Depth? depth});

  /// Update (set/remove) properties defined on resource identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.2 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.2.2
  Future<WebDavStdRequest<ProppatchRequestParam<P>>>
      updateProps<P extends ProppatchRequestProp>(
          {required List<P> operations, IfOr? condition});

  /// Get file's data which identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.4
  Future<WebDavStdRequest<GetRequestParam>> get();

  /// Create new file at the location specified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.7
  Future<WebDavStdRequest<PutRequestParam<T>>> create<T>(
      {T? data, IfOr? condition});

  /// Creates a new directory at the location specified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.3 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.3.2
  Future<WebDavStdRequest<MkcolRequestParam>> createDir({IfOr? condition});

  /// Delete file at the location specified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.6 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.6.2
  Future<WebDavStdRequest<DeleteRequestParam>> delete({IfOr? condition});

  /// Delete directory at the location specified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.6.1
  Future<WebDavStdRequest<DeleteRequestParam>> deleteDir({IfOr? condition});

  /// Creates a duplicate of the source file "[to]" identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.8.1 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.8.6
  Future<WebDavStdRequest<CopyRequestParam>> copy(
      {required Uri to, bool? overwrite, IfOr? condition});

  /// Creates a duplicate of the source directory "[to]" recursively
  /// identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.8 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.8.8
  Future<WebDavStdRequest<CopyRequestParam>> copyDir(
      {required Uri to, bool? overwrite, IfOr? condition});

  /// Move source file identified by [from] to new location [to].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.9 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.9.5
  Future<WebDavStdRequest<MoveRequestParam>> move(
      {required Uri to, bool? overwrite, IfOr? condition});

  /// Move source directory identified by [from] to new location [to]
  /// recursively.
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.9 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.9.5
  Future<WebDavStdRequest<MoveRequestParam>> moveDir(
      {required Uri to, bool? overwrite, IfOr? condition});

  /// Locked resource identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.10 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.10.7
  Future<WebDavStdRequest<LockRequestParam>> createLock(
      {required LockInfo info, DavTimeout? timeout, IfOr? condition});

  /// Locked resource recursively identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.10.3 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.10.7
  Future<WebDavStdRequest<LockRequestParam>> createDirLock(
      {required LockInfo info, DavTimeout? timeout, IfOr? condition});

  /// Refresh existed lock.
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.10.2 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.10.8
  Future<WebDavStdRequest<LockRequestParam>> renewLock(
      {required IfOr condition, DavTimeout? timeout});

  /// Unlock resource identified by [from].
  ///
  /// see: https://datatracker.ietf.org/doc/html/rfc4918#section-9.11 and
  /// https://datatracker.ietf.org/doc/html/rfc4918#section-9.11.2
  Future<WebDavStdRequest<UnlockRequestParam>> unlock({required Uri token});
}

final class StdRequestDispatcherImpl implements WebDavStdRequestDispatcher {
  final WebDavStdClient client;
  final Uri source;
  final ResponseBodyDecoderManager? respDecoder;
  final ResponseResultParser<WebDavStdResResultView>? respParser;

  StdRequestDispatcherImpl(this.client, this.source,
      {this.respDecoder, this.respParser});

  @override
  Future<WebDavStdRequest<PropfindPropRequestParam<P>>>
      findProps<P extends PropfindRequestProp>(
              {required Iterable<P> props, Depth? depth}) =>
          client.openUrl(
              method: WebDavMethod.propfind,
              url: source,
              param:
                  PropfindPropRequestParam(props: props.toList(), depth: depth),
              responseBodyDecoders: respDecoder,
              responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<PropfindAllRequestParam<P>>>
      findAllProps<P extends PropfindRequestProp>(
              {Iterable<P>? includes, Depth? depth}) =>
          client.openUrl(
              method: WebDavMethod.propfind,
              url: source,
              param: PropfindAllRequestParam(
                  include: includes?.toList(), depth: depth),
              responseBodyDecoders: respDecoder,
              responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<PropfindNameRequestParam>> findPropNames(
          {Depth? depth}) =>
      client.openUrl(
          method: WebDavMethod.propfind,
          url: source,
          param: PropfindNameRequestParam(depth: depth),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<ProppatchRequestParam<P>>>
      updateProps<P extends ProppatchRequestProp<ToXmlCapable>>(
              {required List<P> operations, IfOr? condition}) =>
          client.openUrl(
              method: WebDavMethod.proppatch,
              url: source,
              param:
                  ProppatchRequestParam(ops: operations, condition: condition),
              responseBodyDecoders: respDecoder,
              responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<GetRequestParam>> get() => client.openUrl(
      method: WebDavMethod.get,
      url: source,
      param: GetRequestParam(),
      responseBodyDecoders: respDecoder,
      responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<PutRequestParam<T>>> create<T>(
          {T? data, IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.put,
          url: source,
          param: PutRequestParam(data: data, condition: condition),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<MkcolRequestParam>> createDir({IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.mkcol,
          url: source,
          param: MkcolRequestParam(condition: condition),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<DeleteRequestParam>> delete({IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.delete,
          url: source,
          param:
              DeleteRequestParam(depth: Depth.resource, condition: condition),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<DeleteRequestParam>> deleteDir({IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.delete,
          url: source,
          param: DeleteRequestParam(depth: Depth.all, condition: condition),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<CopyRequestParam>> copy(
          {required Uri to, bool? overwrite, IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.copy,
          url: source,
          param: CopyRequestParam(
              destination: to,
              overwrite: overwrite,
              condition: condition,
              recursive: false),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<CopyRequestParam>> copyDir(
          {required Uri to, bool? overwrite, IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.copy,
          url: source,
          param: CopyRequestParam(
              destination: to,
              overwrite: overwrite,
              condition: condition,
              recursive: true),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<MoveRequestParam>> move(
          {required Uri to, bool? overwrite, IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.move,
          url: source,
          param: MoveRequestParam(
              destination: to,
              overwrite: overwrite,
              condition: condition,
              recursive: false),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<MoveRequestParam>> moveDir(
          {required Uri to, bool? overwrite, IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.move,
          url: source,
          param: MoveRequestParam(
              destination: to,
              overwrite: overwrite,
              condition: condition,
              recursive: true),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<LockRequestParam>> createLock(
          {required LockInfo<ToXmlCapable> info,
          DavTimeout? timeout,
          IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.lock,
          url: source,
          param: LockRequestParam(
              lockInfo: info,
              timeout: timeout,
              condition: condition,
              recursive: false),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<LockRequestParam>> createDirLock(
          {required LockInfo<ToXmlCapable> info,
          DavTimeout? timeout,
          IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.lock,
          url: source,
          param: LockRequestParam(
              lockInfo: info,
              timeout: timeout,
              condition: condition,
              recursive: true),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<LockRequestParam>> renewLock(
          {required IfOr condition, DavTimeout? timeout}) =>
      client.openUrl(
          method: WebDavMethod.lock,
          url: source,
          param: LockRequestParam.renew(condition: condition, timeout: timeout),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);

  @override
  Future<WebDavStdRequest<UnlockRequestParam>> unlock({required Uri token}) =>
      client.openUrl(
          method: WebDavMethod.unlock,
          url: source,
          param: UnlockRequestParam(lockToken: token),
          responseBodyDecoders: respDecoder,
          responseResultParser: respParser);
}
