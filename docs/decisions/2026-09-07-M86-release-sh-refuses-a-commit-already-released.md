## M86 — `release.sh` refuses a commit already released · built 2026-09-07

Asked as a question rather than reported as a defect *(2026-09-07: "btw what happens when running
release twice? it should block if main is on a current release")*, and the answer was that
`tools/release.sh patch push` run twice from an unchanged `main` cut two tags from the **same
commit** and published the same build twice. Every refusal the script had was about the tree and the
branch — a dirty working tree, a branch other than `main`, a `main` not level with `origin/main` —
plus a wait on the `test` check. Nothing asked whether the commit about to be tagged already carried
a version tag.

**The refusal is on the commit, not on the version.** If `origin/main`'s HEAD is what the newest
`v*` tag points at, there is nothing to publish and the script stops, naming the tag that already
points there.

Three details decide whether it works at all, and each was a way to write it wrong:

- **It fires in the dry run**, because the script's own contract is that *"every refusal fires
  whether or not `push` was given, so the dry run tells the truth about whether the real thing would
  work."* A refusal that only appeared under `push` would make the dry run lie in exactly the case
  somebody runs it for. It is placed with the other refusals, above the confirmation branch.
- **An annotated tag is dereferenced with `^{commit}` before comparing.** The tag object is not the
  commit it names, so a comparison against the tag's own sha would silently never match and the
  check would never fire.
- **A failed `git rev-parse` is refused explicitly rather than left to fall through.** The script
  runs under `set -uo pipefail` without `-e`, so a failing command carries on to the next line — an
  empty result would read as "not the same commit" and let a second release through. That is the
  same fall-through the script's own header already records for the push path.

**No override flag for re-releasing a commit whose deploy failed**, and the reason is that the case
is already covered: a rejected push leaves the annotated tag in place and tells the operator to
retry `git push origin <tag>`. Open to overturn if a case turns up that this misses.
