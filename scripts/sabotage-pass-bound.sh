#!/bin/sh
# Send the second pass back to itself in a copy of revise_plan.rein, so the
# passes never stop at three. Then check that a walk fails. A walk that still
# passes does not guard the bound on the passes.
cd "$(dirname "$0")/.." || exit 1
root=$(pwd)
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
cp -R "$root/." "$tmp/" || exit 1
target=revise_plan.rein
sed 's/return @\.\/revise_again(/return @.\/revise_plan(/' \
  "$root/$target" > "$tmp/$target" || exit 1
if cmp -s "$root/$target" "$tmp/$target"; then
  echo "sabotage did not apply: the bound is not in $target"
  exit 1
fi
if (cd "$tmp" && sh scripts/test-flow-rules.sh) |
  grep -q '^FAIL: a third false coverage stops and lists the gaps'; then
  echo "sabotage fails as expected: the walk catches the unbounded passes"
  exit 0
fi
echo "sabotage passed: the walks do not guard the bound on the passes"
exit 1
