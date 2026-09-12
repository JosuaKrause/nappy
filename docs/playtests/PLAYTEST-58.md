# Playtest 58 — 2026-09-12

A note from the player on the checkpoint doors, given while the playtest 57 defects were being
merged, without a run folder: one finding, on the crowd at a region door.

## Walkers at a checkpoint

> walkers walk through checkpoints...

A region door is the one crossing the crowd's shut list carves out on purpose (M110, the crowd
goes round a seal): a car brakes and queues for the boom, and a walker passes the hut untouched,
straight through its footprint, while her own crossing is a two-second hold inside the hut. Asked
which rule walkers get — held at the hut like her, walking round it, or turning back like at a
wall — the player chose the hold:

> Held at the hut like her

And a moment later, the exception:

> a small fraction can do that

Then, on what the rest do and on the shape the hold makes on the pavement:

> others can turn back

> don't want a queue that is long

So a walker arriving at a door's hut is held for a short time and continues, a small fraction
walk through as they do today, some turn back the way they do at a wall, and the queue that forms
behind a held walker stays short. None of the fractions and none of the queue's length is a
number the player gave.

And the shape of the hold itself, as states:

> four states walking -> waiting -> inspection -> emerging on the other side (with cooldown to not
> go back again) -> walking

So a held walker waits its turn, goes inside for the inspection the way she does, comes out on
the far side of the door, and for a while after that cannot be taken by the same door again, so
it walks on rather than turning round into a second hold.

## Her own release, the same shape

On the fourth fault of playtest 57's inspection item — released on the far side without moving,
she was detained again — and the two answers that item had left open, putting her outside the
radius or not re-arming until she has left it:

> hmm, she just spawns further away now? it should work that she has a flag "just spawned" that
> only resets once she leaves the area. that way she can't accidentally go back and we don't need
> to place her far away

So the release puts her close, just clear of the hut, and a flag keeps that hut from taking her
again until she has once left its area. The walker's cooldown above is the same rule.

And the building's doors, which fade and teleport:

> same mechanism can be reused in the escape scene when going through doors

So a door in the escape scene gives her the same flag on arrival, reset only once she leaves that
door's area, rather than its own guard.

## Street trees

On the trunk body M106 gave a street tree, listed in `REVIEW.md` as *does the trunk catch her
where the pavement is narrow*:

> trees shouldn't have a hitbox at all. trees in parks don't why should the ones in the street be
> treated differently?

So a street tree has no body, like a park tree.

And on how many there are and where, reshaping M115, streets with trees, which playtest 57 asked
for as runs of three to five blocks:

> and we should place trees in the streets more sparingly as per my earlier comment. trees read
> like obstacles (they add noise) so it makes detecting actual obstacles harder. actually, I'm
> rethinking the placement strategy. trees should only be allowed to be placed if there is no
> other blocking event (or conversely due to map consistency) events can only be placed where no
> trees are (except for the fallen tree which must empty out one tree lot). so trees must be
> quite rare to be able to still place vans restaurants etc. also, trees make it harder to spot
> events like yeller, dog walker, etc. so we need to be careful about how many we are placing

So a tree and an event never share ground: since the trees are the city's and fixed for the run
while the events are the day's, the day's events are placed only where no tree stands, the
fallen tree being the one exception that takes a tree's own spot and empties it. And trees are
rare, both so the events still have room and so a tree never hides one.

## This round

> implement those this round

> also include this in this round

So the walkers' hold, the release flag, the building's doors and the tree body all go in this
round rather than into the queue.
