# Codex instructions

This repository supports Codex and Claude Code. **Read and follow [CLAUDE.md](CLAUDE.md)
before starting work**, then read `docs/HANDOFF.md` and `docs/TODO.md` in that order.
`CLAUDE.md` and `.claude/skills/` are the shared source of project instructions; keep
domain rules there so both agents receive the same guidance.

## Loading the shared rules in Codex

Claude Code's hooks in `.claude/settings.json` and Codex's hooks in `.codex/hooks.json`
supply the same rule text through their native lifecycle events. Codex uses
`tools/codex-hooks.py` to translate patch payloads to the existing Claude hook scripts.
It loads rules for every patch path, including rename destinations, and lints edited
docs. Session start, resume, compaction and subagent start reload the startup rules.

Codex discovers the shared skills through `.agents/skills`, a symlink to
`.claude/skills`. Use `$skill-name` or `/skills` for explicit invocation; descriptions
also enable automatic selection. Edit the canonical `.claude/skills` files so both
agents see the same content. Keep loading selective: discovery exposes descriptions,
and the relevant skill body loads when the task or file calls for it.

The hooks need Python 3.9+, Bash and jq. In Codex, trust the repository and review the
hooks through `/hooks`; untrusted or disabled hooks do not execute. Restart Codex if
new hooks or skills do not appear. If a rule has not actually arrived in context,
read its file explicitly before doing the governed work.

At session start, read `.claude/skills/orchestrating/SKILL.md` before deciding how to
divide the work. Its Codex section makes delegation conditional on useful parallelism,
context isolation or independent review; Claude's default of delegating implementation
to Sonnet does not carry over. Before editing any file, consult the path-to-skill table in
`CLAUDE.md` under **The rules load themselves**, and read each matching
`.claude/skills/<skill>/SKILL.md` in full. All matches apply: an event GDScript file
requires both `events` and `godot`. The executable mapping is in
`.claude/hooks/project-rules.sh`; consult it if the table is ambiguous. These rules
apply to edits through any tool, including patches and scripts.

Also load skills at the moments listed in `CLAUDE.md`: `feedback` before responding
to playtest feedback or design instructions, `committing` before git mutations or
commit messages, and `session-cleanup` before the final report. Read any other skill
whose description matches the task, and follow its referenced resources as needed.
An explicit request for a repository skill means reading its file directly even if
it is absent from the skill picker. Resolve relative resource paths from that
skill's directory. Re-read rules after context loss if their contents are no longer
available. Hooks observe nested tool calls made through code mode as well.

If `.claude/rules/` is added, read its unscoped Markdown rules at startup and its
path-scoped rules before work on matching files, respecting their `paths`
frontmatter. Read any nested `CLAUDE.md` governing files you touch as well as nested
`AGENTS.md` instructions.

## Translating Claude-specific tooling

- Use Codex's file-reading tools or shell reads where a rule says `Read`, and
  `apply_patch` where it says `Edit` or `Write`. Preserve the requirement for
  reviewable diffs and failures on stale matches.
- Where a skill names Claude's `Agent`/`Task` tools or Sonnet, use available Codex
  delegation tools and models. Preserve scope fences and verification requirements;
  do not assume an agent has an isolated worktree unless one was actually created.
  If delegation is unavailable, carry out the bounded work locally under the same
  rules and explain the limitation.
- Ordinary edits use patches so rules arrive before the edit. Arbitrary shell scripts
  can compute their paths; before structural script edits, load the matching skills
  explicitly. The shell hook supplies this reminder and runs doc lint afterward.
- Run `./tools/lint.sh` before committing even when post-edit lint hooks ran; it
  includes this entry point. Follow the applicable skills for other verification.

Preserve the intent of shared skills: route-design constraints, reviewable edits,
bounded delegation and meaningful verification. Claude tool names describe how
Claude carries out those steps; use the equivalent Codex capability. A request for
a PR ends with a reviewable PR, even where the default git workflow describes merging.

System, developer, and user instructions take precedence over repository guidance.
Keep this file focused on Codex loading and tool adaptations; update shared rules
in `CLAUDE.md` or the relevant skill.
