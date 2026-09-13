# Playtest 69 — 2026-09-13

A test run of v0.10.0 on the desktop, played with the frame readout on, right after the release.

## It looks good

> okay I did a test run looks good.

The round that shipped — the events' redraw gate and the chunked shadows, the first press no
longer walking her, the readout — passed a play without a complaint.

## People still come out from outside the map

> one thing I noticed is people still come out from outside the map

A re-report. [PLAYTEST-66](PLAYTEST-66.md) asked for this — *"while people or cars cannot
leave the map anymore from non-tunnel/bridge edge locations they can still spawn there and
walk/drive out of nowhere"* — and M120 answered it (`DECISIONS.md`, M120, the map edge): a
recycled walker or off-spine car is given no room past the true edge at all, so its entry roll
never leaves the map, and only a spine car keeps its room through the tunnel or off the bridge.
On v0.10.0 walkers are still seen coming in from beyond the edge. Filed as a defect under M100
in `TODO.md`, with the suspect the code shows: beside a plain edge the entry band collapses to a
single point on the boundary line itself, and a walker whose centre is on that line has half its
picture outside the map and walks inward from it — which is *coming out from outside*, whatever
the centre's coordinate says. The `REVIEW.md` item that asked about the edge closes on this.

## The social card unfurls

> this is how the social media preview looks like on whatsapp

A screenshot, `evidence/playtest-69-social-card-whatsapp-2026-09-13.jpeg`: the card on a white
ground with the stroller icon, the wordmark, the tagline *"Fourteen days. One pram. Get her to
sleep and get her home."*, then the title and description under it. The unfurl that failed
black before M80's flattening (`DECISIONS.md`, M80) now comes back whole in a chat client; the
`REVIEW.md` item that waited on exactly this closes.

## The busker's loop, refined twice

While M128 was being built. Shown that the agent had pulled the busker's reach from 190px to
55px, so that most of a one-block park with a busker in it became a place to sleep:

> keep the radius the same but tweak the excitement number. the excitement inside the park
> doesn't need to go up by a lot it just needs to be enough to not go down

Then, asked what the loop should do:

> can we make the pulse so a full loop leaves a net sleep decrease / excitement increase but at
> the quieter parts the sleep meter might fill up in the park. so it doesn't continuously
> decrease the sleep but rather let the sleep go up a but and then go down again in equal
> parts. that way we can push the number down even further

And, shown the arithmetic — the pulse averages 62.5% of its peak over a loop, the park gives
back 12 points a second, so at a peak of 13 a full loop at his core already nets sleep gain and
a net excitement gain with the quiet half kept needs a peak near 20, not lower:

> can we do a net sleep gain that is slow enough to never reach 100% in the alotted time?

So the busker's radii stay at 45 and 190px and the pulse stays; over a loop the meter drifts
toward sleep, the quiet half filling and the loud half taking it back, and the peak is the
lowest at which standing at his core from arrival cannot fill the sleep meter inside a day.
Built under M128 (`DECISIONS.md`, M128).

## A path through the city never has to cost

> also framing from a different point of view a path through the city must never hit
> excitement -- so all obstacles should be routable around by eg crossing to the other side of
> the street which in turn means the other side of the street must be open enough so we can
> walk on it unimpeded. a yeller must loop in a way that the desired path has an opening where
> the yeller is not present for example. also, the routing should only cross the street at
> intersections. in block crossings are possible in game but shouldn't be counted on by the
> routing algorithm

A guarantee the day does not make today. What exists (`DECISIONS.md`, M64, M69, M99): the
day's routes are grown on cells and checked for *reachability* — every closure and every
obstructing body is accepted only if the home still reaches two calm areas — and each event
pays a telegraph contract of its own; nothing asks whether a route can be walked at no cost.
The player's framing is a *cost* guarantee on the corridor: for every costly thing standing on
a route's pavement there is a line past it on the other pavement, that pavement is itself clear
for the stretch, the crossings the line relies on are at intersections and never mid-block, and
a pacing row leaves the line open for part of its beat. M129 in `TODO.md`.

## An eastbound car sits south of its halo, confirmed

> just confirmed on current mobile a car going west to east that is offset by a few pixel south
> and the halo is at the regular position

The sighting M123 asked for (`DECISIONS.md`, M123: *"a report on v0.9.1 or later reopens it as
a new entry"*), on v0.10.0 on the phone. What is different from the first report: it is the
*car's picture* that sits a few pixels south, and the halo that sits where the car is expected.
M121 registered every car view to the strike box's southernmost point, which moved east- and
west-bound pictures 14px south on purpose (`DECISIONS.md`, M121) and left it *"open to the
player's eye"*; the halo re-traces the body every frame, so the two should have moved together
and did not. M130 in `TODO.md`.
## Pigeons pop in on screen

> pigeons pop in on screen -- they should exist before they are visible.

The flock is an `AHEAD_OF_PLAYER` row, so it is created only when it is due and sited
`Tuning.AHEAD_LEAD_DISTANCE` (184px) ahead of her along her heading — inside the 640x360 view
on every heading, by design: that distance is the cat's two-second reaction window between
seeing it crouch and reaching where it bolts. Playtest 19 said the same of cyclists and dogs
(*"pop in in front of the player instead of starting off screen"*), and those were moved off
screen because they come *at* her; the cat and the flock cross her line and kept the on-screen
lead. For a flock that is the wrong answer: birds appear from nothing on a pavement she was
already looking at. M131 in `TODO.md`.

## Day 5: who gets the note

> I have no clue how to find the person on day 5 I need to pass the note to

What the game does (`docs/NARRATIVE.md`, the subquest; `ResistanceSteps`): day 4's chalk mark,
in an alley behind a robber, says on the summary of the day it was touched — the *won* day's
summary only — *"Give it to the one who won't stop shouting. Any of them might be him."* From
day 5 the header reads *somewhere out there: a note for a stranger*, and the contact rides on
one of the several `homeless_yeller` rows live that day: the pacing man shouting on a sidewalk
or a square. He looks exactly like the others by design — *"a wrong candidate costs full price
and returns nothing"* — and walking into his reach is the touch. Nothing on screen marks him,
which is the standing decision (`CLAUDE.md`, no quest log or marker for the resistance; *the
first encounter comes with no hint at all, after that the resistance speaks*). Whether the
mark's sentence was seen at all is the M100 open design question about a chalk touch that
shows nothing on a lost day; this report is its second sighting.

Asked which of the two it was:

> I touched the mark on day 4 died then went to the same alley again and the mark was gone.
> but then I still progressed to hand the note on day 5. the day text needs to be bigger to be
> able to be noticed and it should show also when dying so if missed on the first try it can
> be seen on the second try. the in game note should contain the same amount of info on what
> to do. note for a stranger contains less information than won't stop shouting which can be
> easily missed when progressing to the next day. also, we cannot expect the player to do an
> exhaustive check that will not work there is not enough time and the baby needs to fall
> asleep still as well. so if the solution is the yeller it's always the first yeller you come
> close enough to hand the note. let's record this for now and then stop until the next session

So it was the lost day: the touch survived the nerve, the mark was gone on the retry as built,
and the sentence that says what to do was never shown. Four instructions, all M132 in
`TODO.md`: the day brief is drawn big enough to be noticed; it shows on a lost day's summary
too, so a first try that dies still hands over the words on the second; the header line during
the day carries the same information the brief did, not a shorter title; and the contact is
the first yeller she reaches, never a search — *asked for a hidden contact among look-alikes ·
overturned on 2026-09-13*, because a day has no time for an exhaustive check with a baby still
to settle. Recorded and stopped there, at the player's word.

## The busker's numbers

> the busker numbers look good.

On the table showing a peak of 19.3 never fills the sleep meter at his core while anything
under 19.2 fills it within 35 seconds, and that the street beside the lot is half again louder
for it. Accepted as built (`DECISIONS.md`, M128).

## The readout on the live page

> how do I get a readout on the live version?

There is no way: the page is a release export and every developer flag, the readout included,
answers only in a debug build (`DECISIONS.md`, M76, a release carries no modifiers). Offered a
debug build served over HTTPS on the local network, or a query flag:

> let's add a ?debug=1 flag

Asked which shape, since one flag that unlocks everything would overturn the 2026-09-06
decision: **readout only**, a third bounded exception beside `?svg=1` and `?telemetry=1`. Then:

> with a note on the screen that this is debug mode -- the note should not be removable

Not built this session at the player's word (*"don't start implementing yet"*); M133 in
`TODO.md`.
