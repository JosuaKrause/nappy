# calm-pelican — A pursuer notices her and lunges only along a clear line; the route siting names its ground · 2026-10-10

## A pursuer neither notices nor lunges through a building

From the re-review of PR #552 (polite-rabbit, a pursuer catches her only by touching her): the
catch needed her touched, but the 140px notice range (`pursues_within`, the distance at which he
turns to face her) and the lunge still worked through buildings, so the alley robber noticed her
through a building and lunged across it, close to what the player described in #544: "He couldn't
reach me. But it was instant". The player, asked (inbox #648 in
[leafy-puffin](../playtests/2026-10-10-leafy-puffin.md)): "yes noticing needs a clear line"; and
of the lunge (inbox #650 in [mossy-beaver](../playtests/2026-10-10-mossy-beaver.md)): "how would
that even work? how can it pursue without noticing? obviously it needs a clear line".

**Built in PR #657** (`EventInstance._chase()`): a pursuer notices her only along a clear line, and
lunges only along one, both through `_clear_line_to()`, the test the catch already used. **A lunge
held back by a wall starts from the full stand-off**: once she is inside his stand-off with a wall
between them, or he first notices her already inside it (which only a wall can cause),
`_lunge_held` makes him behave as the door guard's row (`sets_off_beside_her`) does: he holds his
ground while she is nearer than the stand-off, follows at it once she is further, and lunges when
she is back at the full stand-off with the line clear, or chases when his notice (1.8s for the
robber) runs out with her outside it. **His notice does not run out while she is inside the
stand-off** (`_notice_paused_for`, left out of `chase_age()`), so the chase starts from the full
stand-off however she came. Deferring the lunge alone would be the events skill's trap: at an alley
mouth the line clears with her 43px to 106px into his 116px stand-off, and the review of PR #657
measured catches 0.02s to 0.58s after a chase that set off from there, under the 0.6s
`PURSUIT_REACTION` a pursuit owes her. The day-3 charging dog and the heated rows go through the
same code; the door guard is unchanged.

**Noticing is also what is drawn**: the waiting robber faces her only along a clear line
(`_robber_waiting_heading()`), and keeps the facing he was sited with otherwise, so he does not
visibly track her round a corner (`docs/GRAPHICS.md`'s robber row).

*Chosen where the design was silent, open to overturn:* a held pursuer she stays beside never sets
off: he stands turned toward her with the doubled red caret up and his field charging her meter for
as long as she stays inside his stand-off, and walking away gets his lunge from the full stand-off;
the notice clock runs while she is outside the stand-off and out of his line, so if it ends then he
chases round the wall from at least the stand-off; the alley mouse still notices through walls,
since it waits and runs its own path rather than chasing, and the answer was about pursuers; the
held state is not kept across a stream-out, which happens only far from her.

**The caret projects the catch.** `will_be_lethal()` (whether the doubled red caret shows) measures
against `def.lethal_reach()` rather than `def.inner_radius`, and its comment says it projects the
straight-line reach without the clear-line test. The one row whose caret changed is the hunting
roadblock's heated copy, from 86px to 28px, its catch; it is the only row with a `lethal_radius`.

Tests in `tests/test_events_pursuit.gd`: the robber does not notice her through a wall and does not
lunge through one (5 failing checks on the old code, among them a lunge "from his full stand-off
(36.0px of 116.0px)"), the caret measured from the catch, and the alley-mouth walk rewritten to the
new contract (the notice along a clear line, the chase from about the stand-off, at least
`PURSUIT_REACTION` for her to react, no catch through the corner), a held lunge that never sets off
inside the stand-off with the robber 20px to 90px into the alley, and a held pursuer she stays
beside who never sets off; the last two fail 16 checks on the code before the pause. The stills of
the same moment 1.75s in, before and after, are in
[pursuers-walls-2026-10-10](../evidence/pursuers-walls-2026-10-10/README.md).

**The events skill was wrong and is fixed in the same PR**: its pursuit trap said "Only the catch
asks for a clear line"; it now says the notice, the lunge and the catch all do, and that a held
lunge holds the door guard's ground until she is back at the full stand-off. `docs/MECHANICS.md`'s
"Running that matters", which said "Its lunge does not ask", says the same.

## The route siting says it offers a row's own ground

Found answering the player in mossy-beaver, who asked "why?" of an answer saying a man shouting
needs "a building face on the stretch of the day's route ahead of her". He does not: the siting
offers every tile of the row's own ground pool on the route's cells ahead of her; it is a building
face only for day 3's fire and the poster crews. Built in PR #657, wording only: `ahead_of()`'s doc
and both `_waited()` log reasons, the `_best_of()` and `_ground_as_a_set()` docs, the director's top
comment, `ON_HER_WAY_LOOK`'s refusal, `site_what_is_on_her_way()`'s doc and refusal paragraph, the
`sited_on_her_way` comment and `docs/EVENTS.md`'s set-piece row and on-her-way paragraphs say "a
tile of the row's own ground", and `_faces_on()` is `_its_ground_on()`. So a place marble is
unplaceable when she is off the day's routes, or when the branch ahead has no tile of the row's
ground past the streaming band that passes the placement rules, which happens near a branch's end,
close to home.
