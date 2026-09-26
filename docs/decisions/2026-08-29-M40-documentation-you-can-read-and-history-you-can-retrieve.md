## M40 — Documentation you can read, and history you can retrieve · `feature/timeless-docs`

Asked for directly: *"adopt a timeless documenting style. Things should be stated as what they are,
not where they came from. Keep a dedicated file for ideas that were rejected, decisions that were
made (and which options were rejected), and changes that happened."* And: *"especially for
docstrings make sure to document the why and the edge cases; don't restate the full
implementation."* And: *"we don't want to lose history/information — we just want to make the
current state more accessible and the history retrievable on demand instead of always in context."*

**The problem, stated plainly.** This project writes history into the thing itself. A docstring
opens with *"(M39, playtest 10 finding 13: …)"*, a constant's comment is three paragraphs about the
two numbers it used to be, and `CLAUDE.md` is 900 lines in which the rules and the archaeology are
interleaved. That was a deliberate bet — the reasoning is not recoverable from a diff — and it has
paid off repeatedly. What it costs is that **reading the current state means reading every past
state first**, and every reader of every file pays it whether or not they need it.

The fix is not to delete any of it. It is to **split by question**: *what is this and why is it like
this* stays with the code; *what was tried, what was rejected, and when it changed* moves to one
file that is read on demand.

**Sharpened on 2026-09-01, and the second half is new work rather than a restatement.** *"Before we
start implementing anything else we need to bring the codebase up to date with the decisions we
made. There is a lot of stale information where notes are outdated. Let's focus on that and the
timeless writing style so that reading outdated information as current information can never happen
again — all information should **only** reflect the current state **never** past states with
caveats."*

So M40 is **two jobs, and the restyle is the smaller one**:

- **A correctness pass.** Find and fix sentences that are no longer true. This is not a side effect
  of restyling — a stale claim survives a rewrite perfectly well if nobody checks it against the
  code. `docs/HANDOFF.md` opens with *"`main` is `c82bcbb`… 175380 checks"* against a suite that is
  at 202075, which is the failure in its purest form: the file whose whole job is *where to pick up*
  is the file most confidently wrong about where things are.
- **A style pass.** Present tense, current state only. **No "used to be", no "since M33", no "this
  was wrong for twelve milestones", no caveats about what a sentence meant before.** Where the story
  is worth keeping — and this project's whole bet is that it usually is — it goes to
  `DECISIONS.md`, which is *the* place the reader goes for it.

**The test is a reader, not a diff:** somebody who opens any single file and believes every sentence
in it is wrong about nothing.

**The size of it, measured rather than guessed** — `grep -rE '(M[0-9]{1,2}\b|playtest)'`:

| | files | history references |
|---|---:|---:|
| `src/**/*.gd` | 45 of 56 | 590 |
| `CLAUDE.md` | 1 | 141 |
| `docs/` minus the playtests and `TODO` | 8 | 528 |
| `docs/TODO.md` | 1 | ~1000 |

`src/autoload/tuning.gd` alone has 113, `event_catalogue.gd` 50, `event_scheduler.gd` 45. **This is a
multi-session milestone**, and the order below is by where a reader lands first, so that stopping
part way still leaves the project better rather than half-converted.

**Two calls taken here rather than asked, because M40's own text implies both.**

- **`docs/HANDOFF.md` splits along a line it already draws itself.** Its header says *"everything
  below the pick-up block is older history, newest first"* — so the pick-up block **is** the
  current-state document and the tail **is** `DECISIONS.md` in session order rather than decision
  order. HANDOFF keeps the block and nothing else; the tail is the first thing merged into
  `DECISIONS.md`. A third file would be a third place to go stale.
- **What timeless means for a to-do list**, which is the one document that is legitimately about
  time. An **open** item is current state and gets the full treatment. A **ticked** item is history
  the moment it is ticked — so it moves to `DECISIONS.md` with its measurement and its rejected
  options intact, and `TODO.md` keeps the queue. That is what takes 4550 lines back to something a
  person reads before starting work, which is what the file is for and has not been for some time.

**And M40 has been sitting unbuilt since before M41** — about fifteen milestones. It is the third
thing this session found filed-and-not-read, after the interact key (playtest 02, twenty milestones)
and the alley roulette. **Three in one session is not three oversights, it is the symptom this
milestone exists to cure**: the project writes things down faultlessly and cannot find them again,
because everything ever decided is interleaved with everything currently true.

- [ ] **`docs/DECISIONS.md`, the retrievable half.** One file, three kinds of entry, each dated and
      each linking to the milestone and the playtest that produced it: **decisions taken** with the
      options that were rejected and why; **ideas rejected** outright; and **changes that happened**,
      with the measurement that justified them. It is the destination for everything the restyle
      lifts out, so nothing is lost — the test is that every fact removed from a docstring can be
      found by searching this file for the symbol name
- [ ] **Restyle every docstring.** Say what the thing is, why it is that way, and what the edge cases
      are. Do **not** restate the implementation — the code is right there — and do not narrate the
      milestones it passed through. Where a number was tuned against something, keep the
      *relationship* (*"above the 7.7/s decay on the ground it stands on"*) and move the story of how
      it got there. `Tuning.PURSUIT_SHAKEN_OFF` and `Tuning.pursuit_standoff()` are the worked
      examples of what an edge-case docstring should read like
- [ ] **Revisit all documentation, not the code alone.** `CLAUDE.md`, `README.md`, and every file in
      `docs/` — `ARCHITECTURE`, `CITY`, `DESIGN`, `EVENTS`, `MECHANICS`, `NARRATIVE`, `TELEMETRY`,
      `TODO`, `HANDOFF`. The playtest files are already history and stay as they are; they are the
      primary source `DECISIONS.md` cites
- [ ] **`CLAUDE.md` becomes rules, and the rules get subfiles.** Working preferences, invariants and
      recipes stay; the war stories under each move out. Anything too long for one file becomes a
      rule file of its own rather than a longer `CLAUDE.md`
- [ ] **And notes live in the repo, not in a session's memory.** Anything worth remembering about how
      to work on this project goes in `CLAUDE.md` or a rule/skill file beside it — a note that exists
      only in an assistant's memory is a note that gets lost

### The order, and why it is this one

By where a reader lands, so that stopping part way leaves the project better rather than
half-converted. Each is its own commit.

1. **`docs/DECISIONS.md` exists and takes `HANDOFF.md`'s tail.** Nothing can move out of a file
   until there is somewhere to move it to.
2. **`docs/HANDOFF.md` becomes the pick-up block alone, and is made true.** It is the first file the
   next session opens and it is currently the most wrong.
3. **`CLAUDE.md`.** Read every session by everybody, 1500 lines, 141 history references. Rules and
   invariants stay in the present tense; the war stories go. Anything that unbalances the file
   becomes a rule file beside it, which this file already says.
4. **The design docs** — `CITY`, `EVENTS`, `MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `DESIGN`,
   `NARRATIVE`, `README`. These are the ones a person reads to learn what the game *is*, and the
   ones where a stale sentence is indistinguishable from a design.
5. **The docstrings**, 45 files, worst first: `tuning.gd`, `event_catalogue.gd`,
   `event_scheduler.gd`, `city_generator.gd`, `event_instance.gd`, `crowd_agent.gd`.
6. **`docs/TODO.md`.** Ticked items out to `DECISIONS.md`, queue stays. Last because it is the
   biggest and because every earlier step tells you what belongs in it.

**The playtest files are not touched.** They are primary sources — a player's words on a date — and
rewriting one into the present tense would be destroying the only record of what was actually said.
`DECISIONS.md` cites them; it does not absorb them.

### Completed 2026-09-01, merged to `main` from `feature/timeless-docs`

Everything above shipped except the number re-audit, which stayed open as M40's finishing pass in
`TODO.md`. What each part found, with the measurements:

- **`DECISIONS.md` exists** and took `HANDOFF.md`'s history tail; the test held — every fact lifted
  out is findable here by its symbol name.
- **`CLAUDE.md` became an index** over eleven skills in `.claude/skills/`, one per operational
  task, holding only what applies to every task and the rules a hook cannot trigger on.
- **The path-triggered rules became a hook, not an instruction.** *(2026-09-01: "if they are
  triggered by files then make them rules that trigger on those files.")* A skill somebody has to
  remember to load is not a rule. `.claude/hooks/project-rules.sh` fires on every `Edit`/`Write`,
  maps the path to the skills that govern it, and injects them before the edit is made — once per
  area per session, keyed on the session id. The three with no file to trigger on — `feedback`,
  `committing`, `session-cleanup` — stay invoked by hand, being about a *moment* rather than a
  place.
- **The design docs pass** — `EVENTS`, `CITY`, `MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `DESIGN`,
  `NARRATIVE`, `README` to zero history references, one commit each. **The style pass found nine
  stale claims, which is the argument for doing both passes at once**: `AHEAD_OF_PLAYER` "is the
  cat" (it was three rows), the pre-per-block event budget formula, `construction` as "the only act
  I event in the way", `cat_dash`'s duration, an 8×8 junction lattice and 112 streets, "nineteen of
  a hundred" signalled junctions, `PARK`'s sleepiness and decay multipliers, a 104×104 city, and a
  car population of thirty. **`charging_dog` had no row in the catalogue table at all.** Two
  obsolete measured tables moved here rather than being restyled in place.
- **The docstring pass** — every `.gd` file in `src/` to zero history references
  (`grep -rcE '(M[0-9]{1,2}\b|playtest|Playtest)' src --include='*.gd'` left four hits, all the
  ordinary word in `main.gd`'s is-this-log-a-playtest function). **The rewrite that works is
  turning a narrated fix into the mistake a reader could still make**: *a contract in seconds
  cannot describe a pursuit played out in distances*, *never guard on a `CanvasLayer`'s `visible`*,
  *a category in an enum is a list waiting to happen*. **The pass found five stale claims and one
  dead field**: the mark docstring's "fifteen of the eighteen rows" (the catalogue had thirty-one,
  six lethal) and its "no lethal events in acts I and II" (the cyclist is day 2),
  `street_network`'s "64 junctions and 112 segments" (144 and 264), `main`'s "eighteen kinds" and
  its list of "four things a picture cannot carry" that named three, two crowd sizes quoted as four
  and five hundred against a cap of 200, and `EventDef.act_tag`, set on eleven rows and read by no
  game code.
- **`TODO.md` became a queue again** — open work only, completed entries archived here whole.

### The number re-audit, run 2026-09-01

Run as its own pass, as designed — a stale claim survives a rewrite perfectly well if nobody checks
it against the code. Four audit agents checked every quoted number in the governed docs and
docstrings against `tuning.gd`, `event_catalogue.gd` and the code they describe, the tooling
against its own documentation, and the docs against each other, on a tree where the full suite was
green. **Found: eight wrong numbers, three docstrings pointing at `CLAUDE.md` sections that had
moved into skills, four pieces of history that outlived the restyle, and stale evidence
attributions** — filed as M40's finishing pass in `TODO.md`. **Verified correct, row by row**:
every other quoted figure in `CITY`, `EVENTS` (all 31 catalogue rows' intensities, radii,
telegraphs, speeds, durations, day windows, weights and caps), `MECHANICS` (the meter rates, the
contact and car geometry, the falloff, the pursuit tables), `ARCHITECTURE`, `NARRATIVE` (the
six-step resistance calendar) and `HANDOFF`. The audit also found the same session's tooling gaps
(M58's items) and the dead-code list (M58's sweep), and confirmed the rules hook's path→skill
mapping correct on all nine rows, all eleven skills' ~90 cited symbols resolving, and the
`PARTIAL RUN` marker working as documented.

### The finishing pass, built 2026-09-01 · `feature/numbers-against-the-code`

All of the re-audit's findings fixed, one commit each, suite green throughout. The outcomes worth
keeping: NARRATIVE's crowd drop and MECHANICS' contact measurement became relationships rather than
figures; ARCHITECTURE's concurrency literal was dropped entirely after **three sources gave three
different figures for the same formula** (22, 25, ~32) — the linear-scan argument never needed the
number, and `CLAUDE.md`'s and the events skill's copies were fixed in the same session; DESIGN's
nerves went 3 → 5 and CITY's calm-area floor 3 → 5 to match `STARTING_NERVES` and
`MIN_CALM_BLOCKS`; the phantom `sabotage_run` row left `EVENTS.md` (the day-14 sabotage is
`GameState` logic, not an `EventDef`); `act_tag`'s true sentence is now "no game code reads it; one
test holds it consistent with the calendar"; three docstrings that cited `CLAUDE.md` for rules that
had moved into skills now state the rule or name the skill; EVENTS' dated six-seed role-weighting
table moved here (M50's section); the city and events skills' "used to" narrations were restated in
the present tense; `_place_home`'s superseded sort-by-distance story (already here under M42) left
the docstring; and `evidence/README.md`'s rows now name the document that actually cites each file.

### Reassessed on 2026-09-01, and closed

- **The pending calm-ground multiplier is planned against a stale base** — *done.*
  `SLEEPINESS_CALM_ZONE_MULTIPLIER` is 21, which is the 1.5× taken on the correct base, and the
  correction travelled with it.
- **A bug closed inside a design finding was never closed out** — *done.*
  `CrowdLanes.PRECINCT_OFFSETS` is six lanes across the whole width. The shape is worth watching:
  **a finding with two halves gets closed when the louder half is done.**
- **M41's eight open boxes** — the milestone is merged and its work shipped; the boxes were never
  ticked. What genuinely remains is in M53 (T-junctions at the edge) and M49 (judged by eye).
- **M27's "nobody has played it"** — superseded. Seven playtests have happened since.
- **M20's overtaking, eight-way driving and the crash event** — **parked with the player's
  agreement**, as *a conversation that is owed*, not as a thing nobody wanted.
- **M17, the route map** — **backlogged by the player's decision.** The gap it closes is real and
  `docs/CITY.md` states it as a gap rather than papering over it.
- **M52's "should more junctions be signalled?"** — parked, unasked-for, and it would repeal *"a
  property of the street rather than a scattering of them"*.
