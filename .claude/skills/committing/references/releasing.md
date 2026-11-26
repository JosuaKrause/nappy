# Releasing

The detail behind **committing**'s "Releasing": what CI and the deploy check, how the notes are
generated, what `tools/release.sh` refuses, and why a browser fetches a release whole. Read it
before cutting a release or answering whether a commit is live.

**A push is a check and a tag is a release.** `https://nappy.josuakrause.com/` serves the game.
`.github/workflows/ci.yml` runs lint, check, the full suite, sharded, and the browser check — the
release Web export, built and played in Chrome exactly as the deploy builds and plays it — on
every push to `main` and every pull request but a docs-only one, which gets the consistency checks
alone (**verify**)
— a new push to a pull request cancels that pull request's older runs, and a run on `main` is never
cancelled. A push to `main` is never docs-only, so the commit a tag points at has had every check.
`.github/workflows/deploy.yml` fires on a `v*` tag and nothing else: verify, plan, boot check and
export and browser check of each build, assembly, publish, then the GitHub release, in that order. **The deploy does not run the suite
again.** The `version tags` ruleset requires the `test` check on the commit a tag points at, so a
tag on a red or untested commit cannot be pushed, and the deploy's first job asks the API for that
check's outcome and refuses to build without it — the same read `tools/release.sh` waits on before
it tags. So a commit that fails in the browser cannot be tagged at all; the deploy's own browser
check, on the very files it publishes, is the second look rather than the first.

**The release's notes are generated, not written.** The deploy's last job runs `tools/release-notes.py
<tag>` — deterministic from git alone, no model and no network call to compute — and publishes its
Markdown as the tag's GitHub Release (`gh release create --notes-file`, or `gh release edit` when a
release for that tag already exists, so a re-run of the deploy is idempotent). One bullet per
commit's own subject line on `main`'s first-parent history, grouped into a Game and a Tooling and
docs section by what each commit changed. A patch tag (`vX.Y.Z`, `Z>0`) covers everything since the
previous tag; a minor tag (`vX.Y.0`) covers everything since the previous `.0` tag, folding in every
patch between them, and a major tag is treated the same way. `tools/release.sh`'s dry run previews
the same notes before anything is tagged.

**A release candidate is a second build online beside the release, at
`https://nappy.josuakrause.com/rc/`** (inbox #1777 in tiny-newt, inbox #1781 in tiny-newt), so
a new feature can be played online before it is a release. It is a tag `vX.Y.Z-rc.N`, the release
it is a candidate for with a counter, cut by `tools/release.sh rc <major|minor|patch>` with the same
refusals and the same wait for `test`, plus one: a commit already carrying a version tag is
refused, since a candidate there publishes nothing new. **Pages keeps nothing between deploys, so
every deploy publishes the whole site**: the newest release at the root and, when one is out, the
newest candidate under `rc/`, each exported and played in Chrome from its own tag's commit with that
commit's own recipe, and laid out by `tools/assemble-site.py`. Which two is
`tools/release-tags.py site`'s answer: a candidate stays while its number is above the release's,
so a patch release removes one only once it reaches that candidate's number, and **a minor or major
release removes every candidate cut before it**, whatever its number (inbox #1783 in tiny-newt). The
root page forwards `?rc=1` to `rc/`, and with no candidate out `rc/` forwards to the root. **A
candidate counts nothing** (inbox #1777 in tiny-newt): its page carries no `count.js` and the game
refuses to send its events (`docs/TELEMETRY.md`, "The page counts visits"); it keeps a save of its
own (`docs/MECHANICS.md`, "Saving and resuming"); and the title screen's version line names it
(`vX.Y.Z-rc.N`). Its GitHub Release is a prerelease whose notes run since the last release, never
since the last candidate, so the release that follows its candidates has the notes it would have had
without them. The `version tags` ruleset targets `refs/tags/v*`, so a candidate's tag needs the
same green `test` and can be neither moved nor deleted, only superseded by the next one.

**Publishing is a separate, deliberate act, and it needs its own go-ahead from the player in the
current session**; the standing merge permission is not release permission. **Cutting a candidate
needs none** (the filer's proposal, lilac-alpaca): a candidate changes nothing at the root, which
keeps serving the release, and counts nothing, so a wrong one is online only at an address linked
from nowhere until the next candidate replaces it. Completed work may be
pushed without asking, since pushing `main` publishes nothing.

**Cut a release with `tools/release.sh <major|minor|patch>`**, which reads the latest release tag
(`tools/release-tags.py latest`, never a candidate) and prints what it would do. It acts only when given a second literal `push` argument, and it
refuses a dirty tree, any branch but `main`, a `main` that is not level with `origin/main`, a
commit that already carries the newest release tag, and a machine with no `gh` or `uv` — every refusal fires
in the dry run too, so the dry run tells the truth about whether the real thing would work. **It
tags nothing until it has read the `test` check on `main`'s commit as green.** That check is CI's
last job (it needs every other job: classify, gates, hooks, `cost-table`, game, plan, shards, costs and browser), so it reads `none` for
the first minutes after a merge and the `push` form waits, polling every 20 seconds. A read that
fails is retried with `gh`'s own error printed, never taken as a pass; a failed check refuses, and
so does a check still not green after 30 minutes, a bound that exists so an unattended run cannot
hang forever and that a normal run never reaches. Ctrl-C while it waits is safe, since nothing is
tagged yet. Semver, and **`major` is reserved for a change that breaks or fundamentally alters the
game**. An agent's own `push` run goes through
`uv run python tools/agent-identity.py run claude-coder -- tools/release.sh <part> push` (Codex the
same as `codex-coder`) — "Who a commit and a pull request are from" is why, and
`.claude/hooks/github-write-guard.sh` denies the bare form. The player's own run at their own
terminal is unwrapped either way (`tools/lib_agent_role.sh`'s `agent_run` only wraps when
`NAPPY_AGENT_ROLE` is set); the player's own go-ahead above is what release still needs regardless
of who types the command.

**A fix on `main` is not a fix on the site**, and that is the sentence to keep in mind before
telling anybody the page is well. The site's root serves whatever the newest release tag points at, so
`tools/release-tags.py site` and `tools/release.sh`'s own dry run are what say whether a given
commit is out there, at the root or under `rc/`.
The record of why is `tools/decisions.sh M73`.

**A browser fetches a new release whole.** The export publishes `index.js`, `index.wasm` and
`index.pck` under a directory named for the release tag (a candidate's under `rc/` in a directory
named for its own), because GitHub Pages sends
`Cache-Control: max-age=600` on everything with no header surface to change it, and under fixed
names each file's ten minutes would run independently, pairing a fresh `index.html` with the
previous release's `index.pck` (`tools/decisions.sh M80`). So a report of a stale build is worth
believing rather than explaining away.
