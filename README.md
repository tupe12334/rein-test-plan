# test-plan

A [Rein](https://github.com/tupe12334/rein) program. It builds a test plan for a feature. It finds the ticket of the feature, then collects the facts about it from Fathom meetings, Slack, the linked pull requests and public docs. It writes the plan as a markdown file in a work folder, checks that every acceptance criterion and every risk has a test case, and posts the plan as a comment on the ticket.

## Install

```sh
rein install -g github:tupe12334/rein-test-plan#v0.1.0
```

## Use

A caller awaits the program with the feature. The `const` needs a doc comment above it:

```text
/** Build the test plan of a feature, and post it on its ticket. */
const plan: string = await @test-plan/main(feature=<feature>);
```

- `feature`: a Jira key or link, a GitHub or Linear link, or a short feature name.

The answer is one line: `Return: plan <path>. Comment <link>.`, or `Return: plan <path>. The comment failed.`, or `Return: no ticket for ...`. A missing ticket writes nothing, and the agent asks the user for the ticket key or link.

## Process

1. The ticket is found (`main.rein`). Jira is searched first (`find_jira.rein`), then GitHub issues in the repo that the feature names (`find_github.rein`), then Linear (`find_linear.rein`). A search that finds exactly one ticket ends the search. A search that finds two or more tickets finds none, and the next tracker is searched. A key that Jira and Linear both hold is ambiguous, so it finds none in both. A feature with no ticket asks the user for the ticket, and the process stops.
2. A work folder is made with its notes file and its plan file (`run_plan/make_work.rein`, `scripts/make-work.sh`). The folder is under the home folder, in `test-plan-work`.
3. The ticket is read into the notes, with its acceptance criteria, its sub-tasks, its linked pull requests, its docs and its people (`read_ticket.rein`).
4. Four sources are collected into the notes. Each is a function of its own, and each answers whether it found a fact. A source with nothing is not an error:
   - `collect/meetings.rein`: Fathom and claude.ai Meetings. Requirements, decisions and edge cases said aloud.
   - `collect/slack.rein`: messages, threads, call notes and canvases. It never posts.
   - `collect/code.rein`: linked pull requests and branches. Changed screens, APIs, flags, permissions and data migrations. It changes no code.
   - `collect/online.rein`: public docs, such as product help pages, WCAG and third-party API docs.
5. The plan is written (`write_plan.rein`). It has a summary, scope, ranked risks, environments and test data, test cases with priority and type, a coverage matrix, and open questions. Each fact carries its source link.
6. The coverage is checked (`check_coverage.rein`). Every acceptance criterion and every risk needs one test case.
   - A plan that is not covered goes to a second pass (`revise_plan.rein`), then to a third and last pass (`revise_again.rein`).
   - After the third pass, the gaps that remain are listed as open questions (`list_gaps.rein`). The plan is delivered with them.
7. The plan is posted as a comment on the ticket (`deliver.rein`, `deliver/post_plan.rein`). The tracker tool is found at run time: Atlassian tools for Jira, `gh` for GitHub, the Linear tools for Linear. No Slack message is posted. The plan file stays in the work folder.

## Outward action

The comment on the ticket reaches the team. The program posts only when a caller awaits it. It posts one comment per run.

## Accepted risks

- The ticket match, the source answers and the coverage answers are agent answers. A wrong match or a missed fact reaches the plan. Each fact carries its source link, so a reader can check it.
- The plan is posted as it is written, after a check for secrets and personal data in the plan. The check is an agent answer.
- The gaps after three passes are listed, not closed. A reader must still read the open questions.

## Known limits

- The rein check reports nine warnings. Eight say that single-caller verbs at `collect/`, `deliver/` and `run_plan/` could move into their caller's folder. The paths follow the design, so they stay. The ninth asks for an empty line before an `if` in `run_plan.rein`: `run_plan` is at the 40-line limit, so the line is not added.
- The package has no peer dependencies. The program hands off to its own verbs only.
- The walks check the text of each rule, not the answers. The answers are checked by a run.

## Develop

Run `git config core.hooksPath .githooks` once. Pushes then run `rein check .`, `scripts/test-flow-rules.sh` and `shellcheck`. `scripts/test-flow-rules.sh` walks the entry offline with fixed answers and checks each text. It also checks the line length, the function length, the absence of `==` and the absence of the banned word for a process. The sabotage scripts invert one rule in a copy and check that a walk fails:

- `scripts/sabotage-coverage.sh`: a covered plan goes to a second pass.
- `scripts/sabotage-ticket-search.sh`: a found Jira ticket still searches GitHub.
- `scripts/sabotage-pass-bound.sh`: the second pass never stops at three passes.
- `scripts/sabotage-style.sh`: a branch uses `==`.

## License

MIT
