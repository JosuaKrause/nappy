# The deploy publishes the newest release at the root and the current RC under `/rc/`

`deploy.yml` runs on RC tags too and builds the newest release tag and the current RC into one Pages
artifact: the release exactly as today, the RC under `rc/` with its own versioned directory. A minor
or major release publishes no RC; a patch release removes one only when it reaches that RC's target
number. The root page forwards `?rc=1` (its query kept) to `rc/`; when no candidate is published,
`rc/` holds a page that forwards to the root. Every browser check runs on each build. The RC's
GitHub Release is a prerelease with the notes since the last release.
`.claude/skills/committing/references/releasing.md` says so.
