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
`.github/workflows/deploy.yml` fires on a `v*` tag and nothing else: verify, boot check, export,
upload, publish, then the GitHub release, in that order. **The deploy does not run the suite
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

**Publishing is a separate, deliberate act, and it needs its own go-ahead from the player in the
current session**; the standing merge permission is not release permission. Completed work may be
pushed without asking, since pushing `main` publishes nothing.

**Cut a release with `tools/release.sh <major|minor|patch>`**, which reads the latest version tag
and prints what it would do. It acts only when given a second literal `push` argument, and it
refuses a dirty tree, any branch but `main`, a `main` that is not level with `origin/main`, a
commit that already carries the newest `v*` tag, and a machine with no `gh` — every refusal fires
in the dry run too, so the dry run tells the truth about whether the real thing would work. **It
tags nothing until it has read the `test` check on `main`'s commit as green.** That check is CI's
last job (it needs every other job: classify, gates, hooks, cost-table, game, plan, shards, costs and browser), so it reads `none` for
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
telling anybody the page is well. The site serves whatever the newest tag points at, so `git tag
--list 'v*'` and `tools/release.sh`'s own dry run are what say whether a given commit is out there.
A release has carried a game-ending bug before (`tools/decisions.sh M73`).

**A browser fetches a new release whole.** The export publishes `index.js`, `index.wasm` and
`index.pck` under a directory named for the release tag, because GitHub Pages sends
`Cache-Control: max-age=600` on everything with no header surface to change it, and under fixed
names each file's ten minutes would run independently, pairing a fresh `index.html` with the
previous release's `index.pck` (`tools/decisions.sh M80`). So a report of a stale build is worth
believing rather than explaining away.
