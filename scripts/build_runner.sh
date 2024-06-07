# Copyright (c) 2024 Fries_I23
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

cd "$(dirname "$0")"/..
dart run build_runner build --delete-conflicting-outputs
