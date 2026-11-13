# CLAUDE.md

Working guidelines for this repo. The *game* is documented in `docs/`.

**These guidelines and `.claude/skills/` are written for Claude Code; Codex support is frozen (below).** Hooks name
the skills that govern the work (below): read each whole before that work, and again once it is no
longer in context.
Every matching skill applies, to edits through any tool, patches and scripts included, and so
does any skill whose description matches the task; one asked for by name is read from its file
even if the skill picker does not list it. A skill's relative resource paths resolve from its own
directory. The system, developer and user instructions take precedence over repository guidance.

## Codex integration is frozen

**Codex support is frozen while the player is not using Codex** (inbox #901 in freckled-moose). Its files stay as they
are (`.agents/skills`, `.codex/`, the adapter `tools/codex-hooks.py` and its tests, the `codex-coder`
and `codex-reviewer` identities, the skills' Codex asides), and nothing keeps them in step: a change
to a hook or to the hooks in `.claude/settings.json` does not update the adapter, which may lag.
Before Codex works here again, the adapter and the asides are brought up to date in one pull
request; what the section said while Codex was in use, including the lifted rule that a hook change
updates the adapter (brisk-heron 6), is in the record amber-penguin (`tools/decisions.sh
amber-penguin`).

The post-edit lint hook does not replace `./tools/lint.sh` before committing a governed doc,
`CLAUDE.md` included. A request for a PR ends with a reviewable PR.

**The orchestrating Claude Code session has the player's standing permission to merge a pull
request** once **committing**'s merge gates hold (its review ready against the head, or a delta
review of what came after; green CI); a release still needs its own go-ahead (inbox #1063 in gentle-walrus). **committing**'s "Merging" says where that permission has to live for Claude Code's auto-mode classifier to act on it (the
player's `~/.claude/settings.json`) and what is done on a refusal (the filer's proposal, curly-rabbit #1094).

**The orchestrating session is the top-level session the player started to run the queue**; a
sub-agent never is, and a second top-level session is one only when the player says so. Any other
session merges nothing on its own authority, only a pull request the orchestrating session hands it
or the player authorizes in that session (**committing**, "Merging"), and writes neither the board
nor `.claude/restart-prompt.md` (inbox #1267 in olive-ferret).

**Everything here and in `.claude/skills/` is current.** Where you need to know why a rule exists,
what was tried and rejected, or what a number used to be, that is the records under
`docs/decisions/`, one file each, fetched on demand with `tools/decisions.sh <noun>`
([docs/DECISIONS.md](docs/DECISIONS.md) says how). Nothing outside them describes a past state.

**Where to pick up is read from the live state, not from a checked-in document.** The
orchestrating session first reads the local, git-ignored `.claude/restart-prompt.md`, the last
session's note to the next, when there is one (frosty-owl #1062), whole and top to bottom in the
fixed layout **session-cleanup** gives it (frosty-owl #1065); the live state wins where the two differ. Then fetch (`git fetch --prune`), then
`gh pr list` for the open pull requests, `tools/agent-status.sh` for the agent worktrees and their
briefs, `tools/queue.sh` for the queue's order ([docs/TODO.md](docs/TODO.md) says how an entry's
band sets it), `uv run python tools/inbox.py list` for the player's inbox, the notes on GitHub
Issues not yet filed (**inbox**), and the Nappy board, the shared doc of open questions and
running work (**board**); the items under `docs/review/` are what waits on a person.

---

## The one-line version

The game is a route-planning puzzle where the only verb is *where do I walk*. Almost every rule
exists to make that choice interesting. Before changing a number or adding a system, ask what it
does to the route decision. If the answer is "nothing", it is decoration.

---

## The rules load themselves

The rules live in `.claude/skills/`, one per kind of work. **A `PreToolUse` hook,
`.claude/hooks/project-rules.sh`, refuses the first `Edit`/`Write` of an area until the skills that
govern it are read whole** (inbox #1267 in olive-ferret): the refusal names each skill with its path and size, and
the same edit made again passes. No hook prints a skill's text to a Claude Code session, since the
harness cuts a long hook output to its opening.

**A rule you have to remember to load is not a rule**: every skill exists to stop a mistake already
made here at least once that nothing in the code or the engine warns about, and the moment it
matters is the moment somebody is about to touch the file.

| Path | Rules that arrive |
|---|---|
| `src/events/**` | **events** |
| `src/city/**`, `src/routes/**` | **city** |
| `src/crowd/**`, `src/city/traffic_signals.gd`, `src/city/traffic_light.gd`, `src/ground_shape.gd` | **crowd-traffic** |
| `src/ui/**`, `sprites.gd`, `palette.gd`, `src/events/views/event_look.gd`, `src/crowd/crowd_agent.gd`, `src/player/stroller.gd`, `src/events/warning_board.gd` | **cues** |
| `src/telemetry/**`, `src/autoload/telemetry.gd` | **telemetry** |
| `src/autoload/tuning.gd`, `src/events/event_catalogue.gd`, `src/events/event_scheduler.gd`, `src/crowd/crowd_lanes.gd`, `src/player/baby.gd`, `src/city/city.gd`, `src/field.gd`, `src/events/dawn_phases/ruled_roadblock_ground.gd`, `src/events/ruled_location_ground.gd`, `src/events/dawn_phases/dawn_masts.gd`, `src/events/dawn_phases/dawn_spoilers.gd` | **balance** |
| `tools/*.py`, `pyproject.toml`, `uv.lock`, `.python-version` | **python-tooling** |
| `tools/synthesize-sfx.py` | **sound-effects** |
| `tools/reference.sh`, `tools/reference.py`, `docs/reference/**`, `docs/style-references/**` | **reference-photos** |
| `tools/**`, `src/dev/dev_flags.gd`, `src/dev/auto_screenshot.gd` | **cli-tools** |
| `tests/**` | **verify**, **writing-tests** |
| `docs/playtests/*.md`, `docs/TODO.md`, `docs/todo/**`, `docs/review/**` | **playtest-feedback** |
| `art/illustrated/**` | **illustrated-png** |
| `assets/atlases/membership.json` | **svg-art**, **illustrated-png** |
| `docs/evidence/archive/rejected-graphics/**` | **rejected-graphics** |
| `docs/evidence/**` | **verify**, **session-captures** |
| `.github/workflows/**` | **verify** |
| `.claude/settings.json`, `docs/decisions/**` | **committing** |
| any `*.gd`, `*.tscn` or `*.gdshader`, `project.godot` | **godot** |
| `src/**/*.gd` | **designing-classes** |
| any `*.svg` | **svg-art** |
| `src/**`, `tests/**`, outside a sub-agent | **orchestrating** |
| spawning a sub-agent (the `Agent`/`Task` tool, not a path) | **orchestrating** |

**And one is named before anything at all.** `.claude/hooks/session-rules.sh` (`SessionStart`) names
**orchestrating**, the orchestrating session's skill and never a sub-agent's, at the start of every
session, to be read whole before the first tool call, because *delegating is the default* is
decided by then. **Keep that list to one skill unless there is a real second**: what is named at
the start is read in every session, relevant or not, the cost the path-triggered hook exists to
avoid.

**These skills have no file to trigger on and are yours to invoke**, because they are about a *moment*
rather than a place:

| Before you… | Load |
|---|---|
| need a tool for a job and do not know its name, or are about to repeat a manual sequence | **using-tools** |
| respond to a playtest or a design instruction, *before* any file is touched | **playtest-feedback** |
| write a brief or a design that shapes classes | **designing-classes** |
| brief an agent to write or change tests, or write them | **writing-tests** |
| commit, branch, merge, cut a release, or write a commit message | **committing** |
| review a pull request, brief a review agent, or decide a PR is ready to merge — every PR is reviewed adversarially first | **pr-review** |
| merge main into a PR or branch | **merging-main** |
| build a worksheet for the player to answer the review items in | **review-answers** |
| ask the player a question — never in a dialog; the orchestrating session's go on the board, and one about an inbox note may go on its issue — or read or write the Nappy board | **board** |
| start a session, or capture, read, ask on or file a note | **inbox** |
| change anything under `src/` | **verify** |
| **end a session** | **session-cleanup** |

**A manual sequence done a second time becomes a script** (woolly-finch 23); **using-tools** says
what the script owes.

If a skill turns out not to cover something it should, add it there rather than here — **anything
too long for one file becomes a file of its own, and this one does not grow.** If a new area of the
tree needs rules, add its row to the hook script and the table above (`tools/test_rules_hooks.sh`
compares the two), or the rule is only a suggestion. **Only a file an edit tool writes can have a
row**: a tool that writes a picture, a recording or a sound names its skill itself. And **the hook
cannot reach a rule about a conversation**: anything that governs what you *say* rather than what
you *edit* has to live in this file, because there is no tool call to hang it on.

**A skill found wrong is fixed, and the fix is flagged to the player** (woolly-finch 24). Wrong
includes a step that fails in practice, a sentence that is no longer true, a broken or duplicated
passage, and a gap that let a mistake through. The fix goes on a branch and PR like any other
change, and the report to the player names the skill, what was wrong, the moment it showed, and what
the text now says — the point is that the player learns how a skill fails, not only that one was
edited.

---

## Documentation is written in the present tense

**Every document states what is true now and only what is true now.** No "used to be", no "since
M33", no "this was wrong for twelve milestones", no caveats about what a sentence meant before.
History goes to a record under `docs/decisions/`.

Keep the *reason* a thing is the way it is — that is current, and it is most of what makes this
project reviewable. Move the *incident* that taught it.

**Why:** a stale sentence is indistinguishable from a live one, so a reader cannot tell which half
of a paragraph to believe without reading every past state first.

The test is a reader, not a diff: **somebody who opens any single file and believes every sentence
in it is wrong about nothing.**

**Never quote a number with a short shelf life** — a check count, a commit hash, a measured figure —
unless recording that measurement is the document's job. Say what the command is, not what it
prints.

**No quest logs outside the decision records** (PLAYTEST-18 2). What was done is rarely relevant
when working on the codebase and only comes into play when planning, so that an approach already
ruled out is not tried again. A ticked box, a "Done:" paragraph, a branch name or a status word in a
heading is a quest log wherever it stands: `TODO.md` and the entries under `docs/todo/` hold open
work only, `REVIEW.md` and the items under `docs/review/` hold what waits on a person only, and what
was done — with its measurement and its rejected options — is retrievable on demand from the records
under `docs/decisions/` and nowhere else.

The playtest files under `docs/playtests/` are the exception and are never rewritten. They are
primary sources: a player's own words on a date.

**`CLAUDE.md` and the skills cite the player's words and never quote them** (woolly-penguin #759). A
rule that rests on something the player said states the rule and its reason in its own words and
ends them with the name of the file that records the words and, where that file has several
statements, the statement's number: `(woolly-penguin #759)`, `(PLAYTEST-16 7)`. A name such as
`woolly-penguin` or `PLAYTEST-16` is the playtest `docs/playtests/<date>-<name>.md`, or
`docs/playtests/<name>.md` for a numbered one; words no playtest holds cite the record under
`docs/decisions/` that does, named the same way. The one other form is what `tools/inbox.py cite`
writes after an inbox number, `inbox #N in woolly-penguin`, the playtest holding that note. A
citation is never a Markdown link, a path or an anchor; `tools/check_citations.py`, which
`tools/lint.sh` runs, checks every one, and its header says which number a statement has. Whether a
rule reads the player right is established once, by the review of the change that writes it, so a
reader does not re-check it on every read, and a quote in the rule is only a distraction.

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
- If a name was invented for the conversation rather than found in the repo, say so and say what
  it names; it never stands alone (inbox #772 in minty-lemur). Half the confusion is a label that sounds official
  and is not.
- **A queue entry is named by its two words, or an entry from before names by its number, *and* a
  short title**, every time: "busy-badger, stars for nerves" or "M98, pressure in the empty acts",
  never "busy-badger" or "M98" alone (woolly-finch 9). A name or a number is a lookup the player has
  to perform; the title is the thing they were asked about.
- **A question carries all the context needed to answer it** — what was asked, what it collides
  with, what each answer costs, and which you would pick — in the message that asks it, not in an
  earlier one (woolly-finch 10). The player answers from the message in front of them, and a
  question that leans on something said three turns ago is a question with its evidence withheld.
- **An open point the player's recorded words already answer is never put back to them**
  (inbox #1232 in gentle-owl): it is read against their words first, and stated as the reading (**board**). An open point is investigated
  only with its task's full context, when the task is discussed or picked up, never in passing, and
  a conclusion is written down where the next session reads it in the turn it is reached
  (inbox #1244 in gentle-owl).
- **A thing in the game is named the way the player knows it, and said what it is in each
  message that mentions it** (inbox #772 in minty-lemur): what it is and what it does in play, in a clause — "the
  checkpoint guard, who steps out of the hut when she walks under the raised boom" — never only
  the code's name for it ("the door guard", from `_door_guard()`). Even the player's own name for
  a thing needs its clause, since they may not recall which one is meant. A code name may follow in
  brackets, never stand alone; this holds for a relayed agent report too.

**"Telemetry", in the player's words, primarily means GoatCounter** (azure-tapir #527). A request
for telemetry on something is a request for its own GoatCounter events (`VisitCounter`, the page
counts visits in `docs/TELEMETRY.md`); the run log is "logs", which name each thing correctly from
its first line as well.

**This rule is about conversation, so nothing can trigger it but you**: it applies to the first
sentence of a turn as much as the last.

## A pasted picture has no file

**An image pasted from the clipboard is image data with no file behind it**: the session sees it,
shown as `[Image #n]`, and has nothing to hand a script or an agent, while one attached from a saved
file has a path. The CLI shows both the same way, so when a picture comes with no path, ask where
it is saved, or for it to be dragged in from Finder or the Downloads folder, rather than describing
what it shows.

## Moving files

**Grep for what pointed at a file before you move it**, since a reference is not visible from the
file being moved.

---

## Names are content, never identifiers

The mother and the baby have names — `docs/NARRATIVE.md` is the one place that says what they are.
**Nothing in `src/` may be named after them.** No `hal.gd`, no `var wren`, no `WREN_CRY_THRESHOLD`.

**Why:** a name can change at any time, and a name that has reached an identifier changes with a
rename across every file that mentions it — a diff nobody can review for anything else, on a
decision that was meant to be cheap to revisit. The code calls them what they *are* — `Stroller`,
`Baby`, `player`, `mother` — which is stable under every renaming the narrative might want.

The same holds for anything else the fiction may rename: the city has no name for the same reason.

**New things get American English names** (PLAYTEST-56). A new event, asset, identifier, constant or
doc noun says *sidewalk*, *crosswalk*, *street musician*, not *pavement*, *zebra*, *busker* — the
player is not a native British speaker and a British word is a lookup. Nothing existing is renamed
for it: `pavement`, `zebra` and `busker` stay wherever they already are, since a rename across the
tree is a diff nobody can review for anything else.

---

## Notes belong in the repo

**Anything worth remembering about how to work on this project goes in a skill, or in this file —
never only in an assistant's private memory.** A memory is scoped to one tool, one machine and one
account: invisible to everybody else who opens the repo, not reviewable in a diff, and lost the
moment that store is cleared or the work moves.

**"Make a note of that" means write it somewhere in the repository** — this file, a skill, or the
doc it belongs to — and commit it (woolly-finch 4). It never means an assistant's memory store.

---

## Things deliberately not done

Each was a decision. Do not "fix" one without a reason; the reasoning is in the records under
`docs/decisions/`.

- **The engine and city non-choices live in the city and events skills**: closures and events are
  checked before they are accepted, never repaired afterwards, with its one monotonic exception;
  counting distinct routes is a max flow; the home's doorstep is exempt from the route-redundancy
  guarantee (**city**); no spatial hash, no `impulse` field, and events defined in code rather
  than `.tres` (**events**).
- **No quest log for the resistance.** Nothing lists the tasks and the day brief carries none
  (PLAYTEST-02 14). Every task is hinted at, the first included (PLAYTEST-16 7; PLAYTEST-122 12):
  day 6's brief names the rumor of chalk, and every task has a red arrow (M181, the resistance has
  a reason, and a task is one day).
