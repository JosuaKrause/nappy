# freckled-gecko — A new name is checked against the open pull requests' branches · 2026-11-24

`tools/new-name.sh` checked a drawn pair only against the tree it ran in, so two branches cut from
the same `main` drew from one free set and could take the same name (pull requests #1700 and #1703
both took `2026-10-18-minty-quail-freckled-toad`; the second to merge renamed a record by hand).

**What is built.** The script reads the open pull requests' branches (`gh pr list --state open`,
then `git ls-tree -r --name-only` of each head under `docs/todo`, `docs/decisions`, `docs/review`
and `docs/playtests`) and counts what they hold as used: a drawn pair is passed over, and an entry's
own `<entry>.md` that a branch already holds is treated as taken, so the further file gets a pair.
A head with no `origin/<branch>` ref is fetched by name; one that still cannot be read is skipped
with a note on stderr. With no git checkout, no `gh` or a failing `gh pr list` the script says so
on stderr and checks this tree alone, so it still works offline.

**Tried and rejected.** Fetching every branch into remote-tracking refs first: it changes the
checkout's refs for a read. A per-branch `git fetch` into `FETCH_HEAD` leaves them alone and is
made only for a head not already known.

**Tests.** `tools/test_cli_help.sh` builds a scratch checkout with a `gh` stub: a pair held only
by an open branch makes the draw find nothing free, a second animal is drawn instead, an unreadable
branch is named and skipped, and a failing `gh` is named and the draw goes on.
