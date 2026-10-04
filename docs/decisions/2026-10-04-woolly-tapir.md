# The browser check runs in CI before a release · built 2026-10-04

*([crisp-lemur](../playtests/2026-10-04-crisp-lemur.md), inbox #550: "That seems to be a bigger issue
than missing notes", then "Let's fix and release a patch".)*

**Why.** The v0.25.0 deploy failed in `tools/web-template/browser-check.mjs` (load the page, wait for
day 1, press Space, wait for the day save): busy-hedgehog (#538) armed its input block on the page's
first focus at load and dropped the Space. The check ran only in the deploy, after the tag, and in
`web-template.yml` on changes to the template's own files, so code under `src/` could merge and be
tagged without ever booting in a real browser. The fix to the input block is #548; this is the fix to
the gap.

**What was built** (PR #551). A `browser` job in `.github/workflows/ci.yml`, on every pull request
that is not docs-only and every push to `main`: it restores the custom web template from the deploy's
cache key (or builds it), exports with `tools/export-web.sh`, and runs `browser-check.mjs` with the
deploy's arguments, uploading its screenshots and `result.json` when it fails. `test` needs it, so
`test` is green only if the browser check passed or was skipped as docs-only; the `version tags`
ruleset, `tools/release.sh` and the deploy's `verify` job already read `test` by name, so a commit
that fails in the browser cannot be tagged. The steps the deploy, `web-template.yml` and the new job
share live in one composite action, `.github/actions/web-browser-check/action.yml`, which takes the
Godot version from `tools/web-template/pins.env`. The **verify** skill lists the check and what it
cannot see; the **committing** skill's release section says `test` covers it.

**Measured** on the PR: the job takes about a minute and a half with the caches warm and runs beside
the shards, so a run's wall clock did not move; a template cache miss adds about fifteen minutes of
compiling. A temporary commit that re-armed the input block at load failed only this job, with the
deploy's own error, and was reverted.

**Not yet seen:** the deploy's use of the shared action, which first runs at the next tag.
`web-template.yml` ran the same action on the PR.
