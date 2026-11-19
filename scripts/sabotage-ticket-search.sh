#!/bin/sh
# Flip the Jira branch in a copy of main.rein, so a found Jira ticket still
# searches GitHub. Then check that a walk fails. A walk that still passes does
# not guard the order of the ticket search.
cd "$(dirname "$0")/.." || exit 1
root=$(pwd)
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
cp -R "$root/." "$tmp/" || exit 1
target=main.rein
sed 's/if (jira.found) {/if (!jira.found) {/' \
  "$root/$target" > "$tmp/$target" || exit 1
if cmp -s "$root/$target" "$tmp/$target"; then
  echo "sabotage did not apply: the Jira branch is not in $target"
  exit 1
fi
if (cd "$tmp" && sh scripts/test-flow-rules.sh) |
  grep -q '^FAIL: a found Jira ticket never searches GitHub'; then
  echo "sabotage fails as expected: the walk catches the flipped branch"
  exit 0
fi
echo "sabotage passed: the walks do not guard the Jira-first search"
exit 1
