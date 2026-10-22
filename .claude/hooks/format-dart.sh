#!/bin/sh
# PostToolUse(Edit|Write) hook: format the touched Dart file so the
# `dart format --set-exit-if-changed .` gate never fails on drift.
#
# Deliberately quiet: a file can be transiently unparsable mid-edit, and a
# machine without the Flutter toolchain must not turn every edit into noise —
# the gate and CI still enforce formatting at the end.

command -v dart >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

file_path=$(python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
')

case "$file_path" in
  '' | *.g.dart | *.mocks.dart | */l10n/gen/*) exit 0 ;;
  *.dart) dart format "$file_path" >/dev/null 2>&1 || exit 0 ;;
esac
