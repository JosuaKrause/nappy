# Playtest 36 — 2026-09-07

A session on M89's halo, given as notes in one conversation. **Three findings, and together they
are one change**: the halo currently answers *how much is landing on me* with its brightness and
answers nothing at all with its colour, and it should answer *how dangerous is this* with the
colour and *how close am I* with the brightness.

---

## 1. Cars get no halo, and neither does anything else in the crowd

> "cars don't get a halo even if they honk at me -- is that a similar reason like the one for the
> crowd?"

**Yes, the same reason exactly.** `CrowdAgent` is *"one person or one car"* — its own class doc —
and `ExcitementHalo.select_sources()` is handed `EventManager.instances()`, which is events. A car
is not an event, so it is never a candidate however loud it is.

**But a honking car is not like the ambient crowd, and that is what makes this more than the
tabled question.** `CrowdAgent._draw_horn_mark()` already draws a caret over it, in
`Palette.MARK_LETHAL`, when `_jolt > 0.0`. So the game already says *this is worth changing your
route for* about that car — and then the cue whose whole job is *this is what is charging you*
says nothing about the same object in the same frame. Two cues that disagree about what they are
about.

**The rule the player gave is the one that makes it statable:**

> "at the very least if something has a caret it needs a halo as well. we can discuss the details
> about general crowd floors later, though"

So: **a caret implies a halo.** The ambient crowd floor stays the open question it already is,
under "The crowd has no halo" in `TODO.md` — this settles only the objects the game has already
decided to mark.

## 2. The colour is the same for everything

> "right now a cat and a musician have the same color"

True: the halo draws `Palette.EXCITEMENT_FIELD` for every source and varies only its alpha. So the
cue distinguishes *which* object is charging her and says nothing about **how much it matters**,
which is the second half of what a player standing in a busy street needs.

## 3. Colour says how much it costs; brightness says how close it is

> "the color of the halo should be determined by the absolute magnitude with red being strong and
> light yellow being weak and the faseout should be by the fraction of its value ... the intensity
> of the halo states how far away I am. the color should state how dangerous it is"

Two axes, each answering one question, and neither currently doing so.

**The first attempt at reading "absolute magnitude" was the row's own `intensity`, and the player
rejected it before it was built.** Put to them as a fork — `cyclist` emits 18/s and ends your day
while `protest` emits 42/s and cannot hurt you, so on declared intensity the lethal biker glows
paler than the harmless protest — the answer was neither of the options offered:

> "magnitude of how much actually landed at the player -- track it over a time window -- then you
> have the real cost and the differences in numbers you mentioned above disappear"

**That is a better answer than the question, and it is worth saying why.** The cyclist-versus-
protest problem only exists for a number *declared on the row*. What has actually landed on her
is a fact about the encounter she just had: a protest she skirted the edge of delivered little, a
protest she walked through delivered a lot, and the same row is correctly a different colour on
those two days. It also means the halo is honestly about **the meter** — lethality is the caret's
job and the doubled red mark's, and this cue does not need to duplicate them.

**The window is five seconds** *(2026-09-07: "5s sounds good for now")*, chosen to be looked at
rather than derived: a `cat_dash` is a three-second interruption and a `busker` is continuous, so
the window has to be long enough that a brief scare can colour at all and short enough that a
source she has walked away from stops colouring promptly.
