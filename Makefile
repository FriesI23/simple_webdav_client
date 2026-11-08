.DEFAULT_GOAL := help
DART ?= dart
CI ?= 0
MACHINE_OUT ?=
DART_DIRS := lib test example

.PHONY: help bootstrap gen format format-check fix analyze test publish-dry-run check aio

help:
	@echo "simple_webdav_client — Dart automation entrypoints"
	@echo "  bootstrap       Resolve the committed dependency lockfile"
	@echo "  gen             Regenerate Mockito mocks"
	@echo "  format          Format all Dart sources with Dart 3.8.3"
	@echo "  format-check    Check Dart formatting without rewriting files"
	@echo "  fix             Apply Dart fixes, then format"
	@echo "  analyze         Require zero errors, warnings, and infos"
	@echo "  test            Run unit and local HTTP integration tests"
	@echo "  publish-dry-run Validate the package without publishing"
	@echo "  check           Resolve, check formatting, analyze, and test"
	@echo "  aio             Generate mocks, apply fixes, format, and run all checks"

bootstrap:
	@$(DART) pub get --enforce-lockfile

gen:
	@$(DART) run build_runner build

format:
	@$(DART) format $(DART_DIRS)

format-check:
	@$(DART) format --output=none --set-exit-if-changed $(DART_DIRS)

fix:
	@$(DART) fix --apply
	@$(MAKE) --no-print-directory format

analyze:
	@$(DART) analyze --fatal-infos

test:
ifneq ($(MACHINE_OUT),)
	@mkdir -p "$(dir $(MACHINE_OUT))"
	@$(DART) test --file-reporter="json:$(MACHINE_OUT)"
else ifeq ($(CI),1)
	@$(DART) test --reporter=github
else
	@$(DART) test
endif

publish-dry-run:
	@$(DART) pub publish --dry-run

# Recursive calls keep these gates sequential, including under make -j.
check:
	@$(MAKE) --no-print-directory bootstrap
	@$(MAKE) --no-print-directory format-check
	@$(MAKE) --no-print-directory analyze
	@$(MAKE) --no-print-directory test

aio:
	@$(MAKE) --no-print-directory bootstrap
	@$(MAKE) --no-print-directory gen
	@$(MAKE) --no-print-directory fix
	@$(MAKE) --no-print-directory check
