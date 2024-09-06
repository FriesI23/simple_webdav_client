// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '../method.dart';
import '../utils.dart';
import 'client.dart';
import 'copy.dart';
import 'delete.dart';
import 'depth.dart';
import 'get.dart';
import 'if.dart';
import 'lock.dart';
import 'mkcol.dart';
import 'move.dart';
import 'propfind.dart';
import 'proppatch.dart';
import 'put.dart';
import 'request.dart';
import 'timeout.dart';
import 'unlock.dart';

abstract interface class WebDavStdRequestDispatcher {
  factory WebDavStdRequestDispatcher(
          {required WebDavStdClient client, required Uri from}) =>
      StdRequestDispatcherImpl(client, from);

  Future<WebDavStdRequest<PropfindPropRequestParam<P>>>
      findProps<P extends PropfindRequestProp>(
          {required Iterable<P> props, Depth? depth});

  Future<WebDavStdRequest<PropfindAllRequestParam<P>>>
      findAllProps<P extends PropfindRequestProp>(
          {required Iterable<P> includes, Depth? depth});

  Future<WebDavStdRequest<PropfindNameRequestParam>> findPropNames(
      {Depth? depth});

  Future<WebDavStdRequest<ProppatchRequestParam<P>>>
      updateProps<P extends ProppatchRequestProp>(
          {required List<P> operations, IfOr? condition});

  Future<WebDavStdRequest<GetRequestParam>> get();

  Future<WebDavStdRequest<PutRequestParam<T>>> create<T>({T? data});

  Future<WebDavStdRequest<MkcolRequestParam>> createDir({IfOr? condition});

  Future<WebDavStdRequest<DeleteRequestParam>> delete({IfOr? condition});

  Future<WebDavStdRequest<DeleteRequestParam>> deleteDir({IfOr? condition});

  Future<WebDavStdRequest<CopyRequestParam>> copy(
      {required Uri to, bool? overwrite, IfOr? condition});

  Future<WebDavStdRequest<CopyRequestParam>> copyDir(
      {required Uri to, bool? overwrite, IfOr? condition});

  Future<WebDavStdRequest<MoveRequestParam>> move(
      {required Uri to, bool? overwrite, IfOr? condition});

  Future<WebDavStdRequest<MoveRequestParam>> moveDir(
      {required Uri to, bool? overwrite, IfOr? condition});

  Future<WebDavStdRequest<LockRequestParam>> createLock(
      {required LockInfo info, DavTimeout? timeout, IfOr? condition});

  Future<WebDavStdRequest<LockRequestParam>> createDirLock(
      {required LockInfo info, DavTimeout? timeout, IfOr? condition});

  Future<WebDavStdRequest<LockRequestParam>> renewLock(
      {required IfOr condition, DavTimeout? timeout});

  Future<WebDavStdRequest<UnlockRequestParam>> unlock({required Uri token});
}

final class StdRequestDispatcherImpl implements WebDavStdRequestDispatcher {
  final WebDavStdClient client;
  final Uri source;

  StdRequestDispatcherImpl(this.client, this.source);

  @override
  Future<WebDavStdRequest<PropfindPropRequestParam<P>>> findProps<
              P extends PropfindRequestProp>(
          {required Iterable<P> props, Depth? depth}) =>
      client.openUrl(
          method: WebDavMethod.propfind,
          url: source,
          param: PropfindPropRequestParam(props: props.toList(), depth: depth));

  @override
  Future<WebDavStdRequest<PropfindAllRequestParam<P>>>
      findAllProps<P extends PropfindRequestProp>(
              {required Iterable<P> includes, Depth? depth}) =>
          client.openUrl(
              method: WebDavMethod.propfind,
              url: source,
              param: PropfindAllRequestParam(
                  include: includes.toList(), depth: depth));

  @override
  Future<WebDavStdRequest<PropfindNameRequestParam>> findPropNames(
          {Depth? depth}) =>
      client.openUrl(
          method: WebDavMethod.propfind,
          url: source,
          param: PropfindNameRequestParam(depth: depth));

  @override
  Future<WebDavStdRequest<ProppatchRequestParam<P>>>
      updateProps<P extends ProppatchRequestProp<ToXmlCapable>>(
              {required List<P> operations, IfOr? condition}) =>
          client.openUrl(
              method: WebDavMethod.proppatch,
              url: source,
              param:
                  ProppatchRequestParam(ops: operations, condition: condition));

  @override
  Future<WebDavStdRequest<GetRequestParam>> get() => client.openUrl(
      method: WebDavMethod.get, url: source, param: GetRequestParam());

  @override
  Future<WebDavStdRequest<PutRequestParam<T>>> create<T>({T? data}) =>
      client.openUrl(
          method: WebDavMethod.put,
          url: source,
          param: PutRequestParam(data: data));

  @override
  Future<WebDavStdRequest<MkcolRequestParam>> createDir({IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.mkcol,
          url: source,
          param: MkcolRequestParam(condition: condition));

  @override
  Future<WebDavStdRequest<DeleteRequestParam>> delete({IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.delete,
          url: source,
          param:
              DeleteRequestParam(depth: Depth.resource, condition: condition));

  @override
  Future<WebDavStdRequest<DeleteRequestParam>> deleteDir({IfOr? condition}) =>
      client.openUrl(
          method: WebDavMethod.delete,
          url: source,
          param: DeleteRequestParam(depth: Depth.all, condition: condition));

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
              recursive: false));

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
              recursive: true));

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
              recursive: false));

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
              recursive: true));

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
              recursive: false));

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
              recursive: true));

  @override
  Future<WebDavStdRequest<LockRequestParam>> renewLock(
          {required IfOr condition, DavTimeout? timeout}) =>
      client.openUrl(
          method: WebDavMethod.lock,
          url: source,
          param:
              LockRequestParam.renew(condition: condition, timeout: timeout));

  @override
  Future<WebDavStdRequest<UnlockRequestParam>> unlock({required Uri token}) =>
      client.openUrl(
          method: WebDavMethod.unknown,
          url: source,
          param: UnlockRequestParam(lockToken: token));
}
