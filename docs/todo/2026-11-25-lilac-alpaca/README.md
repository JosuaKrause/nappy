priority: now
upnext: true

## lilac-alpaca — Release candidates: new features online on their own address, uncounted · filed 2026-11-25

**The ask.** The player: "can we do release candidates? so the online version plays the latest patch
but new features are for a release candidate with a different URL ?rc=1 or something and don't
count goatcounter etc" (inbox #1777 in tiny-newt). **What it is for:** "that way I can try out the
new tutorial without it being a proper release yet" (inbox #1778 in tiny-newt), the tutorial being
the queue entry grassy-beaver, "A day one that teaches". **When:** "implement that before releasing
the patch if still possible" (inbox #1779 in tiny-newt). **How it is served:** "how would the rc
process look like? how would we serve the two images? I guess a proper path allows to serve a
completely different binary" (inbox #1781 in tiny-newt). **When it ends:** "a minor release should remove the rc" (inbox #1783 in
tiny-newt).

**Read as:** the player leans to a proper path for the RC that serves a completely different build,
which is the `/rc/` below; `https://nappy.josuakrause.com/` keeps serving the newest release; a
release candidate (RC) is a second build, online beside it, that a person reaches by a different
address and that counts nothing ("etc" read as every counting the page does, not GoatCounter alone);
a minor release, and so a major one, takes `/rc/` down, so the deploy publishes no candidate until
the next RC is cut, while a patch release leaves the current candidate in place.

**Filed band and order: `now`, `upnext: true`** (the player's "before releasing the patch" puts
it first; the marker is the filer's way to say so). The queue move that starts the work drops the
marker.

**How a release works today** (`.claude/skills/committing/references/releasing.md`,
`.github/workflows/deploy.yml`, `tools/release.sh`): a `v*` tag fires one workflow that checks
the tagged commit's `test` check, exports the Web build, uploads `build/web` as the whole Pages
artifact and publishes it, then writes the GitHub Release from `tools/release-notes.py`. **A deploy
replaces the whole site**, so a second build online beside the release has to be in the same
artifact. The page's counting is GoatCounter's `count.js` in the export's `<head>`
(`html/head_include`, `export_presets.cfg`, counting the visit) and `VisitCounter`'s events
(`GoatCounterOutbox.may_ever_send()`: off the web, debug build, or `?debug=1` send nothing).
The save is one file under `user://`, which on the web is the origin's IndexedDB, so a page at
another path of the same origin shares the player's release save (`GameSave._uses_save()`).

**Proposed, not asked for** (the filer's proposals; each says its plainer alternative and its
cost, and the items below build them; none is a reading of the player's words):

- **An RC is a tag `vX.Y.Z-rc.N`**, the next release's number with a counter, cut by `tools/release.sh
  rc <major|minor|patch> push` (the part names the release it is a candidate for). Plainer: a
  branch or a manual workflow run, no tag. Cost of the tag: `release.sh`'s latest-tag read
  (`git tag -l 'v[0-9]*'`), `release-notes.py`'s tag pattern and `deploy.yml`'s `v*` trigger all
  have to learn that `-rc` is not a release; gain: the same `test` check gate, the ruleset and the
  build stamp apply unchanged.
- **Its build is served at a path beside the release, `/rc/`**: the player's lean (inbox #1781 in
  tiny-newt), a path serving a completely different build. **The root page forwards `?rc=1` there**
  is the filer's proposal, so the parameter the player gave as an example (inbox #1777 in
  tiny-newt) also works. Plainer: the path alone (cheap,
  the root page unchanged) or the parameter alone (the root page must pick between two builds in the
  browser before booting, and the forward is the only way to do that with Pages). Cost: the export
  and its page assume the site root today (`tools/export-web.sh` writes relative names, the
  `og:image` is absolute), so a build under a path needs a check that nothing else assumes the root.
- **A deploy always builds both and publishes both**: the newest release tag at the root and the
  newest RC under `/rc/` while its target number (the `X.Y.Z` of `vX.Y.Z-rc.N`) is above the
  release's. Pages keeps nothing between deploys, so an RC deploy must rebuild the release it sits
  beside. A patch release (`v0.30.1` under a candidate for `v0.31.0`) leaves the candidate's target
  above it and the candidate stays; a minor or major release reaches or passes every candidate's
  target, so the deploy publishes none, which is the player's rule (inbox #1783 in tiny-newt). Plainer: fetch the live site and overlay (fragile) or a branch holding the built site
  (a second thing to keep true). Cost: two exports and two browser checks in one run, so a deploy
  takes about twice as long.
- **An RC counts nothing, twice over**: its export drops `count.js` from the page (so not even the
  visit is counted), and `GoatCounterOutbox.may_ever_send()` refuses when the baked version names
  an RC, so a build served wrongly still sends nothing. Plainer: one of the two. Cost: the second
  is a few lines and a test row; it stops a count being possible rather than being unlikely.
  The run log (`Telemetry`) is behind the debug build already (`docs/TELEMETRY.md`) and needs no
  change; the entry's builder reads that document for any other counting before closing.
- **An RC keeps its own save**, a file name of its own, so trying a new tutorial never overwrites
  the day a player reached on the release, and a save a new feature wrote is never read by the
  release. Plainer: the RC does not save at all (nothing to overwrite, but a long try loses its day
  on a reload) or shares the release save (a newer save format could break the release's resume).
  Cost: a person who tries the RC starts from day 1 there, never from their release day.
- **The page says it is an RC**: the title screen's version text already shows the baked tag
  (`vX.Y.Z-rc.N`), so no new wording is needed. Plainer: a banner; cost: a cue to draw and review.
- **With no candidate published, `/rc/` and `?rc=1` lead to the release.** The root page always
  forwards `?rc=1` to `/rc/`, and the artifact then holds a `/rc/` whose page forwards to the root.
  Plainer: no `/rc/` at all, so both are a 404 until the next RC. Cost of leading to the release: a
  tester with an old bookmark plays the release without being told it is not the candidate (the
  title screen's version text shows which); cost of the 404: a dead address for days, which looks
  like a broken site.
- **The notes.** An RC's GitHub Release is marked a prerelease, its notes the commits since the
  last release (not since the last RC), so the final release's notes are unchanged.
- **The go-ahead: cutting an RC needs none; a release still needs its own, as today.** The
  orchestrating session told the player it would propose this: an RC changes nothing at `/`, which
  keeps serving the release, and counts nothing. Cost: any tag is published at once, so a wrong RC
  is online (at `/rc/`, linked from nowhere) until the next one replaces it; an RC tag cannot be
  deleted (the `version tags` ruleset blocks deletion), only superseded. **The alternative is the
  player's word for each RC**, as for a release. Cost: a question for a build only the player opens,
  and the tutorial's tries wait on an answer each time.
- **The `version tags` ruleset already covers RC tags.** It targets `refs/tags/v*`, so a
  `vX.Y.Z-rc.N` tag needs the same green `test` check on its commit and cannot be moved or
  deleted; nothing in the repository's settings changes.

**Order against the tutorial.** The RC mechanism is built before the grassy-beaver tutorial ships,
so the tutorial goes online as an RC first (the filer's proposal). The tutorial's pull requests may
still merge to `main`, which publishes nothing; what waits is the tag that would release it, and the
first RC cut after this entry lands carries it. The grassy-beaver entry is not edited.
