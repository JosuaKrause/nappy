# new-name.sh draws a record name unique only against its own branch, so two branches take the same one

`tools/new-name.sh` makes a decision's or a review item's name (`<entry>-<adjective>-<animal>` when `<entry>.md` is taken) and checks that the pair is unused only against `docs/todo`, `docs/decisions`, `docs/review` and `docs/playtests` in the tree it runs in. Two branches cut from the same `main` therefore draw from the same free set, and can draw the same pair.

**How it shows:** pull requests #1700 and #1703 both took `2026-10-18-minty-quail-freckled-toad`; whoever merged second had to rename a record by hand. While the refactor runs, parallel builders each file a record on their own branch, so it recurs.

**What would fix it:** the script also reads the names that the open pull requests' branches already hold: `gh pr list --state open --json headRefName`, then `git ls-tree -r --name-only origin/<branch> docs/todo docs/decisions docs/review docs/playtests` for each, treating those names as taken. A branch it cannot read (no network, no `gh`, a missing identity) is skipped with a note on stderr rather than failing the draw, since the script is also used offline. This is the filer's proposal, not something the player asked for. The tool's tests and its `--help` are updated as **cli-tools** says.

**Why the band is `now`, with no `after:`:** minty-quail's entry exempts work on a general project script from its wait (inbox #1305 in grassy-trout), and this defect costs the refactor itself, since its parallel builders are what collide. It can be built beside the refactor.
