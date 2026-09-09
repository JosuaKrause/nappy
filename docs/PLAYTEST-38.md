# Playtest 38 — 2026-09-08

A session on the M92 halo, played on its branch before it merged, given as notes in one
conversation. Four findings: two are investigations — a cue that shows nothing for two rows that
cost something — and two are the cue's own language, the colour and the transparency, not yet
saying what the player needs them to.

---

## 1. Cats and birds have no halo

> "cats and birds have zero effect right now according to halos"

**What this side reads into it.** Both rows cost her: `cat_dash` is 17/s over 30/120px for 1.8s,
and a flock is its birds summed, +35 through the middle. Either the rim is not drawn for them at
all, or it is drawn so faint and so briefly that it reads as nothing. Two things to check rather
than guess: whether a `cat_dash` and a flock instance standing on her are selected and accumulate
`landed()` at all in a rig, and whether the brightness — the fraction of the source's own peak
reaching her, where the peak for a flock is measured at a centre that may lie between its birds —
comes out near zero for exactly these two shapes.

## 2. The chatting mother's capture radius is too small

> "the radius of the chatty lady for capturing must be larger"

**What this side reads into it.** `chatting_mother.detain_radius` is 33px, set by M75 so that
walking her far lane no longer avoids her (the lanes are 32px apart). The player wants it larger
still; no number was given. Not a halo finding — filed here because it came in the same breath.

## 3. Yellow means 1 and yellow means 20

> "the current color scheme doesn't work well. yellow can mean 1 and 20 which are very different. I
> think we can combine color with transparency and also fade in and fade out smoothly using
> transparency. right now it's always abrupt and yellow can mean anything."

**What this side reads into it.** Two separate defects in one sentence. **Magnitude has one
channel and it is not enough**: colour runs pale yellow to red over 0..40 points landed, and
brightness is only *how far into the field she stands*, so a source that has cost her 1 point and
one that has cost her 20 are the same yellow at the same brightness. The player's answer is to let
transparency carry magnitude too — faint for a point or two, solid for twenty — so the two
channels agree. **And the rim switches rather than fades**: it appears at full strength the frame a
source clears the floor and vanishes the frame it does not, and a burst's points leave the
five-second window all at once. The player wants both edges eased through transparency.

## 4. No fade from yellow to red beside the other mother

> "there is also no real fade from yellow to red (eg when standing next to the other baby lady."

**What this side reads into it.** A conversation with `chatting_mother` puts `CHAT_EXCITEMENT` (25
points) on the meter over `detain_seconds` (5s), which should carry her rim more than halfway to
red over the chat. Either the chat's rate is not being attributed to her — `current_intensity()`
answers the chat with a flat rate and `contribution_at()` should return it inside her field — or
the ramp's middle is not visibly orange. A rig can hold the first: after a full chat her `landed()`
is about 25. The second is a screenshot at the end of a chat.
