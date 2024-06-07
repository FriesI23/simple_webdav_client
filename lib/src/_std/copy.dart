// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '_param.dart';
import 'depth.dart';

final class CopyRequestParam extends CommonCopyMoveRequestParam {
  const CopyRequestParam(
      {required super.destination,
      bool? recursive,
      super.overwrite,
      super.condition})
      : super(
            depth: recursive != null
                ? (recursive ? Depth.all : Depth.resource)
                : null);
}
