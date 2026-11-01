# CLAUDE.md

Working guidelines for this repo. The *game* is documented in `docs/`.

**These guidelines and `.claude/skills/` are written for Claude Code; Codex support is frozen (below).** Hooks inject
**orchestrating** at session start and the path rules before each edit (the table below); if a
rule did not arrive, or is no longer in context, read its skill file before the governed work.
Every matching skill applies, to edits through any tool, patches and scripts included, and so
does any skill whose description matches the task; one asked for by name is read from its file
even if the skill picker does not list it. A skill's relative resource paths resolve from its own
directory. The system, developer and user instructions take precedence over repository guidance.

## Codex integration is frozen

**Codex support is frozen while the player is not using Codex** (inbox #901). Its files stay as they
are (`.agents/skills`, `.codex/`, the adapter `tools/codex-hooks.py` and its tests, the `codex-coder`
and `codex-reviewer` identities, the skills' Codex asides), and nothing keeps them in step: a change
to a hook or to the hooks in `.claude/settings.json` does not update the adapter, which may lag.
Before Codex works here again, the adapter and the asides are brought up to date in one pull
request; what the section said while Codex was in use, including the rule this replaces, is in the
record amber-penguin (`tools/decisions.sh amber-penguin`).

**Everything here and in `.claude/skills/` is current.** Where you need to know why a rule exists,
what was tried and rejected, or what a number used to be, that is the records under
`docs/decisions/`, one file each, fetched on demand with `tools/decisions.sh <noun>`
([docs/DECISIONS.md](docs/DECISIONS.md) says how). Nothing outside them describes a past state.

**Where to pick up is read from the live state, not from a checked-in document.** Fetch
(`git fetch --prune`), then `gh pr list` for the open pull requests, `tools/agent-status.sh` for
the agent worktrees and their briefs, `tools/queue.sh` for the queue's order
([docs/TODO.md](docs/TODO.md) says how an entry's band sets it), and
`uv run python tools/inbox.py list` for the player's inbox, the notes on GitHub Issues not yet
filed (**inbox**); the items under `docs/review/` are what waits on a person. A local, git-ignored
`.claude/restart-prompt.md`, when there is one, is the last session's note to the next
(**session-cleanup**).

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
| `tools/synthesize-sfx.py`, any `*.wav`, `*.ogg`, `*.flac` or `*.mp3` | **sound-effects** |
| `tools/**`, `src/dev/dev_flags.gd`, `src/dev/auto_screenshot.gd` | **cli-tools** |
| `tests/**` | **verify** |
| `docs/playtests/*.md`, `docs/TODO.md`, `docs/todo/**`, `docs/review/**` | **playtest-feedback** |
| `art/illustrated/**` | **illustrated-png** |
| `docs/evidence/archive/rejected-graphics/**` | **rejected-graphics** |
| `docs/evidence/archive/session-captures/**` | **session-captures** |
| `docs/evidence/**` | **verify** |
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
| commit, branch, merge, cut a release, or write a commit message | **committing** |
| review a pull request, brief a review agent, or decide a PR is ready to merge — every PR is reviewed adversarially first | **pr-review** |
| merge main into a PR or branch | **merging-main** |
| build a worksheet for the player to answer the review items in | **review-answers** |
| ask the player a question — never in a dialog; the orchestrating Claude Code session's go on the board, and one about an inbox note may go on its issue — or read or write the Nappy board, the shared doc of open questions and running work | **board** |
| **end a session** | **session-cleanup** |

**A manual sequence done a second time becomes a script** (woolly-finch 23). It follows
**cli-tools** for what a command-line entry point owes, and its row goes into the **using-tools**
catalogue in the same commit. This is a conversation rule rather than a hook: the moment a second
manual pass is noticed, nothing has been edited yet, so there is no file to hang it on.

If a skill turns out not to cover something it should, add it there rather than here — **anything
too long for one file becomes a file of its own, and this one does not grow.** If a new area of the
tree needs rules, add the path to the hook script as well, or the rule is only a suggestion.

Two things to know before extending the mapping. **A path may match several skills** and all of them
fire together, so a `.gd` file under `src/events/` brings both `events` and `godot` — keep an eye on
the combined size, because a large injection is written to a file and summarised rather than placed
inline. And **the hook cannot reach a rule about a conversation**: anything that governs what you
*say* rather than what you *edit* has to live in this file, because there is no tool call to hang it
on.

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
`docs/decisions/` that does, named the same way. The number is `#N` in a file whose statements are
`## #N` headings, the note of that number there, and otherwise the file's own number for the
statement, a numbered heading (`## 7. …`) or a numbered statement (`7. **…**`), with a range as
`18-23`. Where a number is both a numbered heading and a numbered statement in its file, the heading
is meant. The one other form is what `tools/inbox.py cite` writes after an inbox number, `inbox #N
in woolly-penguin`, the playtest holding that note. A citation is never a Markdown link, a path or
an anchor, and `tools/check_citations.py`, which `tools/lint.sh` runs, checks every one. Whether a
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

**This rule is about conversation, so nothing can trigger it but you.** It lives here rather than in
a skill because no file edit precedes it — it applies to the first sentence of a turn as much as the
last.

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
- **No quest log for the resistance** — *asked for no marker and no quest log (PLAYTEST-02 14) ·
  overturned on 2026-08-31 to only the first encounter, the chalk mark, coming without a hint
  (PLAYTEST-16 7) · overturned again on 2026-09-23 to the first task being hinted at too
  (PLAYTEST-122 12).* Nothing lists the tasks and the day brief carries none; day 6's brief names
  the rumor of chalk, and every task has a red arrow (M181, the resistance has a reason, and a task
  is one day).
