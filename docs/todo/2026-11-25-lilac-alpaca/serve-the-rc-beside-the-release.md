# The deploy publishes the newest release at the root and a newer RC under `/rc/`

`deploy.yml` runs on RC tags too and builds the newest release tag and, when an RC tag is newer,
the RC, into one Pages artifact: the release exactly as today, the RC under `rc/` with its own
versioned directory. The root page forwards `?rc=1` (its query kept) to `rc/` only when the artifact
holds one. Every browser check runs on each build. The RC's GitHub Release is a prerelease with the
notes since the last release. `.claude/skills/committing/references/releasing.md` says so.
