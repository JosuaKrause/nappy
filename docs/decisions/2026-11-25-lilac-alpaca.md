# lilac-alpaca — Release candidates: new features online on their own address, uncounted · 2026-11-25

The player asked for release candidates: the site keeps playing the latest release while new
features go to a candidate at a different address, counting nothing in GoatCounter (inbox #1777 in
tiny-newt), so a new tutorial can be tried online before it is a release (inbox #1778 in
tiny-newt), served at a path of its own as a completely different build (inbox #1781 in tiny-newt),
and taken down by a minor release (inbox #1783 in tiny-newt). The entry's design was the filer's
proposal throughout, and it was built as written but for the points marked below.

**What was built.**

- **The tag.** `tools/release.sh rc <major|minor|patch> [push]` cuts `vX.Y.Z-rc.N`: the release the
  part names, with a counter one above the last candidate for that number. Same refusals and the
  same wait for `test`, plus two: a commit that already carries any version tag is refused, since a
  candidate there publishes nothing new, and so is a candidate the deploy would never serve because
  a higher one is out (`rc patch` beside a minor candidate), asked of `tools/release-tags.py site
  --as-if <tag>@<commit>` before anything is tagged. A release on a candidate's commit passes, which
  is how a candidate becomes the release.
- **One reader of tags.** `tools/lib_release_tags.py` holds the grammar of both kinds of tag and the
  rules that follow from a set of them, and `tools/release-tags.py` is its command line (`latest`,
  `next <part> [--rc]`, `kind`, `site`). `tools/release.sh` reads its latest release and next tag
  there; before, its `git tag -l 'v[0-9]*' | sort -V` would have taken `v0.30.0-rc.1` for the newest
  tag after `v0.30.0`. `tools/release-notes.py` accepts a candidate's tag and gives it its target's
  range, never counting a candidate as a previous tag, so a candidate's notes are the ones its
  target release would have (since the previous release for a patch candidate, since the previous
  `.0` for a minor or major one) and the release after its candidates keeps the notes it would have
  had. `kind` answers `none` for a name that is no version tag, with exit 0, so a caller tells that
  from a failure to ask.
  `tools/goatcounter.py --by-release` opens no window for a candidate.
- **The deploy.** `.github/workflows/deploy.yml` fires on both kinds of tag and publishes the whole
  site every time, since Pages keeps nothing between deploys: a `plan` job asks
  `tools/release-tags.py site` for the newest release and the candidate to serve, `build-release`
  and `build-candidate` each check out their own tag's commit and run that commit's own
  `web-browser-check` recipe (export and Chrome check), and `assemble` lays the two out with
  `tools/assemble-site.py` into one Pages artifact. The two builds run on two runners side by side
  rather than one after the other. A candidate's GitHub Release is a prerelease.
- **What the deploy does when something fails.** The `plan` step runs under `pipefail`, `site`
  refuses rather than print an empty release, and the answer is checked line by line before it
  reaches the job's outputs; `build-release` refuses an empty release name again, since an empty
  `ref` would check out the pushed tag, on a candidate's push the candidate with `count.js`, for the
  root. `deploy` and `release` carry an explicit condition on their direct need, because the
  implicit one also looks past it and skips both whenever `build-candidate` is skipped
  (actions/runner#2205), which is every deploy with no candidate out. **A candidate whose build
  fails never holds a release back**: `assemble` runs whenever the release built and hands
  `tools/assemble-site.py` the candidate build's result and the pushed tag's kind; on a release's
  deploy it lays the release out alone, `rc/` forwarding to the root, and says so in the job's
  summary, and on a candidate's deploy it refuses, so nothing new is published and the live site
  stays as it was. The release is what needs the player's go-ahead and a candidate needs none, so
  the candidate is the one that waits.
- **Which candidate is served.** The newest candidate whose number is above the newest release's,
  so a patch release removes one only once it reaches that number; and a minor or major release
  removes every candidate cut before it, whatever its number.
- **The forwards.** The root page forwards `?rc=1` to `rc/` with its query kept; with no candidate
  out, `rc/` holds a page that forwards to the root, its query kept but for `rc`.
- **Counting nothing, twice.** `tools/export-web.sh` takes the `count.js` script off a candidate's
  page (asserting it found exactly one and that nothing naming GoatCounter is left), and
  `GoatCounterOutbox.may_ever_send()` takes the build's version and refuses one that names a
  candidate (`BuildInfo.names_a_release_candidate()`), the version reaching the counter through
  `GoatCounterPlatform.build_version()`, which has no default, since a release's shape there would
  count. The run log needed nothing: it is a debug build's alone
  (`docs/TELEMETRY.md`), and a candidate is a release build. Nothing else on the page counts.
- **A save of its own** (the filer's proposal). `GameSave.player_path()` gives a candidate
  `user://save-rc.json`, which `main` hands the save it builds; every candidate shares that one file, so the next candidate
  resumes the last one's day. `GameSave`'s constructor now always takes its path.
- **The marker.** The title screen's version line already shows the baked tag, `vX.Y.Z-rc.N`, as the
  entry proposed; no new wording or cue was added.

**Where the build departed from the entry's text, and why.**

- **The root's `?rc=1` forward is written by the deploy's assembly, not into the export's
  `html/head_include`.** The release at the root is a build of its own tag's commit, which may be
  older than the forward: the first candidate after this lands sits beside `v0.29.3`, whose page
  has no forward of its own. The empty `rc/` page is written there for the same reason.
- **"A minor release removes the candidate" is read from the history, not from dates.** A
  candidate is removed when its commit is the newest `.0` release's commit or an ancestor of it
  (`git merge-base --is-ancestor`), so a deploy re-run and every machine answer the same, and a
  candidate cut after the minor release is served again.
- **"Names an RC" means exactly `vX.Y.Z-rc.N`, read from the version an export baked.** The save
  and the counter ask `BuildInfo.exported_version()` (`application/config/version`), never `git
  describe`, so a developer's checkout sitting exactly on a candidate's tag, which describes as that
  tag, keeps the release's save; on a working tree that setting is `project.godot`'s placeholder.
  Only an exported candidate is one: the deploy's, or a local export of a candidate's tag. `git
  describe` past a candidate's tag (`v0.31.0-rc.1-3-gab12cd3`, or one ending `-dirty`) names none
  either. The version line is left reading every tag, so a developer's may name the nearest
  candidate.
- **`tools/release.sh` and `tools/export-web.sh` now need `uv`**: the tag arithmetic and the
  candidate check are `tools/release-tags.py`'s, and a machine that cannot ask is refused rather
  than guessing that a tag is no candidate, which would put the counter on a candidate's page.
  `export-web.sh` asks before any work and refuses a `uv run` that fails or an answer that is no
  kind, as well as a missing `uv`.

**Verified.** `tools/test_release_tags.py` (the grammar, the arithmetic, which candidate is served,
and the command line on a throwaway repository, where the ancestor question is git's),
`tools/test_release_notes.py` (a candidate's range, a release's after its candidates, a patch
candidate's), `tools/test_assemble_site.py` (the dry run of the assembly on stand-in exports, a
failed candidate on a release's deploy and on a candidate's), `tools/test_cli_help.sh`'s
`export-web.sh` refusals with a stand-in `uv` that fails and one that answers no kind,
`tools/test_goatcounter.py`, `tools/test_cli_help.sh`'s new `release.sh rc` refusals and
`tools/test_cli_help.py`'s two new entry points; `tests/test_build_info.gd`, the outbox's refusal
and a candidate's page counting nothing in `tests/test_visit_counter.gd`, and the save's file name
in `tests/test_save.gd`, and a working tree reading as no candidate in
`tests/test_build_info.gd`. A local debug export with `RELEASE_TAG=v0.30.0-rc.1` left no
`goatcounter` anywhere on its page, and `tools/assemble-site.py` laid that real export out with
the forward first in its `<head>`. The deploy itself runs only on a pushed tag: the first
candidate after this merges is its first run.
