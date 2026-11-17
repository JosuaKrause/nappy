priority: now

# downy-llama — The roadblock covers its own sidewalk and the road, and leaves the far sidewalk whole · filed 2026-11-16

**The ask.** Shown that a roadblock's concrete band covers its own sidewalk and the whole road and
leaves about 52 of the far sidewalk's 64px open, and asked whether, by their rule that a street is
open where more than half of it is one contiguous opening, a roadblock should stand on her routes'
streets at all, the player answered: "okay let's use the one sidewalk has to be open and match the
roadblocks size to one sidewalk + road" (inbox #1465 in spry-plover, the question
`roadblock-opening`; the question as shown is in the playtest).

**Read as** (the orchestrator's): the one-sidewalk rule stands, so a roadblock on her routes' streets
must leave one sidewalk open, and the roadblock's band is resized to cover exactly its own sidewalk
and the road, 128px of the 192px street, leaving the far sidewalk whole, 64px, where today it
leaves about 52px of it and about 20px of its own sidewalk.

**What the note asked that is already built.** The note's first words, "if one sidewalk is blocked
then the other sidewalk cannot draw a block again", corrected by the player to "what I said was *if*
a street needs to have one sidewalk walkable *then* the placement of the drawn events needs to make
sure of that" (inbox #1465 in spry-plover), are built: pull request #1476 added the one-sidewalk
rule (`OneSidewalkOpenRule`), which refuses a body drawn where it would leave neither sidewalk of a
street of her routes walkable from one junction to the other, a roadblock included and read at its
band at every heat. It is part of polite-tapir's placement step 2 (the refactor's design review,
`docs/todo/2026-11-11-polite-tapir/placement-by-construction.md`), whose record is written when that
step closes; `docs/CITY.md` states the rule. **Read as** (the orchestrator's, with the correction):
the note makes no street newly required to keep a sidewalk walkable, so nothing is filed for the
streets beside her routes or off them, which keep PLAYTEST-17's blocking events all over.

**The player's other words on the note.** "what is a heated roadblock?" asked what the board's
shorthand meant (from heat 4, after four resistance tasks, the checkpoint guard leaves his post and
runs at her). "are the roadblocks predominantly on one side of the street? if more than half the
street is open in a contiguous opening it counts as open even if the player has to bait the guard
away" (inbox #1465 in spry-plover). **Read as:** the hunting guard's reach does not close a street by
itself; the band decides it. The answer to `roadblock-opening` above settles which rule is used.

**Open: what this does to M199, the roadblock closes its whole street.** M199 is an open entry in the
`now` band that asks for the opposite on the far sidewalk: "close the street fully" (PLAYTEST-135 7),
its item `band-is-centred-on-its-street.md` a band centred on its street spanning all 192px. The
answer here sizes every roadblock at one sidewalk and the road, and the earlier "roadblocks currently
are impossible to get past. one sidewalk must be open if they're en-route" (inbox #747 in
woolly-penguin) already kept a sidewalk open on her routes. Whether M199 is dropped, or holds for
the roadblocks off her routes, is the player's to say on the board; the filer does not close it.
The rest of M199 is untouched by this: a roadblock on a carriageway and where its guards stand.

*Proposed, not asked for:* the band `now`, the filer's, since the player asked for it to be built;
the item's way of building it is the builder's design, reported in its pull request.
