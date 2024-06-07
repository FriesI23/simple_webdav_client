// Copyright (c) 2024 Fries_I23
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import '_param.dart';
import 'depth.dart';

final class MoveRequestParam extends CommonCopyMoveRequestParam {
  const MoveRequestParam(
      {required super.destination,
      bool recursive = false,
      super.overwrite,
      super.condition})
      : super(depth: recursive ? Depth.all : null);
}
