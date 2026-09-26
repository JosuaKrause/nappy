# CLAUDE.md

Working guidelines for this repo. The *game* is documented in `docs/`.

**These guidelines and `.claude/skills/` are shared by Claude Code and Codex.** Hooks inject
**orchestrating** at session start and the path rules before each edit (the table below); if a
rule did not arrive, or is no longer in context, read its skill file before the governed work.
Every matching skill applies, to edits through any tool, patches and scripts included, and so
does any skill whose description matches the task; one asked for by name is read from its file
even if the skill picker does not list it. A skill's relative resource paths resolve from its own
directory. The system, developer and user instructions take precedence over repository guidance.

## Codex integration

Codex finds the skills through `.agents/skills`, a link to `.claude/skills`, and runs the same
hook scripts through `.codex/hooks.json` and the adapter `tools/codex-hooks.py`: it loads the rules
for every path a patch touches, rename destinations included, lints each edited doc, denies an
unbounded `git grep` on Codex's own Bash calls the same way Claude Code's does, and reloads
the startup rules on session start, resume, compaction and subagent start. The hooks need Python
3.9+, Bash and jq, and run only once the repository is trusted and the hooks are reviewed through
`/hooks`; restart Codex if new hooks or skills do not appear. Where a rule says `Read`, Codex uses
file-reading tools or shell reads; where it says `Edit` or `Write`, `apply_patch`, which keeps the
diff reviewable, fails on a stale match and is what the path rules load on — shell scripts are for
tools, git and inspection. Where a skill names Claude's `Agent`/`Task` tools or Sonnet, use the
Codex delegation tools and models with the same scope fences and verification; an agent has an
isolated worktree only if one was actually created. The post-edit lint hook does not replace
`./tools/lint.sh` before committing a governed doc, `CLAUDE.md` included. A request for a PR ends
with a reviewable PR.

**Everything here and in `.claude/skills/` is current.** Where you need to know why a rule exists,
what was tried and rejected, or what a number used to be, that is
[docs/DECISIONS.md](docs/DECISIONS.md), fetched on demand. Nothing outside that file describes a
past state.

Read [docs/HANDOFF.md](docs/HANDOFF.md) for where to pick up, then [docs/TODO.md](docs/TODO.md).

---

## The one-line version

The game is a route-planning puzzle where the only verb is *where do I walk*. Almost every rule
exists to make that choice interesting. Before changing a number or adding a system, ask what it
does to the route decision. If the answer is "nothing", it is decoration.

---

## The rules load themselves

The rules live in `.claude/skills/`, one per kind of work. **Most of them arrive on their own.** A
`PreToolUse` hook (`.claude/hooks/project-rules.sh`, wired in `.claude/settings.json`) fires on every
`Edit`/`Write`, maps the path to the skills that govern it, and puts their text into context
**before the edit is made** — once per area per session, so the same rules are not repeated on every
subsequent edit to the same place.

**A rule you have to remember to load is not a rule.** That is why the path-triggered ones are a
hook rather than an instruction: every skill exists to stop a mistake that has already been made
here at least once and that nothing in the code or the engine warns about, and the moment it matters
is the moment somebody is about to touch the file.

| Path | Rules that arrive |
|---|---|
| `src/events/**` | **events** |
| `src/city/**`, `src/routes/**` | **city** |
| `src/crowd/**` | **crowd-traffic** |
| `src/city/traffic_signals.gd`, `src/city/traffic_light.gd`, `src/ground_shape.gd` | **crowd-traffic** |
| `src/ui/**`, `sprites.gd`, `palette.gd` | **cues** |
| `src/telemetry/**`, `src/autoload/telemetry.gd` | **telemetry** |
| `src/autoload/tuning.gd` | **balance** |
| `tools/*.py`, `pyproject.toml`, `uv.lock`, `.python-version` | **python-tooling** |
| `tools/**`, `src/dev/dev_flags.gd`, `src/dev/auto_screenshot.gd` | **cli-tools** |
| `tests/**` | **verify** |
| `docs/playtests/PLAYTEST-*.md`, `docs/TODO.md` | **playtest-feedback** |
| `art/illustrated/**` | **illustrated-png** |
| `docs/evidence/archive/rejected-graphics/**` | **rejected-graphics** |
| `docs/evidence/archive/session-captures/**` | **session-captures** |
| `docs/reference/**`, `docs/style-references/**` | **reference-photos** |
| any `*.gd` | **godot** |
| any `*.svg` | **svg-art** |
| `src/**`, `tests/**` | **orchestrating** |
| spawning a sub-agent (the `Agent`/`Task` tool, not a path) | **orchestrating** |

**And one arrives before anything at all.** `.claude/hooks/session-rules.sh`, wired to `SessionStart`
in `.claude/settings.json`, loads **orchestrating** at the start of every session, because
*delegating is the default* is decided before the first tool call — an `Agent` spawn is that
decision already going the right way and a first edit to `src/` or `tests/` is it already going the
wrong one. The table's two **orchestrating** rows are backstops that share its marker, so a
session gets it once however it is triggered, and again after compaction.

**Keep that list to one skill unless there is a real second.** Everything loaded at the start is
paid for in every session whether or not it turns out to be relevant, which is the exact cost the
path-triggered hook exists to avoid.

**These skills have no file to trigger on and are yours to invoke**, because they are about a *moment*
rather than a place:

| Before you… | Load |
|---|---|
| run a sequence of shell commands by hand — git/gh housekeeping, checking on agents, verification, a capture, a build | **using-tools** |
| respond to a playtest or a design instruction, *before* any file is touched | **playtest-feedback** |
| commit, branch, merge, or write a commit message | **committing** |
| review a pull request — the findings go on the PR as comments | **committing** |
| merge main into a PR or branch | **merging-main** |
| **end a session** | **session-cleanup** |

**A manual sequence done a second time becomes a script.** *(2026-09-22: "if you find yourself
doing similar things over and over again that require a lot of manual work maybe that's a time to
move them to shell scripts and note them down somewhere. is there a skill about how to use the
scripts in the tools folder?")* It follows **cli-tools** for what a command-line entry point owes,
and its row goes into the **using-tools** catalogue in the same commit. This is a conversation
rule rather than a hook: the moment a second manual pass is noticed, nothing has been edited yet,
so there is no file to hang it on.

If a skill turns out not to cover something it should, add it there rather than here — **anything
too long for one file becomes a file of its own, and this one does not grow.** If a new area of the
tree needs rules, add the path to the hook script as well, or the rule is only a suggestion.

Two things to know before extending the mapping. **A path may match several skills** and all of them
fire together, so a `.gd` file under `src/events/` brings both `events` and `godot` — keep an eye on
the combined size, because a large injection is written to a file and summarised rather than placed
inline. And **the hook cannot reach a rule about a conversation**: anything that governs what you
*say* rather than what you *edit* has to live in this file, because there is no tool call to hang it
on.

**A skill found wrong is fixed, and the fix is flagged to the player.** *(2026-09-22: "if you
ever notice that a skill doesn't work correctly or contains incorrect information or otherwise
could be improved fix that and flag the fix to me since I want to understand how skills can be
improved.")* Wrong includes a step that fails in practice, a sentence that is no longer true, a
broken or duplicated passage, and a gap that let a mistake through. The fix goes on a branch and
PR like any other change, and the report to the player names the skill, what was wrong, the
moment it showed, and what the text now says — the point is that the player learns how a skill
fails, not only that one was edited.

---

## Documentation is written in the present tense

**Every document states what is true now and only what is true now.** No "used to be", no "since
M33", no "this was wrong for twelve milestones", no caveats about what a sentence meant before.
History goes to `docs/DECISIONS.md`.

Keep the *reason* a thing is the way it is — that is current, and it is most of what makes this
project reviewable. Move the *incident* that taught it.

**Why:** a stale sentence is indistinguishable from a live one, so a reader cannot tell which half
of a paragraph to believe without reading every past state first.

The test is a reader, not a diff: **somebody who opens any single file and believes every sentence
in it is wrong about nothing.**

**Never quote a number with a short shelf life** — a check count, a commit hash, a measured figure —
unless recording that measurement is the document's job. Say what the command is, not what it
prints.

**No quest logs outside `DECISIONS.md`.** *(2026-09-01: "there should be no quest logs outside of
decisions.md — that information is rarely relevant when working on the codebase. it only ever comes
in to play when planning things out, so we don't attempt approaches again that we already ruled
out.")* A ticked box, a "Done:" paragraph, a branch name or a status word in a heading is a quest
log wherever it stands: `TODO.md` holds open work only, `HANDOFF.md` holds the pick-up state only,
`REVIEW.md` holds what waits on a person only, and what was done — with its measurement and its rejected options — is retrievable on demand from
`DECISIONS.md` and nowhere else.

The playtest files are the exception and are never rewritten. `docs/playtests/PLAYTEST-NN.md` are primary
sources: a player's own words on a date.

---

## Explain; never reference something only you have read

**When citing a rule, constant, function, file or line, say what it does in the same sentence.**
Anything read out of a file is information only this side has seen. A bare name — "the
`police_patrol` rule", "`SEEN_RADIUS`", "see `hud.gd:237`" — is not a reference the player can
follow; it is a claim with the evidence withheld.

- Give the **value or the behaviour** inline: "`SEEN_RADIUS` (190px, measured from the mark, not
  from her)".
- Say **what is at** a `file:line` rather than pointing at it.
- Quote the code comment or doc sentence that carries the reasoning rather than paraphrasing it as
  settled fact.
- If a name was invented for the conversation rather than found in the repo, say so. Half the
  confusion is a label that sounds official and is not.
- **A milestone or a `TODO.md` item is named by its number *and* a short title**, every time:
  "M98, pressure in the empty acts", never "M98" alone. *(2026-09-09: "whenever you're talking
  about milestones and todos give a short title in addition to the number.")* A number is a
  lookup the player has to perform; the title is the thing they were asked about.
- **A question carries all the context needed to answer it** — what was asked, what it collides
  with, what each answer costs, and which you would pick — in the message that asks it, not in an
  earlier one. *(2026-09-09: "also provide all necessary context when asking a question.")* The
  player answers from the message in front of them, and a question that leans on something said
  three turns ago is a question with its evidence withheld.

**This rule is about conversation, so nothing can trigger it but you.** It lives here rather than in
a skill because no file edit precedes it — it applies to the first sentence of a turn as much as the
last.

## Editing files

**An edit fails loudly or it is not an edit.** Whatever tool makes a change — a dedicated edit
tool, `sed`, a heredoc, a script — the change is either visibly correct or visibly rejected: a
replacement that matches nothing must say so rather than look like a success. In a repo where the
docs *are* the design and get committed alongside the code, a doc edit that quietly did nothing is
a lie in the commit rather than a missing change.

So a script or a one-liner that rewrites a file **asserts the anchors before writing** —
`str.index` rather than a silent `replace`, a `grep -c` that must return the count you expect —
and **verifies after**, with line counts and a `grep` for something that must have survived. That
holds for a small change as much as for the large-scale and structural work a script is the right
tool for: moving a file whole, splitting a document, deleting a whole section, renaming an
identifier across the tree, applying the same change to thirty files.

**And grep for what pointed at it before you move anything**, since a reference is not visible
from the file being moved.

---

## Names are content, never identifiers

The mother and the baby have names — `docs/NARRATIVE.md` is the one place that says what they are.
**Nothing in `src/` may be named after them.** No `hal.gd`, no `var wren`, no `WREN_CRY_THRESHOLD`.

**Why:** a name can change at any time, and a name that has reached an identifier changes with a
rename across every file that mentions it — a diff nobody can review for anything else, on a
decision that was meant to be cheap to revisit. The code calls them what they *are* — `Stroller`,
`Baby`, `player`, `mother` — which is stable under every renaming the narrative might want.

The same holds for anything else the fiction may rename: the city has no name for the same reason.

**New things get American English names.** *(2026-09-11: "use american words for new things";
"existing names are fine".)* A new event, asset, identifier, constant or doc noun says *sidewalk*,
*crosswalk*, *street musician*, not *pavement*, *zebra*, *busker* — the player is not a native British
speaker and a British word is a lookup. Nothing existing is renamed for it: `pavement`, `zebra` and
`busker` stay wherever they already are, since a rename across the tree is a diff nobody can review
for anything else.

---

## Notes belong in the repo

**Anything worth remembering about how to work on this project goes in a skill, or in this file —
never only in an assistant's private memory.** A memory is scoped to one tool, one machine and one
account: invisible to everybody else who opens the repo, not reviewable in a diff, and lost the
moment that store is cleared or the work moves.

**"Make a note of that" means write it somewhere in the repository** — this file, a skill, or the
doc it belongs to — and commit it. *(2026-09-08: "'making a note' means writing it somewhere in the
repo (eg claude.md) *not* storing it as memory".)* It never means an assistant's memory store.

---

## Things deliberately not done

Each was a decision. Do not "fix" one without a reason; the reasoning is in `docs/DECISIONS.md`.

- **The engine and city non-choices live in the city and events skills**: closures and events are
  checked before they are accepted, never repaired afterwards, with its one monotonic exception;
  counting distinct routes is a max flow; the home's doorstep is exempt from the route-redundancy
  guarantee (**city**); no spatial hash, no `impulse` field, and events defined in code rather
  than `.tres` (**events**).
- **No quest log for the resistance** — *asked for no marker and no quest log (playtest 2) ·
  overturned on 2026-08-31 to "Only the first encounter (the chalk mark) should come without
  hint" (playtest 16, finding 7) · overturned again on 2026-09-23: "we do now hint at the first
  task" (playtest 122).* Nothing lists the tasks and the day brief carries none; day 6's brief
  names the rumor of chalk, and a task sent to one place has a red arrow (M181, the resistance
  has a reason, and a task is one day).
