# Playtest 03 — the first one with a log

The third human playtest, and the first read against a run trace rather than a recollection.
Four findings and one bug, all of them measured off
`run-2026-08-26T225417-seed437307357.log` unless stated otherwise.

**Read [PLAYTEST-02.md](PLAYTEST-02.md) first.** Two of the four findings here are the same
findings, arriving again with numbers attached; that is worth knowing before treating them as
new work.

---

## The day that was traced

Day 1, seed 437307357, won in 103.9 seconds of a 180-second day. In full:

| What | When | For how long |
| --- | --- | --- |
| Walked from the doorstep to a courtyard | 0.0 – 57.0 | 57s |
| Walked in circles inside the courtyard | 57.0 – 77.4 | 20s |
| Walked home | 77.6 – 103.9 | 26s |
| **Encountered anything at all** | — | **never** |

That last row is not a summary, it is a count: **the trace contains zero `near` entries for
the entire day.** The player crossed the city and came back and was never within reach of a
single event.

---

## Finding 1 — four events is not a city

Day 1 places **four** non-attributable-to-the-map events across a 7×7-block, 104×104-tile
city. One event per twelve blocks.

The arithmetic is not subtle. `EventScheduler.budget_for(day)` is `3 + floor(day * 1.4)`, so
day 1 has a budget of 4, and every act-I event costs the default 1:

| Day | Budget | Act-I events at cost 1 |
| --- | --- | --- |
| 1 | 4 | 4 |
| 7 | 12 | 12 |
| 14 | 22 | 22 |

The traced day got `cat_dash x2, dog_walker, homeless_yeller` — exactly the budget — plus one
ambient `playground`, which is part of the map rather than something that happened.

**What the player asked for**, in their words: events "should spawn in when walking in on a
block or should be way more frequent", and "all events etc should be common enough that they
are posing a genuine change in behavior".

### The tension, which has to be settled before the number moves

**More events does not mean more consequence, and right now it would mean almost none.** The
cost table under playtest 02's finding 7 measured every event in the catalogue: eleven of
eighteen cost under fifteen points of a hundred-point meter to walk *straight through the
centre of*, and three are negative — walking through a `dog_walker` beats walking around it,
because the walking decay outruns what it emits.

So quadrupling the budget today buys four times as much scenery. The traced day is evidence
for that read rather than against it: the player never went near an event, and it made no
difference to the outcome, because going near one would not have made a difference either.

**The frequency change and M19 are the same change.** M19 is what makes a street cost
something — collision, lethal cars, pavement hazards that make one side of the street the
wrong side. Density without it is noise; density with it is the thing the game has been
missing since M14. They want landing together, and the numbers want setting from traces
afterwards, per decision 11.

### Two different asks inside one finding

The player named two mechanisms and they are not the same work:

- **"Way more frequent"** is `budget_for()` and a pass over the catalogue's `cost` and
  `max_per_day`. A number, gated on M19 for the reason above.
- **"Spawn in when walking into a block"** is a new mechanism, and a bigger deal than it
  sounds: today a day's events are placed once at dawn from the day's seed, which is what
  makes a day learnable and what `tests/test_events.gd` and the fairness contract are stated
  over. Spawning on approach means events that exist because of where the player went.

  That is not automatically wrong — it is close to what M24 already plans to do to calm zones,
  and a deterministic version is possible (seed the roll from the day plus the block, so the
  same block entered on the same day always does the same thing). But it interacts with the
  telegraph fairness contract in a way that needs stating: an event that appears because you
  walked in has no edge you were outside of, so "start walking away the instant it becomes
  visible and get clear" has to be re-derived for the spawn-on-entry case rather than
  inherited.

**Recommendation:** do the frequency half with M19, and treat spawn-on-entry as a separate
design item with the fairness contract worked out first. Filed as an open question below
rather than decided here.

## Finding 2 — the calm stretch is twenty seconds of walking in a circle

Measured: entered the courtyard at 57.0 with sleepiness 15, asleep at 77.4. In between, seven
`turn` entries — one every 2.5 seconds — and nothing else.

```
  57.0  calm     entered courtyard (2,5), sleep 15
  59.7  turn     doubled back east
  61.9  turn     doubled back south
  64.3  turn     doubled back west
  66.6  turn     doubled back north
  69.1  turn     doubled back east
  71.9  turn     doubled back south
  74.5  turn     doubled back west
  77.4  asleep   asleep after 77.4s, exc 0, in 0.0/s (crowd 0.0, events 0.0), sleep 100
```

M18 already made calm ground ten times the street rather than 3.5 times, which cut this from
about a minute to twenty seconds. The player's report is that it *still* feels wasted, and the
trace says why — and it is not the length.

### The circling is what the rules ask for, not a symptom of the length

`Baby._update_sleepiness()`: standing still **drains** sleepiness, at
`SLEEPINESS_DRAIN_IDLE` = 1.0/s. Walking on calm ground fills it at
`SLEEPINESS_GAIN_WALKING * SLEEPINESS_CALM_ZONE_MULTIPLIER` = 4.2/s. A calm block is a few
tiles across. So the optimal play on reaching calm ground is *walk in the smallest circle that
keeps you on it*, and that is exactly what the seven `turn` entries are.

**Shortening the stretch reduces the number of laps. It cannot remove the lap.** Any change
that keeps "progress requires motion" and "calm ground is a small area" produces circling,
because those two facts are jointly sufficient for it. This is why M18 did not fix it and why
another balance pass will not either.

The three ways out, none of them free:

1. **Let calm ground fill while stationary.** A bench, a pram rocked on the spot. Removes the
   circling completely and removes the "keep walking" pressure with it; the idle drain is what
   currently stops a player parking on the doorstep, so it would need replacing.
2. **Make the calm area big enough that a lap is a walk.** M21 already plans four-block calm
   zones. That turns the lap into a route, which is the game's actual verb.
3. **Put something in the calm area to be doing.** Contested calm — a playground on one side,
   a park keeper, something that makes *where in the park* a decision. The playground already
   half does this and did not appear in the traced courtyard.

**Recommendation: 2, and it is already scheduled.** M21's four-block calm zones are the
structural answer, and this finding raises its priority relative to M20. Worth re-measuring
with the log afterwards rather than assuming.

## Finding 3 — the walk home is free

```
  77.4  asleep   asleep after 77.4s
  81.3  cross    stepped into the road at (43,73), at a zebra
  86.2  cross    stepped into the road at (43,59), at a zebra
  91.1  cross    stepped into the road at (43,45), at a zebra
  95.9  cross    stepped into the road at (44,32), at a zebra
 101.7  cross    stepped into the road at (47,17), at a zebra
 103.9  home     WON, 76.1s to spare
```

Twenty-six seconds, five road crossings, **zero encounters**, and 42% of the day left over.
The return phase is a formality — walk back up the corridor you came down.

The rules that should make it dangerous exist and do not bite: a sleeping baby is at
`SLEEPING_SENSITIVITY` 0.55 and wakes at excitement 60, and nothing on a day-1 street gets
near that. The one mechanism that *would* — being woken and having to walk her down again —
never fires, because there is nothing out there to fire it.

**This is finding 1 wearing a different hat.** An empty city is empty in both directions. It
is listed separately because the fix might not be the same one: the return phase could deserve
its own pressure (a curfew closing behind you, patrols that were not there on the way out)
rather than just more of the same events. M25's patrols are the obvious candidate and are
already scheduled behind M19.

## Finding 4 — the pause never paused *(bug, fixed)*

Reported as "when losing or winning message is on screen all player movement should stop".
Confirmed and considerably worse than it looked.

`main.gd` sets `process_mode = PROCESS_MODE_ALWAYS` on itself so that Esc still quits while
the summary screen has the tree paused. Process mode is **inherited**, and every child
defaults to `PROCESS_MODE_INHERIT` — so the city, the player, the crowd, the event manager and
the resistance director all inherited the exemption. `get_tree().paused = true` has been
running since M6 and pausing nothing.

Consequences, in rough order of how bad they were:

- The player kept walking behind the screen saying the day was over, which is what was
  reported.
- The **resistance deadline kept running out** during the summary. A timed step could expire
  while the player was reading about the day they had just finished, and the contact is lost
  for the rest of the run when it does.
- The crowd and every live event kept ticking, so a day restart began from a world that had
  drifted for however long the summary was up.

Fixed by `main._pauses_with_the_game()`, called on the city, the day controller, the
resistance director and the telemetry observer. Verified by instrumenting the player and a
crowd agent across the transition: both freeze on the exact frame `paused` becomes true.

**Not covered by a test**, and worth being honest about why: it is a property of how the boot
scene wires process modes, and reproducing it needs the real `main.tscn` with a generated city.
It is recorded as a gotcha in `CLAUDE.md` instead, with the rule that a new node under `Main`
needs the call. That is weaker than a test and it is what is there.

## Finding 5 — the log could not answer the question it was asked

The first question put to M23's telemetry, one day after it shipped, was: *I walked on the
road for a significant amount of time and walked with / on top of a car — is that clear?*

It was not. Two gaps, both now closed:

- **Road time was not recorded, only road entry.** Walking a mile down the middle of the
  carriageway produced the same five `cross` lines as crossing at every junction. There is now
  a `road` entry, written when a stretch on the road outlasts the time crossing one takes — so
  **the entry existing is the answer**, and no coordinate arithmetic is needed to see it. A
  stretch still in progress when the day ends is flushed too, which was a second bug: a player
  killed by the traffic they were walking among got no entry at all, having never left it.
- **The crowd was invisible.** Deliberately — 530 agents would bury the log — but that also
  meant a car driving through the pram left no trace but a meter bump indistinguishable from
  passing close by. There is now a `crowd` entry for an agent standing where the player is.
  Pedestrians are rate-limited; cars are not.

Both are in the same day-1 walk now:

```
   0.7  crowd    a car drove through her at (45,52) | exc 11, in 14.4/s (crowd 14.4, ...)
   7.8  road     7.5s on the road (5.4s of it carriageway), (44,52) -> (45,72)
```

**The lesson is about the tool, not the entries.** A telemetry format is only as good as the
first real question asked of it, and the way to find out is to ask one — not to reason about
which fields would be useful. That is now a line in `CLAUDE.md` next to the screenshot rule,
and it is the same rule.

---

## Decisions

Taken as recommended defaults unless stated otherwise.

1. **Event frequency lands with M19, not before it.** More events without consequence is more
   scenery, and the cost table says today's events have almost none. The budget pass and M19's
   mechanisms are one change.
2. **The circling is structural, and M21 is the answer to it.** Not another balance pass: any
   rules where progress requires motion and calm ground is small produce a lap. Four-block
   calm zones turn the lap into a route.
3. **M21 rises relative to M20.** Finding 2 makes the city overhaul the fix for something the
   player actually complained about; traffic that follows and overtakes is not.
4. **The return phase gets its own pressure, eventually.** Filed against M25 rather than made
   a new milestone — patrols that were not there on the way out are already the shape of it.

## Open questions

- [ ] **Should events spawn on entering a block?** The player asked for it explicitly. It
      needs a fairness contract first: an event that appears because you walked in has no edge
      you were standing outside of, so "walk away the instant it is visible and get clear"
      does not carry over. A deterministic version is possible (seed from day + block). Not
      scheduled.
- [ ] **What replaces the idle drain if calm ground ever fills while stationary?** Option 1
      under finding 2. The drain is currently the only thing stopping a player parking on the
      doorstep, so it cannot simply be removed.
- [ ] **Is 42% of the day left over a problem or the point?** The traced day won with 76
      seconds spare and never met anything. Whether the slack should be filled with danger or
      the day should be shorter is a question M19 will answer better than argument will.
