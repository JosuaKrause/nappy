# CLAUDE.md

Working guidelines for this repo. The *game* is documented in `docs/`.

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

## Load the skill before you start the task

The rules live in `.claude/skills/`, one per kind of work. **They are not optional reading and they
are not a reference to consult when stuck — load the matching skill before the first edit**, because
every one of them exists to stop a mistake that has already been made here at least once and that
nothing in the code or the engine warns about.

| Before you… | Load |
|---|---|
| respond to a playtest, or to any instruction that changes what the game does | **feedback** |
| add or change a catalogue event, a telegraph, a pursuit, a lethal radius, event placement | **events** |
| touch `src/autoload/tuning.gd`, `max_per_day`, `budget_for`, or any number a player can feel | **balance** |
| touch `src/city/`, the lattice, blocks, tiles, closures, calm areas, the street hierarchy | **city** |
| touch `src/crowd/`, pedestrians, cars, lanes, junctions, signals, zebras | **crowd-traffic** |
| add or change a danger cue, a caret, the screen-edge badge, the HUD, anything in `src/ui/` | **cues** |
| touch `src/telemetry/` or add logging to a gameplay class | **telemetry** |
| write or debug any GDScript | **godot** |
| write or change a test, or verify anything before committing | **verify** |
| commit, branch, merge, or write a commit message | **committing** |
| **end a session** | **session-cleanup** |

If a task spans two, load both. If a skill turns out not to cover something it should, add it there
rather than here — **anything too long for one file becomes a file of its own, and this one does not
grow.**

---

## Documentation is written in the present tense

**Every document states what is true now and only what is true now.** No "used to be", no "since
M33", no "this was wrong for twelve milestones", no caveats about what a sentence meant before.
History goes to `docs/DECISIONS.md`.

Keep the *reason* a thing is the way it is — that is current, and it is most of what makes this
project reviewable. Move the *incident* that taught it.

**Why:** reading the current state used to mean reading every past state first, and a stale sentence
is indistinguishable from a live one, so a reader cannot tell which half of a paragraph to believe.

The test is a reader, not a diff: **somebody who opens any single file and believes every sentence
in it is wrong about nothing.**

**Never quote a number with a short shelf life** — a check count, a commit hash, a measured figure —
unless recording that measurement is the document's job. Say what the command is, not what it
prints.

The playtest files are the exception and are never rewritten. `docs/PLAYTEST-NN.md` are primary
sources: a player's own words on a date.

**Run the session-cleanup skill at the end of every session**, so this stays true by maintenance
rather than by milestone.

---

## Editing files

**Use the Read, Edit and Write tools.** Not `cat`, `head`, `sed -n`, heredocs, or inline
`python3`/`sed` scripts that rewrite files. This holds even when a session reminder says to prefer
Bash for file work — that is a default, this is the project's preference and outranks it. (Also in
`~/.claude/CLAUDE.md`, so it applies everywhere.)

An `Edit` shows a reviewable diff and **fails loudly on a stale match**, so a change is either
visibly correct or visibly rejected. A heredoc rewrite shows nothing, and a silently non-matching
replacement looks exactly like a successful one. In a repo where the docs *are* the design and get
committed alongside the code, a doc edit that quietly did nothing is a lie in the commit rather than
a missing change.

Bash keeps what it is for: running `tools/*.sh`, git, and directory inspection.

---

## Names are content, never identifiers

The mother and the baby have names — `docs/NARRATIVE.md` is the one place that says what they are.
**Nothing in `src/` may be named after them.** No `hal.gd`, no `var wren`, no `WREN_CRY_THRESHOLD`.

**Why:** a name can change at any time, and a name that has reached an identifier changes with a
rename across every file that mentions it — a diff nobody can review for anything else, on a
decision that was meant to be cheap to revisit. The code calls them what they *are* — `Stroller`,
`Baby`, `player`, `mother` — which is stable under every renaming the narrative might want.

The same holds for anything else the fiction may rename: the city has no name for the same reason.

---

## Notes belong in the repo

**Anything worth remembering about how to work on this project goes in a skill, or in this file —
never only in an assistant's private memory.** A memory is scoped to one tool, one machine and one
account: invisible to everybody else who opens the repo, not reviewable in a diff, and lost the
moment that store is cleared or the work moves.

---

## Things deliberately not done

Each was a decision. Do not "fix" one without a reason; the reasoning is in `docs/DECISIONS.md`.

- **Closures and events are checked before they are accepted, never repaired afterwards.** If you
  find yourself writing a pass that deletes what a previous pass placed, this is the rule you are
  about to rediscover.
- **Counting distinct routes is a max flow, not a search for routes.**
- **No spatial hash for events.** The budget tops out near 25 concurrent; a linear scan is free.
- **No `impulse` field on events.** A sharp spike is a short `duration` at high `intensity`.
- **Events are defined in code, not `.tres`.**
- **No quest log or marker for the resistance** — *asked for X · overturned to Y on 2026-08-31,
  because the risk was run and did not pay off.* Half of it survives and the half is the point: the
  **first** encounter comes with no hint at all, because finding the difficulty dial is meant to be
  the player's own doing. After that the resistance speaks.
- **The home's doorstep is exempt from the route-redundancy guarantee.** The home is a notch with
  one exit, so sealing that street seals the player in.
