# Playtest crisp-lemur — The browser check runs before a release

2026-10-04. One note captured in the session, #550, after the v0.25.0 deploy failed. Each of the
player's words is copied word for word, after what it answered.

## #550 — The browser check runs before a release, not only in the deploy

Said on 2026-10-04 after the v0.25.0 deploy failed: busy-hedgehog (#538) armed its 500ms input
block on the page's first focus at load, so the deploy's browser check
(`tools/web-template/browser-check.mjs`: load, wait for day 1, press Space, wait for the save) lost
its Space and timed out. The check runs only in the deploy and in `web-template.yml` (on changes to
the web template's own files), not in a PR's CI, and neither #538's brief nor its review asked for
it. Offered: a verify-skill rule that a change to input, focus or boot runs the browser check before
it merges, or running the browser check in PR CI.

> That seems to be a bigger issue than missing notes

Proposed on 2026-10-04: a `browser` job in the main CI on every PR that changes `src/` or `tests/`
and on every push to `main`, building the release export as the deploy does and running
`browser-check.mjs`; the `test` check (which the tag ruleset and `tools/release.sh` already require)
waits for it, so a commit that fails in the browser cannot be released; a few extra minutes per code
PR, the web template cached by its key. "Shall I file it and build it now?"

> Let's fix and release a patch

## Routing

**#550** → built in the pull request that files it, with no queue entry: the `browser` job in
`.github/workflows/ci.yml`, recorded under its own decision; then a patch release.
