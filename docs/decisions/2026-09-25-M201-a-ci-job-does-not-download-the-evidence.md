## M201 — A CI job does not download the evidence · built 2026-09-25

*([PLAYTEST-137](../playtests/PLAYTEST-137.md): "one shard took significantly longer than the rest --
maybe we need to balance that again".)*

**The slow shard was its checkout, not its tests.** Every CI job checked out the whole tree at
`HEAD`, about 949 MB, of which about 910 MB is `docs/evidence/`, and the shallow fetch took
anywhere from about 35s to 670s per job; the 853s shard spent 667s fetching. Rebalancing the
shard plan was the player's first guess and would not have moved it.

**What is built.** Every `actions/checkout` that runs code is a partial clone (`filter:
blob:none`: commits and trees up front, blobs only for checked-out paths) with a non-cone sparse
checkout of `/*` and `!/docs/evidence/`. `ci.yml`'s `gates` job re-includes
`/docs/evidence/**/*.svg`, because `tools/lint.sh` parses every tracked SVG, 93 of which are under
the evidence; the `shards` job and `deploy.yml`'s `build` job take none of it. Nothing else CI
runs reads the evidence: the `tests/*.gd` mentions are doc comments naming where a probe writes,
probes are never run in CI, `docs/` carries a `.gdignore`, `tools/test_rules_hooks.sh` writes its
own scratch file there, and the web export reads nothing under `docs/`. `git ls-files` still lists
every tracked path in a sparse tree, so the lint's list of SVGs is complete.

**Measured** on the pull request: the `gates` checkout took 4s on two runs, and every shard's
2–13s on the first and 2–5s on the second, against 32–670s on `main` before. The fetched size is an accounting against the tree (about 42 MB outside the
evidence plus 372 KB of SVGs), not a byte count read off a log, since a blob:none fetch prints
none. **Unexercised**: the deploy job's checkout runs only on a version tag, so the next release
is its first run.
