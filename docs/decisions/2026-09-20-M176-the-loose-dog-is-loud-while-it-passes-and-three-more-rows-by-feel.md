## M176 — The loose dog is loud while it passes, and three more rows by feel · built 2026-09-20

*(2026-09-20, [PLAYTEST-116](../playtests/PLAYTEST-116.md): "unleashed dog still has too little
influence -- needs to be more intense", "but keep things in relation to each other", "also
protesters have very little excitement?", "should be a bit more", "guard posts should emit less
excitement by themselves, too", "since there can be other obstacles around", "birds are also
very late to start. they shouldn't prematurely start but they should basically start fluttering
when I touch them not after".)* One agent, seven commits on `feature/m176-rows-by-feel`,
reviewed here.

**The cost table's pass was wrong for a row sited in front of her, and that was the dog's whole
problem.** `M174Pass` started its clock after the telegraph, right for a row placed at dawn and
wrong for a `TOWARD_PLAYER` row, which is created when it is owed and covers its approach at
`Tuning.TELEGRAPH_INTENSITY_FRACTION` (0.15). Measured as it is met, `loose_dog`'s pass was −2.9
awake, not +15.0: walking past it let the bar recover, which is what the run's `(telegraph)`
entries down to 20px were saying. `cyclist` moved for the same reason, 5.7 to 3.4. Where such a
row is sited now lives on `EventDef`, so the measurement and the director cannot disagree.

**The dog is sited further out, 225px to 739px**, so its 2.25 second telegraph ends before its
190px forward reach touches her (`Tuning.outlasting_telegraph_lead()` takes an arrival margin:
nothing for a `hard_fail` row, whose arrival is touching her, and the row's own reach for a loud
one). A pass nets 24.2 awake and 9.9 asleep at 0px, 16.4 to 24.2 depending on where its bark
falls. Rejected: more intensity, since 39 is the ceiling above which running past it is cheaper
than walking; a shorter telegraph, which cannot work at any length when the field is on her
0.16 seconds after the row exists; ramping the damping with proximity, which changes what a
telegraph means for every row. Order on the pass: fire truck 31.6, convoy 29.8, protest 26.0,
loose dog 24.2, dog walker 16.1, the man shouting 11.1.

**The pigeons' telegraph was a wait, not a warning**: the flock stays grounded through it, so
its 1.7 seconds were the delay between her walking in and the birds reacting. It now ends the
moment she is within the flock's spread plus her own body (76px), through the flag a pursuer's
lunge uses; a flock she never reaches still goes up on the clock, and `validate_event()` is not
weakened. **Its intensity stays 42, by the player's word, after a detour.** The flush made the birds loud
while she is among them, and walking dead through a flock went from +10 to +45 (real birds, in
the tree; the agent's first figures, +33 and +65, came from a rig that measured the modelled
ring and are wrong). The orchestrator read that as a cost nobody had asked to change and had
the intensity cut to 34.5 in review; the player, the same hour: *"no keep the pigeon cost … they
fly away. the strategy is to wait them out at no cost"* and *"not following the procedure should
be costly"*. So 42 stands, the test keeps only its lower bound (a flock costs more than a loose
dog's pass), and the upper bound the orchestrator invented, under half the meter, is gone.
Skirting at 80px is recovery.

**The protest is 19.5 a second, from 15**: +6.2 beside it awake where the decay had left +3.4,
23 points to reach its middle from its edge, a walk-through cost of 46.4 against the wall line
at 48. 19.9 is the ceiling: past it the scheduler makes it a wall and places none on a route,
while a resistance task sends her to stand in one; a test holds the role.

**The guard posts**: `roadblock` 13 to 9, `checkpoint_hut` and `checkpoint_post` 6 to 4, read as
the player's "guard posts" by the orchestrator and open to overturn. The line they were chosen
against is now a test: one barrier's rate over one hold stays under the hold's own toll. A test
in the checkpoint suite that required the roadblock to be louder per second than the toll was
restated as what it needs, a leak many times its tolerance.

**Evidence:** `docs/evidence/m176-loose-dog-loud-2026-09-20/`, a burst in which no `near` entry
for the dog reads `(telegraph)`.
