# Playtest 08 — the day-3 dog, and the things that are not there

The eighth human playtest, taken on `c2e048d` (M34). Five things, and the run it came from ended
on **day 3** with a `bad` ending — the shortest run any playtest has produced.

It is also the first playtest whose central finding is a **question about the log** rather than
about the game: *"is there enough telemetry to tell what happened?"* The answer was no, and why is
the most useful thing in this document.

---

## The one sentence

**Three of the five are the same complaint: a thing exists, and being near it changes nothing.**

The robber in the park does not deny the park. The pigeons do not do anything. And the things that
move stop existing in front of you rather than going anywhere. Each of them is authored content
that the player looked at, walked to, and found had no consequence — which is playtest 07's
sentence (*"every cost in the game is paid on contact"*) surviving a milestone that was supposed to
answer it.

The other two are the day-3 running lesson, which killed the run, and a number.

---

## The findings, as reported

| # | What the player said | Kind |
|---|---|---|
| 1 | "the robber in the park is still ineffective — I can use the same park every day — and there is only one robber — I can walk over the robber without issue" | design |
| 2 | "pigeons are also completely ineffective" | content |
| 3 | "running dog events etc — things that move disappear on screen; they should at least run offscreen before despawning" | art / correctness |
| 4 | "I like the running tutorial on day 3 but I don't know how to solve it yet — I died every time (is there enough telemetry to tell what happened?)" | balance / correctness |
| 5 | "we need more nerves let's try 5?" | balance |

---

## What the trace already said

The run left behind `run-…seed1775207372`, and it answers finding 4 completely without anybody
having to be asked twice.

**Day 3, first attempt.** The dog is sited, and 2.4 seconds later — its telegraph, exactly — the
day is over:

```
   8.3  ahead    charging_dog crosses 184px in front of her at (63,71)
   8.8  near     charging_dog (telegraph) at (59,75), 148px
   9.2  near     charging_dog (telegraph) at (60,74),  80px
   9.5  near     charging_dog (telegraph) at (60,72),  44px
   9.7  near     charging_dog (telegraph) at (60,71),  23px
  10.7  lost     lost_hard_fail after 10.7s | near: charging_dog 12px
```

Four `near` entries inside one telegraph, closing to **23px** — and the lethal radius is 26. So it
was standing inside its own kill radius, unable to fire, for the last 1.7 seconds of a phase whose
entire purpose is to be a warning. The moment the phase ended it killed her from a standing start.

`Tuning.validate_pursuit()` passed every line of itself the whole time, and that is the finding
underneath the finding: **the contract was stated in speeds and durations, and a pursuit is played
out in distances.** It bought 2.4 seconds of notice and never asked where the dog spends them. The
answer is that `EventDirector` sites what the day owes across her line 184px ahead — *which is where
she was already walking* — so the dog closed at 148px/s against her 92 and covered the gap in three
quarters of a second.

**Day 3, second attempt**, and this one is the other half:

```
   9.6  cue      the mark over her head: soon for 1.8s | charging_dog 148px
  10.8  lost     lost_crying after 10.8s | exc 100, in 37.2/s (crowd 6.5, events 16.7)
```

She read the cue and ran — `37.2 − 6.5 − 16.7 = 14.0`, which is `EXCITEMENT_FROM_RUNNING` exactly.
She gave the right answer and lost the day to the meter anyway, with the dog 87px behind her. A
chase that always runs its full `PURSUIT_TIME` prices the correct answer at forty points whether it
is given on the first frame or the last, which is a toll rather than a lesson.

**And what the trace could not say.** It has the dog being sited, four distances, and a death. Every
one of those is about the **world**; the question is about the **exchange** — how close it got,
whether she ran, and which of the two ways a chase can end it ended in. Reconstructing that from
four `near` lines and a separate `run` span is exactly the inference the format exists to make
unnecessary, and it is guesswork when the run span outlives the chase. Hence the `chase` entry.

**Finding 1, confirmed too.** Day 1 settles in calm block (3,5). Day 2 correctly rolls a spoiler for
it — `roll busker in the park she used yesterday, (3,5)` — and she settles in (3,5) again at 44.6s.
Day 3 rolls another one for the same block. The rule fired, three days running, and changed nothing.

---

## The analysis

### A. One busker cannot spoil a park (1)

M24 placed exactly one event in the calm block she used yesterday, and nobody did the arithmetic.
What denies calm ground is not *reaching* it — it is out-emitting the decay the calm multiplier has
already raised to 7.7/s. A busker is intensity 9 over a 190px reach, so his **useful** radius is
100px, in a lot that is 704px across. He denied about three percent of a four-block calm zone.

*"I can walk over the robber without issue"* is the same finding said from close up rather than a
regression of M34. A probe confirms the body works exactly as M34 says — she is stopped 25px from
his centre, which is 11px of man plus 14px of pram — but a busker at intensity 9 against a 7.7/s
decay nets **+1.3/s** at his own feet, and she needs 35 points to freeze. Being *right next to him*
is nearly free. The complaint is not that he has no body; it is that he has no effect.

Both halves are the same fix, and it is the one the player asked for twice — in playtest 07, *"it
should have multiple robbers so the entire area is dangerous or a full block party"*, and here,
*"there is only one robber"*. See docs/EVENTS.md, "It has to cover the ground, not stand in it".

### B. Nothing vanishes while you are looking at it (2, 3)

Findings 2 and 3 are one rule. The end of an event was `_finish()` wherever it happened to be
standing, and for the two shortest-lived rows in the game that is directly in front of her: the
cat's route is one street wide and its far end is comfortably inside a 640x360 view, and the flock
hangs in the air for a fraction of a second and is then deleted.

The pigeons had two more problems on top of that, and this is the third time they have been
reported. They were **over before she arrived** — sited two seconds of walking ahead, with a 0.9s
telegraph and a 2.4s burst — and they were **quiet and small**, 17 over a 110px reach in a game
where a café is 12 over 170.

### C. The nerve economy was set for a different game (5)

Three nerves is the number from M6, when a lost day also advanced the calendar: a nerve cost a day
of the fourteen *as well as* a life. M32 took that half away and left the number. Three attempts
against an act I that grew teeth in M31 is a run that can end on day 3 — which this one did, twice
on the same dog — and a run that ends before act II ends before the game has shown what it is.

---

## What was done

All five, as **M35**.

- **1** — the spoiler is a crowd, not a man. A grid over the calm ground, spaced by what each thing
  can actually deny, each cell rolling its own def so a spoiled park is a busker *and* a leaf blower
  *and* a market stall. Measured over five seeds and twenty lots, the share of calm ground she
  cannot settle on goes from **8–12% to 91%** of a one-block courtyard and **99%** of a four-block
  zone.
- **2, 3** — an event that is over **leaves**. It stops emitting, it cannot end the day, it carries
  no cue, and it moves until it is out of sight before it is deleted. The cat runs on, the flock
  climbs away, a dog that has lost interest trots off. The flock also sits on the pavement for its
  whole telegraph — which is a thing to walk around rather than a thing that happens — and is 20
  over 140px for three seconds, which moves it from +22.9 to **+34.9** in the cost table.
- **4** — the stand-off and the break-off; see docs/MECHANICS.md, "The stand-off, and what a
  contract in seconds cannot say". The dog holds `inner + speed × PURSUIT_REACTION` — 104px — for
  its whole telegraph, backing off if she walks into it, and it gives up as soon as she has opened
  `PURSUIT_BREAK_OFF` rather than running its clock out. It also came down from 148px/s to 130,
  which is *symmetric* (walking loses 38px a second, running gains 38), and from intensity 22 to 12,
  because it is lethal and does not also need to be the loudest thing in act I.
- **and the log can see a chase.** A `chase` entry per pursuit, written when it ends, carrying how
  close it got, how much of it she spent running, and whether it gave up or merely stopped.
- **5** — five nerves.

### Measured

The three answers to the dog, on a rig, plus the two that are new:

| she | outcome | cost |
| --- | --- | ---: |
| walks into it | caught 0.4s after the lunge | the day |
| walks away | caught 2.1s after the lunge | the day |
| runs the moment it appears | shakes it off in 1.5s | 21 points |
| runs when it reaches her | shakes it off in 1.7s | 24 points |
| dithers 2.4s, then runs | caught | the day |

| | before | after |
|---|---:|---:|
| calm ground denied, one-block lot | 12% | **91%** |
| calm ground denied, four-block zone | 8% | **99%** |
| things put in the park she used yesterday | 1 | 1–9, sized to the lot |
| `pigeon_flock`, walked through | +22.9 | +34.9 |
| events placed, day 1 | 40.0 | 40.0 |
| events placed, day 14 | 76.0 | 76.0 |

The density M28 set and M21 re-measured is untouched away from the spoiled lot, which is the number
that had to not move.

### Two things found by doing it, that the analysis did not predict

- **A rig that runs on a timer runs *into* the dog.** `--flee` took a timestamp at first, and three
  traces showed a lethal dog "arriving from nowhere" and killing a fleeing player. They were the rig
  sprinting at it: the director sites what it owes in front of the direction she is **actually
  travelling**, so starting the run before the dog is placed puts the dog in front of the run. It
  waits for the pursuit to start now, which is also the thing worth measuring.
- **Clamping the approach at zero is not a stand-off.** The first version stopped the dog closing
  past 104px and left it standing politely still while she walked the last 104px into it herself and
  died on the first lethal frame — the contract true of the dog and false of the encounter. It backs
  off now, which is also what a dog barking at a pram actually does.

### Not done

Nothing from this playtest. What is still open is playtest 07's list, unchanged: three act I events
sharing one `person.svg` (2), a café with no people at it (11), the cat crossing the wrong axis (1),
a four-block concrete plaza (8), a car turning with no diagonal (6), the warning indicators
rendering below roofs (4), and the zzz stepped aside from the pram (14).
