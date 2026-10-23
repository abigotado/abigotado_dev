#!/usr/bin/env bash
# Codegen drift guard: committed *.g.dart must match what build_runner
# produces. Fingerprints every tracked and untracked non-ignored *.g.dart,
# runs build_runner, fingerprints again, and fails naming the changed files.
#
# Comparing content before/after (not `git status`) keeps the check honest in
# a dirty tree: an uncommitted provider edit with correctly regenerated output
# passes, while stale output fails. CI's porcelain drift guard (ci.yml) is the
# equivalent check on a clean checkout.
set -euo pipefail

fingerprint() {
  git ls-files -co --exclude-standard -- '*.g.dart' | LC_ALL=C sort -u \
    | while IFS= read -r f; do
        if [ -f "$f" ]; then
          printf '%s  %s\n' "$(git hash-object -- "$f")" "$f"
        else
          printf '%s  %s\n' missing "$f"
        fi
      done
}

before=$(fingerprint)
dart run build_runner build --delete-conflicting-outputs
after=$(fingerprint)

if [ "$before" != "$after" ]; then
  {
    echo 'codegen was stale — commit the regenerated output:'
    diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") \
      | sed -n 's/^[<>] [^ ]*  //p' | LC_ALL=C sort -u || true
  } >&2
  exit 1
fi
