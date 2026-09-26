## Gotchas learned in M32

- **A cue whose condition is not the thing it claims to mean is invisible to every test in the
  suite.** `tests/test_danger.gd` asserts *which* things are marked, over the whole catalogue,
  and both of playtest 06's defects were about **when**. Two milestones' worth of careful rules
  about membership, and the next complaint came from the other axis entirely.
- **A hold cannot tell "the danger is between two cars" from "the danger is over".** Only the
  system that raised it can, which is why the fix is a source and a `stand_down()` rather than a
  shorter hold — and why the source check matters: a caller that has been outbid finds nothing
  of its own to lower, so this is not the setter the additive rule exists to prevent.
- **Two hysteresis problems in one cue, in different units.** The closing test needed a hold, in
  seconds. The screen boundary needed a margin, in *screen* pixels — a thing on the edge trades
  places with its own badge every frame, and the world is drawn scaled, so the same question in
  world pixels has no fixed answer. The write-up predicted the first and not the second.
- **A range cap wants to be a window, not a distance.** The same 800px is a fire engine four
  seconds away and a dawdler twenty seconds away. Stated as `LEAD_TIME` seconds of the thing's
  own approach, the cap scales itself and is in the units the fairness contract is already
  written in.
- **A cap on how many cues show is a choice, and distance is the wrong basis for it.** Sorting by
  distance means `MOST_AT_ONCE` drops the thing arriving first in favour of a slow thing standing
  closer. Sort by arrival.
- **The thing whose whole content is that it is not announced was being announced.** The
  director's `AHEAD_OF_PLAYER` events were eligible for a badge, so the cat M27 rebuilt to
  *happen to her* got a pre-announcement — which flashed for a tenth of a second and vanished,
  because it walked into view immediately. Found in a trace, not in a test.
- **The observer must name the cause, not the nearest thing.** The first `cue` entry reused
  `_nearest()` and blamed an ice cream van 513px away for a car's horn — reproducing, inside the
  log written to settle it, the exact *"unattributable"* complaint playtest 05 made about the
  mark. Two things raise that mark and the observer can check both.
- **A cue span is written when it *ends*.** The complaint is a duration — "it is still up and
  the car has gone" — and a duration cannot be read off a line saying a cue went up. Every `cue`
  entry carries how long it lasted, and the mark's carries how much of that she spent on the
  road: **0.3–0.7s, all of it on the road**, is what the fix looks like in a trace.
- **`--walk south` can walk into a wall and stay there for seventy seconds.** A day-12 probe run
  produced one cue and a column of `crowd` bumps at the same tile. A walking probe is not a
  player; check the tiles in the trace before concluding anything about the density.
