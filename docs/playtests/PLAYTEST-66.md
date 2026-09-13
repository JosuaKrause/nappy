# Playtest 66 — 2026-09-12

Day 1, seed 3265820891, invincible, on v0.8.2-870-g6ff43b3 (`main` after M109, the walking
sprites, with M117, M118 and the finale still on their branches). The run folder is copied whole
to [evidence/archive/session-captures/2026-09-12/run-205023-seed3265820891-v0.8.2-870-g6ff43b3/](../evidence/archive/session-captures/2026-09-12/run-205023-seed3265820891-v0.8.2-870-g6ff43b3/):
`run.log`, seven asked stills (`asked/001`–`007-attempt1-asked.png`) and twelve recorded bursts
(`asked/burst-<id>-001` through `-012`, 36 frames each with their `burst.json` timing). "Burst N"
below is the burst whose folder name ends in `-0NN`; "picture N" is `asked/00N-attempt1-asked.png`.

> '…/telemetry/2026-09-12/run-205023-seed3265820891-v0.8.2-870-g6ff43b3' contains a lot of
> insightful information.

## The crowd with nowhere to go

> pedestrians with nowhere to go (all four sides of the intersection are blocked off) should just
> despawn (or never spawn in the first place)
> right now they're accumulating in one place and move back and forth or worth flicker (burst 3,
> 4, 9, and quite a few others). the same with cars (burst 10 and 11).

Burst 3 (frame 17) is the mother at tile 59,87 on a road crossing, with café tables and street
trees around a junction; burst 5's north-west corner (tile 0,0) shows a pack of walkers stacked on
one crossing corner, bodies overlapping. Burst 10 (tile 159,1, the north-east corner) shows two
cars turned onto the pavement at the corner, one of them with its halo drawn beside the body. The
finding is the crowd's answer to a junction sealed on every side: walkers and cars keep being sent
into it, reach the seal, turn, reach the next seal, and stack up, and at the tightest spots the
picture flickers as they reverse. The player asks for those agents to leave the map rather than
pace, and for none to be spawned into a pocket they cannot leave. The entry is M119 in `TODO.md`.

Verdict on the `REVIEW.md` question *does the crowd ever look stuck against a seal*: yes, where
seals close every side of a junction. Whether a single sealed street reads as *shut* was not
reported on.

## The map edge

> at the eastern and western edge one column of tiles is missing leaving a black band (picture 1
> and 2).

Picture 2 (tile 159,159, the south-east corner) shows the grass band east of the city stopping
short of the window, with a black column beyond it; burst 10 at the north-east corner shows the
same black column. Picture 1 (tile 0,101, the western edge) is the matching still for the west.

> while people or cars cannot leave the map anymore from non-tunnel/bridge edge locations they
> can still spawn there and walk/drive out of nowhere (burst 8 and 9).

Burst 8 (tile 36,3, north edge) has a walker on the mountain band north of the pavement and
vans coming in from the top; burst 9 the same on the eastern side. `CITY.md` says a car leaves
the city by the bridge and the tunnel and nowhere else, and everybody else keeps a tile inside
the map; the player reports that the entry side of that rule is not held: agents are still placed
at the plain edge and walk or drive in out of the forest, the water or the rock. Both halves are
M120 in `TODO.md`.

## Turning cars

> the halo doesn't update when the drawn sprite updates. so a turning car will have the original
> halo while turning (burst 5 and 6 and a couple more). also while turning the car might get
> weirdly offset (burst 5 and 6).

Burst 10's north-east corner has it plainly: the blue car on the pavement is drawn in its
diagonal view while its halo is the side-view silhouette, sitting up and to the left of the body.
The halo traces whichever texture the owner drew when it was built, and a car that changes view
on the arc is not re-traced; and the body itself is drawn off its registration for part of the
turn.

> the halo issue is not specific to cars you can see the same for when you walk close to birds
> you will get a freeze frame of their position as halo while they keep flying

So the halo is stale for every owner whose body moves or changes while its glow is steady, not
for the crowd car alone: a flock's rim stays where the birds were when the glow settled while
the birds fly on.

> a car doing a u-turn into a lane with traffic reset the other lane (burst 1).

Burst 1 (tile 28,98) is the eastern side street with a queue of cars in the northbound lane and a
car about-facing into it; the player saw the lane it joined reset. All three are M121 in
`TODO.md`.

Verdict on the `REVIEW.md` questions about a car's turn: the picture jumps its halo and floats
off its registration on the arc; whether the pause at the mouth reads as slowing, and whether the
street about-face over the kerb reads as wrong, were not reported on.

## Shadows

> don't draw a shadow for water main breaks.

The burst water main is one of the three whole-scene seal pictures (with the fallen tree and the
car accident) and draws the body shadow every seal draws under its scene; the player wants none
under this one. The crater is on the ground, not above it.

> can we do a one tile diagonal shadow from all buildings? like the bottom right of a build has a
> shadow triangle 45 ne to sw with the top half filled. that shadow then goes all the way to 1
> tile left of the building and up to 1 tile before the building ends. buildings that are joined
> don't have an extra shadow where they connect. this should make alleys more obvious since they
> will have part of those shadows, too

Buildings draw no shadow today. The player asks for a one-tile cast shadow on every building,
with a 45° cut at the corner, drawn over the union of joined buildings rather than each one, so
that the ground of an alley carries part of it. Both are M122 in `TODO.md`, where the reading of
the geometry is spelled out with the one question it leaves open.

## Priority

This round is played on the same footing as playtest 63's: *"this round's feedbacks should all be
prioritized since I'm actively testing the changes as they come in."* The four entries go ahead of
the queue with M117 and M118.
