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
| `src/city/**` | **city** |
| `src/crowd/**` | **crowd-traffic** |
| `src/ui/**`, `sprites.gd`, `palette.gd` | **cues** |
| `src/telemetry/**` | **telemetry** |
| `src/autoload/tuning.gd` | **balance** |
| `tests/**` | **verify** |
| `docs/PLAYTEST-*.md`, `docs/TODO.md` | **feedback** |
| any `*.gd` | **godot** |
| spawning a sub-agent (the `Agent`/`Task` tool — a tool, not a path) | **orchestrating** |

**And one arrives before anything at all.** `.claude/hooks/session-rules.sh`, wired to `SessionStart`
in `.claude/settings.json`, loads **orchestrating** at the start of every session, because
*delegating is the default* is decided before the first tool call — an `Agent` spawn is that
decision already going the right way and a first edit to `src/` is it already going the wrong one.
The two path triggers are backstops and share its marker, so a session gets it exactly once.

**Keep that list to one skill unless there is a real second.** Everything loaded at the start is
paid for in every session whether or not it turns out to be relevant, which is the exact cost the
path-triggered hook exists to avoid.

**Three have no file to trigger on and are yours to invoke**, because they are about a *moment*
rather than a place:

| Before you… | Load |
|---|---|
| respond to a playtest or a design instruction, *before* any file is touched | **feedback** |
| commit, branch, merge, or write a commit message | **committing** |
| **end a session** | **session-cleanup** |

If a skill turns out not to cover something it should, add it there rather than here — **anything
too long for one file becomes a file of its own, and this one does not grow.** If a new area of the
tree needs rules, add the path to the hook script as well, or the rule is only a suggestion.

Two things to know before extending the mapping. **A path may match several skills** and all of them
fire together, so a `.gd` file under `src/events/` brings both `events` and `godot` — keep an eye on
the combined size, because a large injection is written to a file and summarised rather than placed
inline. And **the hook cannot reach a rule about a conversation**: anything that governs what you
*say* rather than what you *edit* has to live in this file, because there is no tool call to hang it
on.

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

**No quest logs outside `DECISIONS.md`.** *(2026-09-01: "there should be no quest logs outside of
decisions.md — that information is rarely relevant when working on the codebase. it only ever comes
in to play when planning things out, so we don't attempt approaches again that we already ruled
out.")* A ticked box, a "Done:" paragraph, a branch name or a status word in a heading is a quest
log wherever it stands: `TODO.md` holds open work only, `HANDOFF.md` holds the pick-up state only,
and what was done — with its measurement and its rejected options — is retrievable on demand from
`DECISIONS.md` and nowhere else.

The playtest files are the exception and are never rewritten. `docs/PLAYTEST-NN.md` are primary
sources: a player's own words on a date.

**Run the session-cleanup skill at the end of every session**, so this stays true by maintenance
rather than by milestone.

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

**This rule is about conversation, so nothing can trigger it but you.** It lives here rather than in
a skill because no file edit precedes it — it applies to the first sentence of a turn as much as the
last.

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

**One exception, and it is narrow: moving a file whole.** Splitting a document by `cp` or appending
one to another (`cat a >> b`) is a *structural* operation that changes no content, and the reason
the rule exists — a silently non-matching replacement looking exactly like a success — does not
apply. Retyping four thousand lines through `Write` to move them is its own risk.

**It is only allowed when the move is verified**: line counts before and after, and a `grep` for a
heading that must have survived. Anything that changes what a line *says* still goes through `Edit`.

**And grep for what pointed at it before you move anything.** Six documents in this repo referred to
`CLAUDE.md` sections by name, and all six were wrong within the hour of those sections moving into
skills. A reference is not visible from the file being moved.

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
- **No spatial hash for events.** The concurrent count stays a few dozen even on the last day, so a
  linear scan is free.
- **No `impulse` field on events.** A sharp spike is a short `duration` at high `intensity`.
- **Events are defined in code, not `.tres`.**
- **No quest log or marker for the resistance** — *asked for X · overturned to Y on 2026-08-31,
  because the risk was run and did not pay off.* Half of it survives and the half is the point: the
  **first** encounter comes with no hint at all, because finding the difficulty dial is meant to be
  the player's own doing. After that the resistance speaks.
- **The home's doorstep is exempt from the route-redundancy guarantee.** The home is a notch with
  one exit, so sealing that street seals the player in.
