# `tools/release.sh` cuts an RC tag and every reader of tags ignores it as a release

`tools/release.sh rc <major|minor|patch> push` tags `vX.Y.Z-rc.N` on the commit it releases today
(same refusals, same wait for the `test` check), the next release number being the latest *release*
tag bumped by the part and N one above the last RC for that number. `release.sh`'s latest-tag read,
`tools/release-notes.py`'s tag pattern (its range is the previous release tag, never an RC) and
anything else that lists `v*` tags read only release tags. `--help` and the tool's tests say so.
