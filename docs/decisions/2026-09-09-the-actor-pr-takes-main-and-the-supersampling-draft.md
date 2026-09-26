## The actor PR takes main and the supersampling draft — 2026-09-09

The player asked for PR #49 to land on `main` soon, for its skills and tooling, with the graphics
kept behind the illustrated opt-in, and for the supersampling draft to travel with it so the work
stays in one place. *(2026-09-09: "can we get the illustrated-supersampling branch … merged into
this PR so it stays together fully? out of order playtests are fine -- what matters is the
numbering makes sense and PRs only add higher numbers".)*

`feature/illustrated-supersampling` (one commit past the PR branch's own `bb03202`) merged into the
PR branch first. Its one conflict was the repair brief's resolution paragraph; the result documents
the `--illustrated-render-scale 2` command and states the experiment is unverified. The draft
removes the `--illustrated-zoom` camera prototype and its tests. The Canvas/ObjectDB leak the
draft's handoff had left open to investigate was the orientation suite's own hand-built
downsample layer, never freed at the end of the furniture test; the pre-merge tip ran the same
suite clean, and freeing it restores a clean exit.

`main` had merged its own playtest 39 (the tunnel, PR #55) after the branch last took `main`
(`33c45f9`). The branch's playtest 39 (the animation-capture request, same date) moved to **46**,
the first number unused on either tip; only its title and the one archive sentence citing it
changed. Main's playtest 39 kept its number and references. The `TODO.md` conflict kept main's
tunnel paragraph, reworded so it no longer claims to be the newest session of all, beside the
branch's one-line halo pointer; the `DECISIONS.md` conflict kept both sides' prepended sections.

Two handoff sentences would have been false at the merge commit and were fixed in the same merge:
the Luna handoff told readers to keep PR #49 a draft and not merge it, and the main handoff pointed
at a local worktree path for the supersampling draft.
