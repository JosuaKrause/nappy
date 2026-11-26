priority: now
upnext: true

## lilac-alpaca — Release candidates: new features online on their own address, uncounted · filed 2026-11-25

**The ask.** The player: "can we do release candidates? so the online version plays the latest patch
but new features are for a release candidate with a different URL ?rc=1 or something and don't
count goatcounter etc" (inbox #1777 in tiny-newt). **What it is for:** "that way I can try out the
new tutorial without it being a proper release yet" (inbox #1778 in tiny-newt), the tutorial being
the queue entry grassy-beaver, "A day one that teaches". **When:** "implement that before releasing
the patch if still possible" (inbox #1779 in tiny-newt).

**Read as:** `https://nappy.josuakrause.com/` keeps serving the newest release, and a release
candidate (RC) is a second build, online beside it, that a person reaches by a different address and
that counts nothing; "etc" is read as every counting the page does, not GoatCounter alone.

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
- **Its build is served at a path beside the release, `/rc/`, and the root page forwards `?rc=1`
  there**, so both the player's `?rc=1` and a stable address work. Plainer: the path alone (cheap,
  the root page unchanged) or the parameter alone (the root page must pick between two builds in the
  browser before booting, and the forward is the only way to do that with Pages). Cost: the export
  and its page assume the site root today (`tools/export-web.sh` writes relative names, the
  `og:image` is absolute), so a build under a path needs a check that nothing else assumes the root.
- **A deploy always builds both and publishes both**: the newest release tag at the root and, when
  an RC tag is newer than it, the RC under `/rc/`. Pages keeps nothing between deploys, so an RC
  deploy must rebuild the release it sits beside, and a release deploy drops the RC when the release
  is newer. Plainer: fetch the live site and overlay (fragile) or a branch holding the built site
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
- **The notes and the go-ahead.** An RC's GitHub Release is marked a prerelease, its notes the
  commits since the last release (not since the last RC), so the final release's notes are
  unchanged. **Cutting an RC needs the player's word in the session** (a request to put something
  online as an RC is that word) but no separate go-ahead beyond it, since it is served on an address
  nobody is sent to and counts nothing; **a release still needs its own go-ahead, as today.**
  Plainer: the release rule unchanged for an RC; cost: a second question for a build only the
  player opens.

**The unpublished v0.29.3** (its deploy was cancelled before it published, the site still serves
v0.29.2, and the tag exists). Both ways are the filer's proposal:

- **Publish it later by re-running its deploy once RCs exist.** The deploy workflow builds from the
  tag's own commit but runs the workflow file of the commit the re-run uses, which is the tag's, so
  the re-run would deploy with the old workflow and no `/rc/`; the RC mechanism has to land and a
  release deploy of the newest tag run after, or the re-run publishes v0.29.3 alone and the site
  loses nothing but gains no RC until the next tag. Cost: the patch waits for this entry.
- **Supersede it with the next patch** (v0.29.4, cut with the new workflow, covering v0.29.3's
  commits as a patch's notes do since the previous tag). Cost: a tag that never published stays in
  the history, and `tools/release.sh`'s patch bump skips a number.

The filer would pick the second only if the entry takes longer than the player wants to wait, and
otherwise re-run after the entry lands, since it publishes the commits the player already approved;
the choice, and the release itself, are the player's.

**Order against the tutorial.** The RC mechanism is built before the grassy-beaver tutorial ships,
so the tutorial goes online as an RC first (the filer's proposal). The tutorial's pull requests may
still merge to `main`, which publishes nothing; what waits is the tag that would release it, and the
first RC cut after this entry lands carries it. The grassy-beaver entry is not edited.
