#!/bin/sh
# Walk the test-plan process with fixed answers and check where each walk
# ends. Each walk must hold its text. A sabotage edits one rule in a copy and
# must make a walk fail, so the walk is known to test that rule.
# The patterns hold backticks and globs in single quotes on purpose.
# shellcheck disable=SC2016
cd "$(dirname "$0")/.." || exit 1
root=$(pwd)
fail=0
FEATURE=ABC-1
W='run_plan.work={"notes":"/w/notes.md","plan":"/w/test-plan-ABC-1.md"}'
JIRA='main.jira={"found":true,"tracker":"jira","key":"ABC-1","name":"ABC-1"}'
NO_JIRA='main.jira={"found":false,"tracker":"none","key":"none","name":"none"}'
GH='main.github={"found":true,"tracker":"github","key":"acme/app#7","name":"acme-app-7"}'
NO_GH='main.github={"found":false,"tracker":"none","key":"none","name":"none"}'
NO_LIN='main.linear={"found":false,"tracker":"none","key":"none","name":"none"}'
TICKET='run_plan.ticket={"read":true}'
NO_SRC='run_plan.meetings={"found":false}'
NO_SLACK='run_plan.slack={"found":false}'
NO_CODE='run_plan.code={"found":false}'
NO_ONLINE='run_plan.online={"found":false}'
WROTE='run_plan.wrote={"written":true}'
COV_YES='run_plan.cov={"covered":true,"gaps":"none"}'
COV_NO='run_plan.cov={"covered":false,"gaps":"AC-2 has no test case"}'
REV_WROTE='revise_plan.wrote={"written":true}'
REV_COV_YES='revise_plan.cov={"covered":true,"gaps":"none"}'
REV_COV_NO='revise_plan.cov={"covered":false,"gaps":"AC-3 has no test case"}'
AG_WROTE='revise_again.wrote={"written":true}'
AG_COV_NO='revise_again.cov={"covered":false,"gaps":"AC-4 has no test case"}'
LISTED='revise_again.listed={"listed":true}'
POSTED='deliver.posted={"posted":true,"link":"https://example.test/c1"}'
NOT_POSTED='deliver.posted={"posted":false,"link":"none"}'

# joined: one output line per step, and the line breaks of a text as spaces.
# The JSON output writes a break as a backslash and an n, so both are joined.
joined() { tr '\n' ' ' | sed 's/\\n/ /g'; }

# A walk stops at the first request it has no answer for: rein exits 3 then.
# $1 name, $2 fixed text the output must hold, $3... rein answers.
expect() {
  name=$1 want=$2
  shift 2
  status=0
  out=$(rein step --root "$root" --entry main --json \
    --input feature="$FEATURE" "$@" 2>&1) || status=$?
  if [ "$status" -ne 0 ] && [ "$status" -ne 3 ]; then
    echo "FAIL: $name (rein exit $status)"
    echo "$out"
    fail=1
  elif printf '%s\n' "$out" | joined | grep -Fq -- "$want"; then
    echo "ok: $name"
  else
    echo "FAIL: $name"
    echo "$out"
    fail=1
  fi
}

# $1 name, $2 fixed text that must not appear, $3... rein answers.
never() {
  name=$1 bad=$2
  shift 2
  status=0
  out=$(rein step --root "$root" --entry main --json \
    --input feature="$FEATURE" "$@" 2>&1) || status=$?
  if [ "$status" -ne 0 ] && [ "$status" -ne 3 ]; then
    echo "FAIL: $name (rein exit $status)"
    echo "$out"
    fail=1
  elif printf '%s\n' "$out" | joined | grep -Fq -- "$bad"; then
    echo "FAIL: $name"
    echo "$out"
    fail=1
  else
    echo "ok: $name"
  fi
}

# The ticket search: Jira first, then GitHub, then Linear.
expect "the Jira search runs first" \
  'Find the Jira ticket of the feature'
never "a found Jira ticket never searches GitHub" '"key":"main.github"' \
  --answer "$JIRA"
expect "no Jira ticket sends the search to GitHub" \
  'Find the GitHub issue of the feature' --answer "$NO_JIRA"
never "a found GitHub issue never searches Linear" '"key":"main.linear"' \
  --answer "$NO_JIRA" --answer "$GH"
expect "no GitHub issue sends the search to Linear" \
  'Find the Linear issue of the feature' \
  --answer "$NO_JIRA" --answer "$NO_GH"

# A feature with no ticket: the user is asked, and the process stops.
expect "no ticket asks the user for the ticket, then stops" \
  'Ask the user for the ticket key or link, then stop' \
  --answer "$NO_JIRA" --answer "$NO_GH" --answer "$NO_LIN"
never "no ticket never makes a work folder" '"key":"run_plan.work"' \
  --answer "$NO_JIRA" --answer "$NO_GH" --answer "$NO_LIN"

# The work folder comes first, then the ticket, then the sources.
expect "the work folder is made by the bundled script" \
  'scripts/make-work.sh' --answer "$JIRA"
expect "the script folder is found through the installed package" \
  'rein/programs/npm/node_modules/test-plan' \
  --answer "$JIRA"
expect "the ticket is read before the sources" '"key":"run_plan.ticket"' \
  --answer "$JIRA" --answer "$W"
expect "the ticket read writes its notes to the notes file" \
  'Append to /w/notes.md the title' --answer "$JIRA" --answer "$W"
expect "the sources come after the ticket read" '"key":"run_plan.meetings"' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET"

# Sources with nothing: the run goes on and the plan is still written.
expect "a source with nothing is not an error" \
  'An empty search is not an error' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET"
expect "the slack source never posts" 'Never post or edit in Slack' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" --answer "$NO_SRC"
expect "all sources empty: the plan is still written" \
  '"key":"run_plan.wrote"' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE"
expect "all sources empty: the gaps go under open questions" \
  'list it under Open questions' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE"
expect "a covered plan is delivered with its link" \
  'Return: plan /w/test-plan-ABC-1.md. Comment' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_YES" --answer "$POSTED"
expect "a failed comment returns the plan path and says so" \
  'The comment failed' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_YES" --answer "$NOT_POSTED"

# Coverage false, then true: the second pass closes the gap.
expect "coverage false sends the plan to a second pass" \
  '"key":"revise_plan.wrote"' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_NO"
expect "the second pass gets the gaps of the first" \
  'Gaps: AC-2 has no test case' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_NO"
never "coverage true never makes a second pass" '"key":"revise_plan.wrote"' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_YES"
expect "coverage true after the second pass delivers" \
  'Return: plan /w/test-plan-ABC-1.md. Comment' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_NO" \
  --answer "$REV_WROTE" --answer "$REV_COV_YES" --answer "$POSTED"

# Coverage false three times: the process stops and lists the gaps.
expect "a third false coverage stops and lists the gaps as open questions" \
  'Under the heading Open questions, add one line for each' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_NO" \
  --answer "$REV_WROTE" --answer "$REV_COV_NO" \
  --answer "$AG_WROTE" --answer "$AG_COV_NO"
expect "the stopped plan is still delivered" \
  'Return: plan /w/test-plan-ABC-1.md. Comment' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_NO" \
  --answer "$REV_WROTE" --answer "$REV_COV_NO" \
  --answer "$AG_WROTE" --answer "$AG_COV_NO" \
  --answer "$LISTED" --answer "$POSTED"

# The plan rules: sources cited, no secrets, and no Slack post.
expect "every fact of the plan carries its source" \
  'Each fact has its source link' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE"
expect "the plan never holds a secret or customer data" \
  'Never write a secret, a token or a customer' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE"
expect "the comment goes to no Slack channel" 'Post to no Slack channel' \
  --answer "$JIRA" --answer "$W" --answer "$TICKET" \
  --answer "$NO_SRC" --answer "$NO_SLACK" \
  --answer "$NO_CODE" --answer "$NO_ONLINE" \
  --answer "$WROTE" --answer "$COV_YES"

# style: lines of 80 columns or fewer, functions of 40 lines or fewer, no ==,
# and no word "flow" in the rein files or the README.
# shellcheck disable=SC2016 # the awk programs read $0, not the shell
long=$(find "$root" -name '*.rein' -type f -exec env LC_ALL=en_US.UTF-8 awk \
  'length($0) > 80 { print FILENAME": "FNR }' {} +)
too_long=$(find "$root" -name '*.rein' -type f -exec awk \
  '/^export default/ { start = FNR; in_fn = 1 }
  in_fn && /^}/ { if (FNR - start + 1 > 40) print FILENAME": "start; in_fn = 0 }' \
  {} +)
eqs=$(find "$root" -name '*.rein' -type f -exec grep -n '==' {} +)
# A file name such as test-flow-rules.sh is not prose: no dash, dot or slash
# may touch the word.
flows=$( (find "$root" -name '*.rein' -type f; echo "$root/README.md") |
  xargs grep -inE '(^|[^-_./[:alnum:]])flow($|[^-_./[:alnum:]])')
if [ -z "$long$too_long$eqs$flows" ]; then
  echo "ok: style: lines, function length, no ==, no flow"
else
  echo "FAIL: style: $long $too_long $eqs $flows"
  fail=1
fi
exit $fail
