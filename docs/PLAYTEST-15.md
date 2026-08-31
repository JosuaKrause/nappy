# Playtest 15

Played on `feature/placed-by-role` at M50 step 2 — `8a02e9e`, seed `3584108623` — with the
placement-by-role work in the build but nothing from it visible yet. Reported in two bursts, the
first a single line off a telemetry map and the second a list sent mid-run with a screenshot
attached. The wording below is the player's, verbatim.

**The through-line is that the city is drawing things it does not mean.** A cul-de-sac is a wall
on the graph and nothing on the pavement; the spine has a zebra painted on it and a traffic light
above it, which are two contradictory promises about who gives way; a police car drives north
showing its flank; and a car reaches the bridge — the one place in the city that is *about* leaving
— and blinks out. Two of the seven are about the frame around the game rather than the game, and
one is a report the player is not sure about, which is recorded as exactly that.

The map finding is in **[PLAYTEST-14.md](PLAYTEST-14.md)**, finding 7, because it is a re-report of
that one and belongs with it rather than in a document of its own.

---

## 1. Cars and people go through cul-de-sacs

> "cars and people go through cul-de-sacs"

The dead ends M50 step 1 added are `absent_segments`, which every *route* search already takes
through `CityMap.blocked_segments()`. The crowd is the thing that walks and drives the lattice, and
this says it is not asking.

Worth being precise about what "through" can mean here, because the fix differs: a dead end is one
street with one end **built over**, so the tiles at that end are building and the rest of the
street is ordinary road and pavement. A car that drives *down* it and turns round is fine. A car
that drives *out of the end that no longer exists* is the bug, and so is one that never diverts
because the street it is aiming at is gone from the graph but not from its own view of the map.

## 2. The main road should not have zebra crossings

> "the main road shouldn't have zebra crossings (since they have traffic lights) it should be two
> dotted lines demarking the pedestrian safe zone"

Design **and** art, and the design half is the load-bearing one: a zebra means *traffic gives way
to you*, and on the spine it does not — what stops the traffic is the light (`M41`, and
`Tuning.validate_signals` is the contract). So the paint has been contradicting the rule at every
junction of the one street where getting it wrong ends the day.

The replacement is stated exactly: **two dotted lines** marking the pedestrian safe zone, not a
zebra, not nothing.

## 3. The police car is drawn side-on when it is driving north

> "the police car only has a sideview even when driving vertically"

## 4. The day counter may have reset mid-run

> "I can swear that the day counter just reset mid run when reaching the next act and then I was
> back at day one (maybe I died fully without noticing)"

**Recorded as reported, including the doubt.** The player's own alternative explanation — a run
that ended on the last nerve and started over — is the likely one, and it is *not* a reason to
close this: if a lost run restarts without the player noticing it has, that is finding 5's
complaint arriving from the other side and the two should be read together.

**Checked in the code, and the alternative is the only thing that fits.** `GameState.day` moves in
exactly two places: `finish_day` increments it on a win, and `start_run` sets it to 1. `start_run`
is reached only through `_restart_run`, which **reloads the scene**. So a counter reading 1 again
is a new run and there is no third path.

That is not the same as *nothing happened*. What it says is that the run ended and the ending was
unreadable — three screens deep, in the fiction's own voice (*"You stop going out."*), dismissed
with the same key as every other screen in the game. Finding 5 is the fix and this is the evidence
for it. Left half-open: reopen it if the counter is ever seen to move with nerves still on the HUD.

## 5. The game over screen has to say game over

> "can we make the game over screen more obvious and also the title screen. clearly say game over
> on the game over screen with big letters (in addition to everything else that is already there)"

Note **"in addition to everything else that is already there"**: the ending text, the reason and
the keys stay. This adds a heading, it does not replace a screen.

## 6. The title needs a different colour

> "on the title screen change up the color of the game title"

## 7. Cars on the bridge disappear instead of driving off

> "cars driving over the bridge currently just disappear. they should drive until they leave the
> visible area"

The bridge, the tunnel and the road out of the map are M41's edge of the world — the three holes in
the ring of frontages, and the whole point of them is that the city carries on past where she can
walk. A car that vanishes on one of them says the opposite.

This is *"nothing vanishes while you are looking at it"* — the M35 invariant, written for events —
arriving at the crowd, which has never had it. `Crowd` recycles a car when it leaves the corridor
box, and the box is smaller than the map.
