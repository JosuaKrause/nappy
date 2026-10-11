priority: now

# quiet-lynx — Checkpoints, and a Hard Mode that has none · filed 2026-10-11

**Band: `now` is the filer's proposal.** The note carried no `queue_<band>` label and the player
named no band, and it is a feature the player asked to have built.

## What the player asked for

Filed from inbox #678 ([gentle-osprey](../../playtests/2026-10-11-gentle-osprey.md), statements 1 to 8). In their words:

> I want to introduce a partway continue checkpoints. what are good days for checkpoints that restart after game over with 5 nerves? also on that note I want a "Hard Mode" checkbox on the title screen (if new game) that decides whether checkpoints are available. with hard mode the escape also has normal nerve counts and ends if nerves go to zero (instead of restarting indefinitely; this is only for normal mode). needs telemetry whether someone chooses hard mode and whether they are restarting from a checkpoint after losing all nerves
> ([statement 1](../../playtests/2026-10-11-gentle-osprey.md))

And, answering the assistant's questions on the issue:

- Checkpoints are days 4, 8 and 12: "4, 8, 12 (Recommended)" ([statement 3](../../playtests/2026-10-11-gentle-osprey.md)).
- A game over before the first one: "Day 1, same city (Recommended)" ([statement 3](../../playtests/2026-10-11-gentle-osprey.md)).
- Hard mode's escape: "Section won gives one back" ([statement 3](../../playtests/2026-10-11-gentle-osprey.md)).
- Telemetry: "in addition to the above we should also count regular day starts with mode. so we know how far people get in each mode. the event stats (influence/lethal/etc) should not include hard mode since hard mode doesn't affect gameplay -- only restart pacing" ([statement 3](../../playtests/2026-10-11-gentle-osprey.md)).
- Normal mode at 0 nerves: "No game over in normal (Recommended)" ([statement 5](../../playtests/2026-10-11-gentle-osprey.md)).
- Day starts by mode: "Add a hard-only copy (Recommended)" ([statement 5](../../playtests/2026-10-11-gentle-osprey.md)).
- "store the exact state at the checkpoint -- continuing should not have anything that happened after the checkpoint" ([statement 6](../../playtests/2026-10-11-gentle-osprey.md)).

## The shape, in one paragraph

A new game offers a **Hard Mode** checkbox on the title. Unchecked (normal), the run has checkpoints
at the first day of acts II, III and IV (days 4, 8, 12) and day 1 is checkpoint zero: running out of
nerves puts her back at the latest checkpoint reached, with 5 nerves, in the same city, in exactly
the state the run had at that checkpoint's dawn, and never shows the GAME OVER ending. Checked
(hard), there are no checkpoints and the days are today's rules, but the escape also spends nerves:
a lost section costs one, a cleared section gives one back, and 0 ends the run. The mode changes
nothing about what the city does. The items beside this file split the work.

## Quoted where the entry touches an earlier word

- **PLAYTEST-28, finding 4, stays as written** ([PLAYTEST-28](../../playtests/PLAYTEST-28.md)): *"the game over screen cannot have a continue button"*. Normal mode never reaches that screen, so its continue button
  is the lost-day screen's, and the GAME OVER screen is hard mode's only. See [out-of-nerves-in-normal.md](out-of-nerves-in-normal.md).
- **PLAYTEST-143 stays as written** ([PLAYTEST-143](../../playtests/PLAYTEST-143.md)): *"restart button restarts the game from scratch -- not sure why that was ever a question?"* The pause screen's held restart starts from scratch in both modes, never from a checkpoint.
- **The escape's "no nerves" is narrowed to normal mode, at the player's own word.** pebbly-penguin, statement 3 ([pebbly-penguin](../../playtests/2026-09-27-pebbly-penguin.md)): *"escape doesn't have nerves"* · *"escape has no nerves was already preexisting you should have it in your records"*, and the M102 record (`docs/decisions/2026-09-09-M102-the-finales-brief-and-the-collisions-the-player-answered.md`, item 2): *"Losing the finale restarts the section, at no Nerve cost."* ("sounds good at that point you earned it.") Statement 1 asks that hard mode's escape "also has normal nerve counts"; normal mode's escape is unchanged. See [hard-escape-nerves.md](hard-escape-nerves.md).
- **Decision 2 of the 2026-08-26 decisions** (`docs/decisions/2026-08-26-the-decisions-that-govern-the-next-milestones.md`): *"Difficulty is self-selected through the extra quests. The resistance is the dial. That is why the base game has to be hard on its own — the dial *adds* difficulty, it does not supply it."* The entry reads it as not overturned, and **that reading is the filer's, open to overturn**: checkpoints change only what running out of nerves costs, never how hard a day is to walk, so the base game stays as hard as it is and the resistance stays the gameplay dial. It rests on the player's own words, *"hard mode doesn't affect gameplay -- only restart pacing"* (statement 3). A player who would have lost the run now gets a retry from a checkpoint, which is softer in the way the player asked for, restart pacing.
- **The title's class doc says "There are no options"** (`src/ui/title_screen.gd`: *"What it is not is a main menu. There are no options, no seed box and no load game"*). The checkbox is the one option, and the player asked for it; the doc changes with it. See [hard-mode-checkbox.md](hard-mode-checkbox.md).
- **Nerves and saves**: `docs/MECHANICS.md` "Nerves" (a lost day costs one, a won day gives one back, *"A nerve buys a retry of the same day"*), "Saving and resuming" (the save holds the run, never the moment inside a day) and the escape's "A lost section starts again where it began, and costs no Nerve" are the passages that change with this entry, in the same pull request that builds it.

**Every doc a cold build must make true** (each says today that nerves at 0 ends the run, or that the bad ending is the way to lose; all become hard-mode-only or gain the normal-mode checkpoint):

- `docs/MECHANICS.md` "Nerves": the bullet *"The run cannot end by running out of days while nerves remain. The bad ending is the only way to lose"* (hard mode only), the opening paragraph's *"At 0 the run ends with the bad ending"*, *"The escape gives none back"*, and the escape's "A lost section starts again where it began, and costs no Nerve".
- `docs/MECHANICS.md` "Saving and resuming": what a save holds (the mode and the checkpoint snapshot), and the passage that says a load spending the run's last nerve shows the ending (*"the day brief never shows at all — the ending does"*), which in normal mode shows the lost-day screen.
- `docs/DESIGN.md`, the endings table row *"Bad ending | Nerves hit 0 — the mother breaks, leaves the city, nothing changes."* (hard mode only).
- `docs/NARRATIVE.md`, the section "Bad — Nerves at 0" (*"Whichever day it happens on, the run ends."*): the bad ending is hard mode's.
- `docs/TELEMETRY.md`: the new event names.
- `src/ui/title_screen.gd`'s class doc, and the comments in `src/main.gd` (about the last nerve ending the run, near the resumed-save charge) and `src/ui/day_summary.gd` (the GAME OVER ending's comments), which say the last nerve ends the run.
- **Records that now describe hard mode's GAME OVER screen**, not every run's: striped-lemur ([the game over screen shows the day you made it to](../../decisions/2026-09-27-striped-lemur.md)) and M206 ([a game over's continue and a held restart](../../decisions/2026-09-25-M206.md)). A record is not rewritten; the build says in its own decision record that these two now apply to hard mode.

The grep behind this list searched `docs/*.md`, `docs/decisions/` and `src/` for nerves at 0, last nerve, out of nerves, game over and bad ending.

## Answered, no change needed

The player asked (statement 5, "can the player get into a situation where they won't be able to complete enough tasks from a checkpoint? should we care?"). No new trap, and nothing to build: tasks belong to their days (days 6 to 13; the goal is 5 plus the day-14 sabotage), so a run can already be past the good ending before any checkpoint, and a checkpoint restores exactly what the run had at that dawn, no more and no fewer tasks done. Winning day 14 still gives the neutral ending.

The player followed up (statements 7 and 8): *"what I mean is if I neglected tasks in Act 2 and I get the checkpoint in Act 3 I won't be able to get the good ending at all, right?"* The answer: not quite. There are 8 tasks (one each day 6 to 13: act II has 2, act III 4, act IV 2) and the good ending needs 5 plus the day-14 sabotage, so skipping both act II tasks and returning to checkpoint 8 still leaves 6; it is gone once tasks done plus task days left falls below 5. **Outcome: "okay sounds good" -- leave it as it is.** Nothing on the out-of-nerves screen mentions tasks, and the held restart is the fresh start. The alternative, the out-of-nerves screen offering a start over when the good ending is already out of reach, was not taken.

## Open

Nothing is open for the player. Marked as the filer's proposal in the items: the checkbox's start state, what shows during play, where the snapshot rides in the save, the old-save fallback, the lost-day line's wording, and the run-log lines.

## Items

- [hard-mode-checkbox.md](hard-mode-checkbox.md) — the title's checkbox, and the mode carried in the save.
- [checkpoints.md](checkpoints.md) — the days, and the exact state stored and restored.
- [out-of-nerves-in-normal.md](out-of-nerves-in-normal.md) — what the last nerve does in normal mode.
- [hard-escape-nerves.md](hard-escape-nerves.md) — the escape spends and regains nerves in hard mode.
- [telemetry.md](telemetry.md) — the GoatCounter events.
