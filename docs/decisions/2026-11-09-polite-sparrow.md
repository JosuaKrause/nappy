# polite-sparrow — The domain skills after the rules review: true against the code, one owner per rule, detail in reference files · 2026-11-09 · not from an entry

**The ask.** The player had a review made of every rule file ("have another fable agent review all
skills/claude/rule files", inbox #1267), read its summary, and said "let's do all the suggested
changes for the hooks/skills/claudes etc", "four PRs is fine with me -- can we parallelize?" and
"for the rule/skill/claude changes I want fable to do it directly" (inbox #1267). The work was split
by files into four pull requests. This record is the one for the thirteen skills about the game
itself: events, crowd-traffic, city, balance, telemetry, cues, godot, svg-art, illustrated-png,
reference-photos, sound-effects, session-captures and rejected-graphics.

## What the review found in these skills

- **The rules did not arrive.** A hook's injection is shown inline only when it is small; a larger
  one arrives as its first two kilobytes and a file path. Where a skill's must-see rule sat decided
  whether a session saw it: the events skill's fairness contract started about four kilobytes in,
  the crowd-traffic skill's contract for lethal traffic about eighteen.
- **Sentences that were false against the code:** the telemetry skill taught a frame-timing API
  that does not exist (statics on `FrameRecord`, where the code hands each timed system a
  `FrameTiming` sink); six skills named suites that do not exist (`tests/test_events.gd`,
  `tests/test_routes.gd`) as the thing enforcing a rule; functions and constants were named on the
  wrong class.
- **The same rule in several skills**, with the copies free to drift: `art/`'s `.gdignore` and the
  import sidecar in five places, the event car's give-way rule in two, and four passages of the
  events skill restating `docs/EVENTS.md`.
- **Skills that disagreed:** whether art is converted to PNG; which question a traffic light
  answers; how a new evidence folder is named.

## What was built

- **Each skill opens with "The rules not to miss"**, one line per rule, inside its first two
  kilobytes; the detail a coder needs only for one kind of change is in a reference file under the
  skill's `references/`, which the skill names with when to read it.
- **The telemetry skill's frame-timing section is written from the code**: a timed system is handed
  its timing sink and wraps its body; how a bucket and a drawn kind are added; a `_draw()` override
  carries no counting code.
- **Every sentence naming an enforcing suite names the suite that does it**, and a rule no check
  holds says so (below).
- **One owner per rule:** godot owns the `.gdignore` rule; the events skill's `event-cars.md` owns
  the give-way rule; `docs/EVENTS.md` owns what the events skill had copied, with three sentences the
  doc does not hold kept in the skill; session-captures owns the evidence folder's name.
- **svg-art opens with the hold on converting art to PNG, and illustrated-png with the stop for
  Claude Code**; the generation procedure, which only Codex can run, is a reference file, moved
  unedited.
- **The proposals are listed once at the end of a file** (godot, cues, session-captures), and the
  past-tense passages and drifting figures are out of the rule files (below).

## Rules nothing enforces

Found while matching each rule to its suite; each skill now says the rule is unenforced:

1. **Nothing else is placed inside a lethal event's field** (events). The placement rules do it
   (`StreetInvalidation.room_around()`), `tests/test_events_costs.gd` holds only who is exempt, and
   no suite walks a planned day to check it.
2. **Anything new that closes a street goes through `ClosurePlanner`** (city). The closure rigs see
   only what the planner plans.
3. **No illustrated PNG of the pelican cyclist under `art/illustrated/`** (illustrated-png).
   `tests/test_pelican.gd` has no such check.

## Where the review was wrong

- It called the citation of PLAYTEST-144 8 for the evidence folder's name a mismatch. The player's
  words under that statement accept the naming table just above it, whose row gives an evidence
  folder its entry's name, so the citation stays, with what it rests on said beside it.
- It missed the first of the unenforced rules above.

## Choices made in the rewrite, open to the player's overturn

- Which passages became reference files, and their names.
- The caret drawn by `Sprites.draw_caret()` is stated as the one exemption from "a symbol is never
  assembled at runtime", worded as "because its width and colour are live state", and listed as a
  proposal: PLAYTEST-29 3 names no exemption.
- Two extensions of the evidence folder's naming are listed as proposals in session-captures: a
  playtest's evidence takes the playtest's name, and nothing new goes into the archive folder.
- The rejected-graphics skill's split between an in-review rejection and an out-of-service removal
  says "the player's choice" with no citation, since no playtest statement holding those words was
  found.
- A constant's value in brackets was dropped wherever its sentence was rewritten, leaving the
  constant's name.

## History taken out of the skills

Kept here word for word, each with the rule it stood beside.

**telemetry** (the frame record's timing wrap is the one exception to "per-frame checks go in the
observer"):

- The date in "…and the player accepted the exception itself (azure-tapir #526) on 2026-10-04."
- "A thing timed **once per body per frame** (a live event) copies the switch when it is made, so
  off it pays one member read: a static read and a second call on each of a couple of hundred bodies
  made every player's frame measurably longer on a desktop
  (docs/evidence/m159-frame-record-2026-10-04/). It is made per day, after the recorder has started."
- "A step that re-ran itself could not take back what the inner run emitted, which is why a car's
  frame is proposed and committed by its driving (`EventCarDriving`) rather than by a second run."

**events** (a car that parks where it arrives must not reach past where it parks):

- "uncut, it warned her past the kerb of a strike it could not make, ended the day parking short of
  her, and stood off screen for her there."

**events, figures quoted beside a constant's name:**

- "`EventScheduler.WALL_WORTH_OF_COST` (48 points)"
- "the warning is badge to visible (its half second), the chase is lunge to catch (0.35s, 0.60s and
  2.05s walking into it, standing and walking away)"
- "the planned convoy telegraphs in the world (4.43s, with a badge because 120px/s is faster than a
  walk)"
- "`Tuning.OUT_OF_SIGHT` (420px)"
- "`Tuning.PURSUIT_TIME`, a long cap (30s)"
- "`EventScheduler.OBSTRUCTION_A_PARK_CAN_HOLD` (16.0px)"
- "the 6-second backstop"

**crowd-traffic, figures quoted beside a constant's name:**

- "(26px long, 14px either side), never its whole 52×28px body"
- "`CAR_ZEBRA_SIGHT` (200px)"
- "`CAR_HORN_SIGHT` (296px)"
- "the zebra's own 200px sight circle"

**cues:**

- The halo: "*Asked for no rings and no drawn fields, held since the vocabulary was written ·
  overturned on 2026-09-07 for one specific cue (M89-a-halo-says-what-is-costing-her), because the
  player asked for exactly this: a soft halo around the entities actively causing excitement, a hint
  at what to walk away from.*"
- The halo's transparency: "*(asked on 2026-09-07 for brightness to show distance · overturned on
  2026-09-08: only the amount received counts, colour and transparency are not the same number, and
  transparency emphasizes low values)* (PLAYTEST-38 3)"
- The amber caret: "**The amber caret is the one exception, and it is the player's own overturn.**
  *(Asked on 2026-09-08 for the source's own velocity with her position fixed, so that her own
  walking cannot raise or lower it · overturned on 2026-09-20: the caret is the net gain she very
  likely gets if she keeps doing what she is doing, so the halo roughly matches it when she does.)*
  (PLAYTEST-115 7)"

**godot** (a press read in `_unhandled_input()` must cross every `Control` above it):

- "(The title's Hard Mode box took no tap or click at all while a full-width scrim left at STOP sat
  over it, and its test, calling the handler, passed.)"

**rejected-graphics** (where rejected artwork goes):

- "*(2026-09-23: the player chose this split between an in-review rejection, which stays with the
  family that produced it, and an out-of-service removal, which moves to this archive.)*"
