#!/usr/bin/env bash
# Updates the rpcs3 flake package, working around nix-update's
# --version=branch picking up RPCS3's unrelated "vcpkg-v1.0" tag
# instead of a real release version.
#
# nix-update still does the actual work correctly (fetching the
# latest commit, rev, and hash) -- we just repair the version
# string it derives afterwards.

set -euo pipefail

FLAKE="flake.nix"

if [[ ! -f "$FLAKE" ]]; then
  echo "error: $FLAKE not found in $(pwd)" >&2
  exit 1
fi

# 1. Remember the currently-pinned major.minor.patch (the part
#    before "-unstable-"). This only needs to change by hand when
#    RPCS3 itself bumps its version (rare), not on every commit.
OLD_BASEVER=$(grep -oP 'version = "\K[0-9]+\.[0-9]+\.[0-9]+' "$FLAKE" || true)
if [[ -z "$OLD_BASEVER" ]]; then
  echo "error: could not find a valid X.Y.Z version prefix in $FLAKE" >&2
  echo "current version line is:" >&2
  grep -n 'version = ' "$FLAKE" >&2
  echo "fix it by hand to something like: version = \"0.0.41-unstable-2026-07-03\";" >&2
  exit 1
fi
echo "Current base version: $OLD_BASEVER"

# 2. Let nix-update do the real work: fetch the new rev + hash.
#    Its guessed version prefix will likely be wrong (e.g. cpkg-v1.0);
#    we don't care, we overwrite it in step 3.
nix-update --flake --version=branch rpcs3

# 3. Extract the date nix-update just wrote -- that part is always
#    correct, it's just the prefix before "-unstable-" that's bogus.
NEW_DATE=$(grep -oP 'version = ".*unstable-\K[0-9-]+' "$FLAKE" || true)
if [[ -z "$NEW_DATE" ]]; then
  echo "error: could not extract a date from the version nix-update wrote:" >&2
  grep -n 'version = ' "$FLAKE" >&2
  exit 1
fi

# 4. Re-apply the correct version scheme: <old base version>-unstable-<new date>
sed -i "s/version = \".*\";/version = \"${OLD_BASEVER}-unstable-${NEW_DATE}\";/" "$FLAKE"

echo
echo "Updated to: ${OLD_BASEVER}-unstable-${NEW_DATE}"
grep -n 'version = ' "$FLAKE"

echo
echo "If RPCS3 has released a new base version (check https://rpcs3.net/download),"
echo "bump OLD_BASEVER by hand: sed -i 's/${OLD_BASEVER}/X.Y.Z/' $FLAKE"