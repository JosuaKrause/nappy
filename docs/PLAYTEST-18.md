# Playtest 18

Reported on 2026-09-01, in four messages. Not a played run: the player was reading the results of a
whole-repo audit — the full suite green, plus four audit passes checking every quoted number, the
code, the tooling and the docs against each other — and gave five instructions and one design on the
back of it.

**The wording below is the player's, verbatim.** Everything under a *"What this side reads into
it"* heading is this side's analysis and is kept apart from it on purpose.

**Six findings, in three groups.**

- **Two are process rules about the documentation** — enforcement for the timeless style, and where
  progress-tracking is allowed to live. Both are M40's own logic taken one step further: from *the
  docs are made true* to *the docs are kept true by machinery rather than by discipline*.
- **Three are approvals and a build order**: the drift guard, `stats.sh`, and the instruction that
  the plan be written down at implementation depth and then handed to Sonnet 5 sub-agents.
- **One is a new entity** — the first new gameplay design since M56 was written — with its cost
  model given in the player's own sentence.

---

## 1. Documentation must be written so it cannot easily go stale

> "can we enforce that documentation is written in a way that it cannot easily become stale? for
> example we don't need to state how many tests are green in the claude docs."

**What this side reads into it.** The rule already exists in words — `CLAUDE.md` says never to
quote a number with a short shelf life — and the audit that prompted this found the failure anyway:
the handoff opened with a commit hash and an open-branch claim that were both false within a day of
being written. So the instruction is not *have the rule*, it is **enforce** it: machinery that
catches a volatile fact in a doc before it is committed, the way the path hook catches an edit
before it is made. That is M57 in `docs/TODO.md` — a linter over the governed docs for commit
hashes, branch names, check counts and status markers, wired into the hook, the committing pass and
the session cleanup.

## 2. No quest logs outside DECISIONS.md

> "also, there should be no quest logs outside of decisions.md that information is rarely relevant
> when working on the codebase. it only ever comes in to play when planning things out (so we don't
> attempt approaches again that we already ruled out)"

**What this side reads into it.** A sharpening of M40's split. M40 moved *history* out of the
current-state docs; this moves **progress-tracking** out too — the ticked boxes, the "Done:"
paragraphs, the branch names and status words in headings that had crept back into `TODO.md` and
`HANDOFF.md` within one milestone of the restyle. The reason given is the design of the whole
documentation system in one sentence: done-work narration has exactly one use, which is checking a
planned approach against the approaches already ruled out, and that lookup happens in
`DECISIONS.md` by design. Everywhere else it is weight. Applied the same day to `TODO.md` and
`HANDOFF.md`; the rule is in `CLAUDE.md`; the lint (finding 1) is what keeps it applied.

The playtest files keep their in-place status annotations: they are primary sources and are never
rewritten. The rule applies going forward — status about a finding goes to `DECISIONS.md`, not into
the playtest that raised it.

## 3. The drift guard and stats.sh are wanted

> "drift guard sounds good. stats.sh sounds good."

**What this side reads into it.** Two approvals of proposals made in the same session, recorded so
the entries can say who agreed. The **drift guard** is a session-cleanup step: when
`src/autoload/tuning.gd` or `src/events/event_catalogue.gd` changed in a session, grep the docs for
the names of the constants that moved — because the number re-audit found all of its drift around a
handful of constants that had been retuned (`CROWD_*_PER_ACT`, `STARTING_NERVES`, `BUMP_RADIUS`,
catalogue rows) while the sentences quoting them stood still. **`stats.sh`** is the consumer for
playtest 17 finding 3: the run logs now say whose run they are, and nothing reads the tag, so "how
often is a day lost" still means hand-reading a scratch folder full of rig runs. Both are specified
in `docs/TODO.md` — the guard in M57, the tool in M58.

## 4. A new entity: another mother with child

> "I have an idea for a new entity -- another mother with child. when getting too close one gets
> caught up in a conversation that takes 5s and consumes 25% excitement. if the baby is already
> sleeping it's a pure time loss if it's not it bears overstimulation risk."

**What this side reads into it.** The first authored event whose cost is **time under compulsion**:
nothing else in the catalogue takes the controls away. Every clause of the sentence is doing work,
and the reading of each is recorded here so a wrong one can be corrected:

- *"getting too close"* — a proximity trigger, so the counterplay is distance: the far lane of a
  two-tile pavement, or the other side of the street. She is avoidable by routing, like everything
  that is not a pursuer.
- *"caught up in a conversation that takes 5s"* — the player's movement is taken for five seconds.
  Standing still is already modelled: idle drains sleepiness and freezes excitement decay, so the
  five seconds price themselves through the existing rules on top of the meter cost.
- *"consumes 25% excitement"* — read as **adds 25 points to the excitement meter** over the
  conversation, because the same sentence calls the awake case an *overstimulation risk*, and
  overstimulation is the meter going up. If "consumes" meant *removes*, the awake case would be a
  reward and the risk clause would have nothing to refer to.
- *"if the baby is already sleeping it's a pure time loss"* — read as: **while the baby is asleep
  the conversation adds no excitement at all**. *Pure* is the load-bearing word — a scaled
  contribution through `SLEEPING_SENSITIVITY` (0.55, so ~14 points) could cross the wake threshold
  and cost sleepiness, which would not be a pure time loss. Asleep, the meters do not move (sleep
  pins sleepiness at 100, the chat emits nothing) and the only cost is five seconds of a 180-second
  day — during the return leg, when time is the resource that is left.

What makes it a route decision rather than a toll: the cost **flips sign with the baby's state**.
Outbound with an awake baby she is a quarter of the lose meter and worth a wide berth; homebound
with a sleeping baby she is only the clock. The same body on the same pavement is a different
obstacle in each act of the day, and no other row does that.

Designed as **M59** in `docs/TODO.md`, at implementation depth. The row is `chatting_mother` —
named for what she is, per the rule that nothing in `src/` carries a narrative name.

## 5. Write the plan down; Sonnet 5 implements it

> "let's write the plan down and if needed clean up / rewrite TODO and/or HANDOFF for it. write
> everything detailed enough that a Sonnet 5 can do the actual implementation"

> "once the plan is fully written and committed orchestrate sonnet 5 sub-agents to start the
> implementation."

**What this side reads into it.** The plan is the deliverable and the queue is its home: `TODO.md`
rewritten as a pure queue holding the audit's findings as actionable items (M40's finishing pass,
M57, M58, M59), `HANDOFF.md` rewritten to be true, and each entry written to the standard that an
implementer who has read nothing but the entry and the skills it names can build the thing.
Implementation is orchestrated to Sonnet 5 sub-agents, one milestone per branch, after the plan is
committed.

## 6. Can the game be embedded on a website?

> "one btw question. does godot support website embedding? can we use github pages to put the game
> on a page? or do we need a proper server?"

**Answered in the session.** Yes: Godot exports to HTML5/WebAssembly, the project already uses the
web-friendly `gl_compatibility` renderer, and a web export is static files — GitHub Pages carries
it. The one constraint is that a *threaded* web build needs cross-origin-isolation headers Pages
cannot set; a build with threads disabled, or the `coi-serviceworker` shim, sidesteps it. No server
is needed for a game with no networking. Recorded as a release item under M10.
