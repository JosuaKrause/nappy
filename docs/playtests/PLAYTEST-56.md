# Playtest 56 — 2026-09-11

A design conversation rather than a played session, held while M108, eight-direction entity
graphics, and M111, cars follow their turns, were being built in parallel. No run, no seed.

## The crowd walkers do not walk

Asked whether the crowd walkers have a walking animation, the answer was no: a crowd walker is one
static picture per facing that slides along its lane, with no gait frame pair and no bob — the
crowd agent's own comment says *"the crowd never bobs — only an `EventInstance` rides a stride's
worth of lift"* — while the mother alternates two frames per view, mid-stride and feet passing,
driven by her walk phase.

> can we do a similar one to what the player does?

So the crowd walkers get the mother's stride: a second gait frame per view, authored as SVG first
under the SVG-first rule, and the same alternation the stroller already runs.

On whether the art is a large job:

> the art should be easy to adapt, right? using the player as reference?

It is. The mother's b frame differs from her a frame only in the two leg and shoe paths, redrawn
with the feet passing, and a one-pixel lift of the whole figure for the bob; the walker's trim
layer already carries its legs and shoes as the same two paths in the same style, so a walker b
frame is those two paths redrawn and the coat body unchanged.

## Every living thing moves when it moves

> also, all living things should have movement animation

This widens the instruction from the crowd walkers to every living thing the game draws: the
event people, the animals and the cyclist as well. Read as *while moving* — a thing that stands
still keeps its single frame, so the busker, the café sitters and a posted guard are unchanged
until they move — and the pigeons already alternate two wing phases, which is a movement
animation. The first draft of this listed the yeller among the standing ones and the player
caught it:

> the yeller walks around, too, no?

He does — `homeless_yeller` paces eight tiles of pavement, walking up and down for ever — so he
strides like the rest. Filed under M108, eight-direction entity graphics, as one item after the walker
binding, walkers first because their art derives from the mother's, then the event people and the
animals, each needing its own second frame for every view before any code. Reading *movement* as
*while moving* is the orchestrator's, open to overturn if an idle animation was meant too.

Partly overturned the same day, for the café sitters:

> cafe sitters should have an idle animation, too. what's a busker? I'm not english

So a seated figure that never moves still animates: a second seated frame, alternated slowly on a
timer. The busker — a street musician playing for coins, here the man with the guitar and the
open case in a park or square — was then given his own:

> busker should have a two frame animation strumming the guitar

A standing guard stays single-frame until the player says otherwise.

## New names in American English

The "I'm not english" above was read as a question about a word; it was an instruction:

> I'm not english means -- use american words for new things

> existing names are fine

So anything new — an event, an asset, an identifier, a doc noun — takes the American word, and
nothing already named is renamed. Recorded as a rule in `CLAUDE.md` under "Names are content,
never identifiers".

## Cars bob on their wheels

> cars could bop up and down while the wheels stay in the same place

A moving car's body rises and falls a pixel while its wheels stay put on the ground. Today a crowd
car is two layers, a tintable paint body and one trim layer holding windows, tyres and lights
together, so the wheels cannot stay still while the trim moves; the wheels come out into a layer
of their own, SVG first. Filed under M108 beside the stride item, crowd cars first and the event
vehicles that move the same way.

Confirmed when the split was proposed:

> yeah we can extract the wheels and make them separate svgs

## An invincible mode for playtesting

> can you add an invincible mode for playtesting? that way I can check off basically all items in
> one go

> and it let's me inspect things more thoroughly

Asked after `docs/REVIEW.md` was named as the file that keeps what a person still has to look at.
The list is long and a day is three minutes that one car or one crying baby ends, so a mode in
which nothing ends the day lets one sitting walk past every item and stand next to any of them
for as long as looking takes. Filed under M100, small, real and nobody's, as a debug flag on the
same terms as the rest of the developer furniture: never in a release build, marked on screen and
in the run log so no capture from it can be mistaken for a real run.

## The mid-turn capture is a burst

Two branches had failed to photograph a crowd car mid-turn with a single windowed screenshot — a
turn is two seconds, and a still lands on it by luck — and the queue had proposed a probe that
places a car on a synthetic arc. The player chose the instrument that already exists:

> use burst mode for mid turn capture

So the evidence is an animation burst — `B` in a debug run, or `--press snapshot_burst <seconds>`
from a rig, thirty-six frames over three seconds at a junction — converted with `tools/clip.sh`
and kept with its frames and timing record, as the session-captures rule already requires for
anything about motion. A still cannot establish a smooth turn; the burst can.
