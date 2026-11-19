#!/bin/sh
# Add an == test to a copy of run_plan.rein, which the rules forbid. Then check
# that the style walk fails. A walk that still passes does not guard the rule.
cd "$(dirname "$0")/.." || exit 1
root=$(pwd)
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
cp -R "$root/." "$tmp/" || exit 1
target=run_plan.rein
sed 's/if (cov.covered) {/if (cov.covered == true) {/' \
  "$root/$target" > "$tmp/$target" || exit 1
if cmp -s "$root/$target" "$tmp/$target"; then
  echo "sabotage did not apply: the covered branch is not in $target"
  exit 1
fi
if (cd "$tmp" && sh scripts/test-flow-rules.sh) |
  grep -q '^FAIL: style'; then
  echo "sabotage fails as expected: the style walk catches the =="
  exit 0
fi
echo "sabotage passed: the walks do not guard the no-== rule"
exit 1
