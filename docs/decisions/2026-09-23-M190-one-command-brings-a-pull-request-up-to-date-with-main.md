## M190 — One command brings a pull request up to date with main · built 2026-09-23

*(Asked for under CLAUDE.md's "a manual sequence done a second time becomes a script", after
every PR merged in a row on 2026-09-23 needed `main` merged into the next with the same
`docs/DECISIONS.md` conflict; the player: "yes", and "use it for subsequent prs".)*
`tools/update-pr.sh <pr-number | branch>` fetches, finds the branch's worktree or makes a scratch
one, records the three revisions, merges `origin/main` without committing, resolves the one
recurring `DECISIONS.md` shape with `tools/resolve-decisions-top.sh` and aborts naming the files
on anything else, then runs `git diff --cached --check`, lint and `check.sh`, commits a message
naming the revisions and the resolution, and pushes, over HTTPS when SSH is refused. It never
merges or enables auto-merge, and it ends by saying the semantic review is still the reviewer's,
listing what main changed. `--dry-run` reports conflicts through `git merge-tree` without touching
a worktree. It refuses a dirty worktree and a branch behind or diverged from its own remote.
**Open to overturn, chosen by the agent:** `UPDATE_PR_CLAUDE=1` adds the Claude co-author line,
off by default so a person running it does not sign as Claude; a diverged branch is refused as
well as one that is behind.
