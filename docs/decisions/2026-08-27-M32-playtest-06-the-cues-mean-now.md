## M32 — Playtest 06: the cues mean now

See **[docs/playtests/PLAYTEST-06.md](../playtests/PLAYTEST-06.md)**. The first playtest taken on M28–M31, reported
part-way through M21 with the instruction to *"take note of those but continue implementing the
next item on the handoff first"*. **All five are done.** Three were small fixes in code M22, M30
and M6 already owned; one added a row to the vocabulary; and the four of them together are one
sentence — *a cue is a claim about a moment*, which is the axis M30 had not looked along.

- [x] **The difficulty is right.** *"I like the difficulty now — it actually became harder."*
      Not a task; recorded because it is the **first balance number in this game ever confirmed
      by a human**, and `CLAUDE.md`'s "no balance number has been felt by a human" has been true
      since M14
- [x] **The screen-edge badge measures the wrong speed** — *"they show events far away, and if
      you walk towards them they sometimes disappear; also they flicker a lot."* Two of the three
      symptoms were one defect: `DangerEdge` tested the *relative* closing rate against a 20px/s
      threshold and she walks at 92, so **walking towards anything lethal raised its badge**. It
      measures the event's own approach with the player held still now; the range cap is a
      *window* (`LEAD_TIME` seconds of its own approach, so the same 800px is a fire engine and
      not a dawdler); a raised badge is held; and the list is sorted by **arrival** rather than
      by distance, which is what `MOST_AT_ONCE` should be choosing between.
      **The flicker had a second cause the analysis did not predict**: a thing on the screen
      boundary trades places with its own badge every frame, which needed hysteresis on the
      *edge* — a margin outside the view before one may be raised — and no amount of it on the
      closing rate would have helped. Also caught by a trace: the director's `AHEAD_OF_PLAYER`
      events were eligible, so a cat whose entire content is that it is *not* announced was
      raising and dropping a badge inside a tenth of a second
- [x] **The exclamation mark outlives the car** — *"I get the flashing exclamation marks after
      the fact, at which point they're not useful."* `CAR_WARNING_HOLD` is 1.4s and nothing
      lowered the mark when she stepped off the carriageway, where a car cannot reach her at all.
      The hold has a real job — surviving the gap between two cars in one lane — so it is a
      second condition rather than a shorter hold: `Stroller.warn()` takes a **source** and
      `stand_down()` lets that source, and only that source, lower its own mark. A trace of a
      minute of day 3 now shows every span at 0.3–0.7s and **all of it on the road**
- [x] **A lost day is retried, not skipped** — finding 4, and it closes an open design question
      carried since M6. `GameState.finish_day()` no longer advances the calendar on a loss, the
      summary says *"You try day 3 again"*, and the attempt's `settled_in` record is forgotten
      with it — otherwise M24 would spoil a park the winning attempt never went to, and the
      record is written once a day. The run can no longer end by running out of days while
      nerves remain
- [x] **The meters are in the corner and the game is played at the pram** — finding 5, and the
      only one that adds to the vocabulary rather than fixing something in it. Four states over
      the pram — asleep, stirring, not settling, nearly crying — as *states with an instruction*
      rather than a gauge, in the vocabulary's own colours and its own motifs, anchored to the
      pram and stepped aside when the pram is on her own axis so it can never share a column
      with the exclamation mark. `Baby.Cue`, `Stroller._draw_baby_cue()`, three new sprites
- [x] **And the log can see a cue at last.** Not a finding: the gap playtest 05 named and
      playtest 06 walked straight into. Both cue defects were invisible to a trace, because
      every entry said what the *world* did and none said what the game **told her about it**.
      A `cue` entry per span, written when the span ends so the duration is on the line
