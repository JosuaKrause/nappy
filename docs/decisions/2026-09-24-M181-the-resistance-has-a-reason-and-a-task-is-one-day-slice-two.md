## M181 — The resistance has a reason, and a task is one day: slice two · built 2026-09-24

*([PLAYTEST-117](../playtests/PLAYTEST-117.md) to [PLAYTEST-122](../playtests/PLAYTEST-122.md); the
calendar and every decision are in the TODO entry as it stood and in slice one's record.)*

**Day 10, warn the neighbor.** The neighbor spawns about 55 s of their own walk from her door, off
screen, and walks home with the red arrow on them. Reaching them first, they run; if they reach
the door first, the task is lost and they are taken. Whether they were taken is read from the
completed steps rather than saved, so a lost day gives it back; the day 12 wanted notice shows
the crossed-out face when they were. **The raid** is two quiet vans on the far sidewalk and a patrol
car pacing the street, arriving once she is 420px from her door and never on screen, with her own
sidewalk to the door open; passing the vans with the baby asleep costs about nothing. The patrol
car and the walking neighbor were catalogue copies that had dropped their `shape`, a script error
every frame they were drawn; fixed.

**The neighbor from day 1**: a figure in work clothes leaving her building each morning on days
1 to 9, pointed at by nothing, gone from day 11 (art in the PR, the same figure as the notice).

**Day 11, silence a mast.** Reaching its foot silences it for the rest of the run and leaves a
scar. Day 11's `silence_mast()` and the blackout's `silence_all_masts()` share one flag on the
mast's plan, `silenced`, so a mast silenced first stays silent through the blackout. The redraw
gate did not include a mast's broadcast cycle or its silenced state, so a silenced mast kept its
arcs and a live one's lamp did not cycle — a bug also on `main`, fixed here with a test.

**The once-only happenings.** Day 11: a commercial block ahead of her on the route she is walking,
out of sight, is boarded up and its market stalls taken away; with nothing on her way by 90 s, the
nearest unseen one goes instead (7 of 40 cities have no such block, lose no market, and the run
log says so). Day 12: once she reaches the swing the park is requisitioned, its grass turning to
mud a ring at a time from the edges over 12 s; mud is walkable, so she is never shut in. Day 13: a
column of three army trucks down one lane of the main road, far enough up it that their warning is
over before their noise reaches her; the rear truck leaves a permanent barricade where it stops,
out of her sight and only where home and a calm area stay reachable. It triggers within 480px of
the main road after 18 s of walking, otherwise at 100 s. `military_convoy`'s `first_day` is 13;
`COSTS.md` does not change.

**Day 12's park is forced open.** Each city picks one park for the swing by the seed's hash, so no
other generation step moves; it prefers a park already due to be requisitioned, and otherwise
gives it a requisition only reaching the swing triggers (`BlockCause.TAKEN`). On day 12 that park
is open whatever its state, the swing task points only there, and the day keeps a second clean
calm area reachable. The generator refuses a city with no park, so seeds 777, 228514, 260190 and
378975 of the 40 probe seeds now give the next seed's city.

**The marks, day 14.** Days 8 and 13 say what PLAYTEST-122 agreed; day 10's and 11's lines are
shortened to fit the on-screen line. Day 14's task is the power station's front door by the red
arrow, and touching it sets `GameState.sabotage_done`; the blackout follows from M183. Also fixed,
also on `main`: the red arrow stayed on a one-place task after she reached it; and the walk timer
days 11 and 13 wait on reads her velocity, as day 3's fire does, since counting frames undercounted.

**Open to overturn** (the agent's choices where the design was silent): the 55 s walk home; the
raid's layout; the neighbor never getting a guard; a skipped day 10 counting as taken; the market
read as a block due to be boarded plus its stalls, with the 90 s fallback; the park closing as mud
rings over 12 s; the column's size and trigger; the swing park by the seed's hash; the "second open
park" read as any clean calm area. Outside the brief's fence, and small: `BlockCause.TAKEN` in
`src/game_enums.gd`, the two mast lines in `EventInstance._picture_key()`, and the generator's
no-park refusal. **Left open and queued:** the sealed door's picture (M181); day 8's mark line
running off the HUD (M100); the answers M182 still owes.
