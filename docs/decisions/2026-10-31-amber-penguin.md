# amber-penguin — Codex support frozen while it is not in use · 2026-10-31 · not from an entry


The player froze Codex support on 2026-10-31, not using Codex at the time (inbox #901 in freckled-moose). Codex's last
commit here was on 2026-10-08, 23 commits in all. Measured that day: `tools/codex-hooks.py` 252 lines
and its tests 887, `.codex/hooks.json` and `config.toml`, the Codex model reference, the `codex-coder`
and `codex-reviewer` identities, about 98 mentions across twelve skills, and CLAUDE.md's Codex section,
about 340 words loaded in every session. The orchestrating session proposed freezing over removing, so
Codex is cheap to bring back; removing would also have closed the one route for generating a raster
image (**illustrated-png**).

**What changed.** CLAUDE.md's section became a short note that the files stay and nothing keeps them
in step; the requirement that a hook change update the adapter was lifted. The skills' Codex asides
were left as they were.

**The section as it stood while Codex was in use**, to restore when it comes back:

> ## Codex integration
>
> Codex finds the skills through `.agents/skills`, a link to `.claude/skills`, and runs the same hook
> scripts through `.codex/hooks.json` and the adapter `tools/codex-hooks.py`: it loads the rules for
> every path a patch touches, rename destinations included, lints each edited doc, denies an unbounded
> `git grep` on Codex's own Bash calls the same way Claude Code's does and a GitHub write outside an
> agent's own identity every time, even an ordinary one that Claude Code's guard, once the player
> switches its asking on, asks them about instead, and reloads the startup rules on session start,
> resume, compaction and subagent start. **A change to a hook script under `.claude/hooks/` or to the
> hooks in `.claude/settings.json` checks whether the adapter and its tests need to change — a new
> tool name, payload field or hook event — and updates them in the same PR when they do** (brisk-heron
> 6), because Codex names its tools differently (`apply_patch` rather than `Edit`/`Write`) and a hook
> that works only in Claude Code leaves Codex unguarded; a change to a hook's own logic alone needs
> nothing from the adapter. The hooks need Python 3.9+, Bash and jq, and run only once the repository
> is trusted and the hooks are reviewed through `/hooks`; restart Codex if new hooks or skills do not
> appear. Where a rule says `Read`, Codex uses file-reading tools or shell reads; where it says `Edit`
> or `Write`, `apply_patch`, which keeps the diff reviewable, fails on a stale match and is what the
> path rules load on — shell scripts are for tools, git and inspection. Where a skill names Claude's
> `Agent`/`Task` tools or Sonnet, use the Codex delegation tools and models with the same scope fences
> and verification; an agent has an isolated worktree only if one was actually created. The post-edit
> lint hook does not replace `./tools/lint.sh` before committing a governed doc, `CLAUDE.md` included.
> A request for a PR ends with a reviewable PR.
