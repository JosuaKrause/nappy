# freckled-gecko — A new name is checked against the open pull requests' branches · 2026-11-24

`tools/new-name.sh` checked a drawn pair only against the tree it ran in, so two branches cut
from the same `main` drew from one free set and could take the same name (pull requests #1700
and #1703 both took `2026-10-18-minty-quail-freckled-toad`; the second to merge renamed a record
by hand).

**What is built.** The script reads the open pull requests' branches (`gh pr list --state open`,
then `git ls-tree -r --name-only` of each head under `docs/todo`, `docs/decisions`,
`docs/review` and `docs/playtests`) and counts what they hold as used: a drawn pair is passed
over, and an entry's own `<entry>.md` that a branch already holds is treated as taken, so the
further file gets a pair. The local `origin/<branch>` is used only when it is the very commit
`gh` reports as the pull request's head (`headRefOid`), since a stale ref is the case the check
exists for; otherwise the head is read from that commit if it is held locally, else the branch
is fetched. A pull request from a fork (`isCrossRepository`) is skipped with a note, as is a
branch that cannot be read. With no git checkout, no `gh` or a failing `gh pr list` the script
says so on stderr and checks this tree alone, so it still works offline.

**Tried and rejected.** Fetching every branch into remote-tracking refs first: it changes the
checkout's refs for a read. A fetch into `FETCH_HEAD`: it overwrites the calling worktree's own
`FETCH_HEAD`. The fetch goes into a private ref, `refs/new-name/<pid>`, with
`--no-write-fetch-head`, and the ref is deleted after the read, so no ref of the checkout and
not its `FETCH_HEAD` is changed.

**Tests.** `tools/test_cli_help.sh` builds a scratch checkout with a `gh` stub: a pair held only
by an open branch makes the draw find nothing free, a second animal is drawn instead, a stale
`origin/<branch>` is passed over for the head `gh` reports (read by a fetch that leaves
`FETCH_HEAD` and `refs/` as they were), a fork's pull request and an unreadable branch are named
and skipped, and a failing `gh` is named and the draw goes on.