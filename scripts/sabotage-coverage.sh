#!/bin/sh
# Flip the covered branch of the first pass in a copy of run_plan.rein, so a
# covered plan goes to a second pass. Then check that a walk fails. A walk
# that still passes does not guard the coverage branch.
cd "$(dirname "$0")/.." || exit 1
root=$(pwd)
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
cp -R "$root/." "$tmp/" || exit 1
target=run_plan.rein
sed 's/if (cov.covered) {/if (!cov.covered) {/' \
  "$root/$target" > "$tmp/$target" || exit 1
if cmp -s "$root/$target" "$tmp/$target"; then
  echo "sabotage did not apply: the covered branch is not in $target"
  exit 1
fi
if (cd "$tmp" && sh scripts/test-flow-rules.sh) |
  grep -q '^FAIL: a covered plan is delivered with its link'; then
  echo "sabotage fails as expected: the walk catches the flipped branch"
  exit 0
fi
echo "sabotage passed: the walks do not guard the covered branch"
exit 1
