## M70 — A run is a folder · built 2026-09-03

*(2026-09-03, playtest 22: "also repeating a day should create a new image. also instead of encoding
everything in the filename let's do folders instead", "so all files of a run stay together", "folder
should be `<day>/<commit>/<run>/<type>` where type is automated screenshot vs maps vs manual
screenshots log file lives directly in the run folder", "also no automatic cleanup anymore", "the
folder structure allows for easily deleting old days/commits".)*

**The whole run identity used to be repeated on every file.** `Telemetry.begin_run` built a stem —
`run-<timestamp>-seed<N>-<commit>`, or `rig-` when nothing human was at the controls — and every
artifact was that stem plus a suffix: `.log`, `-<clock>s-<kind>.png`, `-map-day<NN>[-dusk].png`, all
dropped flat into one directory. Files of one run were adjacent only by luck of the timestamp sorting
first.

**The layout is the player's and was given verbatim**, so nothing about its shape was inferred. Three
type subfolders named `maps`, `auto` (the periodic captures) and `asked` (the snapshot-key ones),
created lazily so an empty one never appears:

```
user://telemetry/2026-09-03/db09693-dirty/run-205437-seed2102613802/
├── run.log
├── maps/day06.png, day06-dusk.png, day06-attempt2.png
├── auto/019s-lost-lost_crying.png
└── asked/060s-asked.png
```

**The `<commit>` level lasted two hours.** *(2026-09-03: "hmm, the commit hash makes it hard to find
a run maybe let's remove it from the folder structure", then "and add a more granular timestamp as an
intermediate folder", "minute precision `<date>/<hour:minute>/...`".)* A folder per commit split one
day's runs across several folders, so listing a day did not list its runs — the exact thing the
milestone had just been built to fix, reintroduced one level down. The commit moved to the **tail** of
the run folder's own name, which keeps the one thing that level bought: `tools/telemetry.sh -p`
compares it against `git rev-parse --short HEAD` by path alone, without opening a log. It goes last so
the name still leads with its clock. A minute folder took its place, spelled `HHMM` rather than
`HH:MM` — the instruction was about precision, not punctuation, and a colon in a path is trouble on
macOS, where Finder renders one as `/`. The current shape is therefore
`<day>/<minute>/<run>/<type>/`, and `docs/TELEMETRY.md` is where it is described.

**And `tools/telemetry.sh -l` was wrong for those two hours.** It promises newest first; the sort key
was `<day>/<run folder name>`, and a run folder's name leads with `run-` or `rig-` rather than with
its clock, so every playtest sorted above every rig whatever time either happened — while the comment
beside it asserted that "the run folder leads with the full `HHMMSS` time of day". The key became the
day plus the time with that prefix cut off. **It was invisible until this milestone** because the
flat layout sorted by mtime, so no filename had ever been load-bearing for order.

**Two things had to survive the move and both were verified by hand rather than by test.** The
`run-` versus `rig-` prefix is load-bearing — a pile of logs that does not say which of them a person
played reads as a great many plays that never happened — and `tools/stats.sh` groups by it. And the
commit is in the path so `tools/telemetry.sh -p` can compare it against `git rev-parse --short HEAD`
and say what is stale, with a dirty tree written as the word `-dirty` because `*` is a glob character
in a shell.

**Automatic pruning is gone entirely** — `_prune`, `_remove_run` and the 50-log `KEEP_LOGS` cap — and
the player's reason is the structure itself: a tree of date, then commit, then run is one a person
can delete a whole day or a whole commit out of. So the directory grows without bound on purpose.
`tools/telemetry.sh -p` stays, because that is somebody running a command rather than the game
deciding behind them, and it now removes whole run folders and their emptied `<commit>` and `<day>`
ancestors instead of matching log-name patterns.

**A day replayed after a nerve used to overwrite its own map**, which destroyed exactly the picture
worth having: `write_map` built its path from the day number alone, and a lost day is retried without
the calendar advancing. Attempts are counted per day and folded into map and screenshot filenames.
**Chosen where the design was silent and open to overturn:** the count is a dictionary keyed by day
number rather than a single counter, so day 6's second attempt stays *attempt 2* even if other days
were played in between.

**The suffix was first written to appear only from the second attempt**, on the reasoning that a
first attempt's filenames should not churn. That lasted an hour: *(2026-09-03: "can we make the names
consistent and include attempt in all maps even for day one".)* Every picture now carries
`-attempt<N>`, first attempt included, because a suffix that appears only sometimes is two shapes to
read and two to match on — and the names had just been redesigned anyway, so there was nothing left
to protect from churn.

**The one thing it collided with was the evidence rule**, which said to keep a telemetry file's
original name because that name carried the timestamp, the seed and the commit. No single file
carries those now. **Chosen and open to overturn:** copy the whole run folder under `docs/evidence/`,
rather than inventing a rename convention for a lone extracted file. Once the commit moved into that
folder's name the copy stopped needing its ancestors to be identifiable, so what the rule asks for is
one self-describing folder rather than a path. The alternative is the rename convention, and it is
the one to pick if folder-per-finding turns out too heavy.
