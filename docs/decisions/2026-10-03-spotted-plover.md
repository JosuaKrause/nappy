# spotted-plover — release.sh never pushes on a check it could not read · 2026-10-03 · not from an entry

## What happened

On 2026-10-03 the player ran `./tools/release.sh minor push` right after a merge to `main`. For
three minutes the script printed `checks: none ... -- waiting`, which is normal: CI's `test` job
`needs` the classify, gates, cost-table, game and shards jobs, so its check-run registers only
once those finish (the last ten push runs of `ci` on `main`, measured 2026-10-03, took 7–8
minutes). Then one poll's GitHub read failed. The CLI's error was discarded, so the cause is
unknown; in the same minutes a separate `gh api` call from the orchestrating session hung for over
two minutes. `check_state` mapped "could not read" to
`unavailable`, which the push loop treated as "push anyway; the ruleset refuses the tag if main is
not ready". The ruleset did refuse (`Required status check "test" is expected`), leaving a local
`v0.22.0` and nothing published; a rerun after CI went green published fine. The `gh` CLI was
installed and authenticated, and its stderr was discarded, so nothing said why the read failed.

## Decision

The player: "let's fix the root cause."

- **An unread state never pushes.** `unavailable` waits like `pending` and `none`, under the same
  bound. Only `success` tags and pushes; `failure` and the end of the wait refuse. The ruleset is
  a backstop, not the gate.
- **The failure says what it was.** `check_state` keeps the first two lines of the CLI's stderr and
  the retry message prints them.
- **One read per poll.** The repository is resolved once, and retried like any read if that fails.
- **No `gh` at all is refused up front**, in the dry run too, since it cannot become available by
  waiting.
- **The wait limit stays at 1800 seconds.** Rejected: no limit at all — "no time limit at all is
  dangerous ... since it could hang indefinitely" — and the limit was never hit. It bounds an
  unattended or agent-driven run and sits well above CI's duration.
- The waiting lines say what `none` means (the test check has not started yet) and that nothing is
  tagged and Ctrl-C is safe.
