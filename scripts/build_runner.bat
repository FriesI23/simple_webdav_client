@rem Copyright (c) 2024 Fries_I23
@rem
@rem This software is released under the MIT License.
@rem https://opensource.org/licenses/MIT
@echo off

cd /d "%~dp0\.."
dart run build_runner build --delete-conflicting-outputs
