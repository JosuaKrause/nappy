## M178 — A gate lets her out alive, and where she comes out · built 2026-09-20

*(2026-09-20, [PLAYTEST-116](../playtests/PLAYTEST-116.md): "the gate checks were placed in a way
that I would basically immediately die after crossing them"; "when I reappear I briefly spawn at
my old location before teleporting to the new location. I should directly spawn at the new
location"; "there should be a gap for events immediately surrounding the gates"; "since two gates
can be adjacent to each other their influence shouldn't add up"; "otherwise going into a hut at a
corder with two huts double counts the influence".)* One agent, five commits on
`feature/m178-gates-let-her-out-alive`, reviewed here. The run: taken in with the meter at 10,
let out two seconds later at 72 beside three roadblocks and a patrol, crying 0.4 seconds on.

**The hold charges its toll and nothing else.** Any point inside the trigger of a door whose
hold is running gets that hold's flat `CHAT_EXCITEMENT / detain_seconds` and nothing from any
other event or from the crowd (`EventManager.door_holding_her_at()`, read by both halves of
`City.excitement_sources_at()`). Asked of the *point*, not of "a hold is running": a
manager-wide flag was tried first and made the meter's query lie about every street in the city
for two seconds. Idle decay is already zero, so the hold is exactly 25. `chatting_mother` shares
the hold's path and is left as she was, keyed out by `redetains`: her conversation happens on
the sidewalk with both of them drawn, so what stands beside them is part of its price; a door is
the one place she goes in. Open to overturn.

**Events keep 176px clear of a door** (`Tuning.CHECKPOINT_EVENT_GAP`): the gate's 120px field
plus the 54px the release sets her down at, measured from every door body, with the candidate's
own reach added and taken to the nearest point of its whole route, so a mover's beat through the
gap is refused as well. Refused at placement by the scheduler and the director through one
function, never removed afterwards. Six seeds, days 7 and 11, the same days planned with and
without the rule: 367 placements inside the gap before and none after, 1936 placed before and
1922 after.

**The boundary's bodies charge as one source.** `EventDef.barrier_structure` is set on
`checkpoint_hut`, `checkpoint_gate`, `checkpoint_post` and `roadblock`; the event sum keeps the
strongest of them at a point and drops the rest, so what lands is attributed to that one and the
halo follows. The caret and the halo's rim are told which bodies are outranked, since they
promise a cost rather than read the sum. `roadblock` is included although it is the wall and not
a door, because the three bodies that killed her were the wall's and cannot be moved; two
scheduled roadblocks together therefore also read as one. The maximum is over all of them, not
per cluster. That a corner of two doors is one toll was already true of the release latch and is
now tested.

**The ground she is let out onto is a guarantee over seeds, not a runtime check — a fork taken
as the entry allowed.** A door cannot be refused or moved: it is a crossing the day's route tree
uses, and *a region edge may never affect a path* is the stronger rule, so refusing one walls a
street a route needs. The entry's alternative — the things that make it deadly are not placed
beside it — is what the gap and the single source are. The sweep walks out of every release
point on sampled days, both sides, five lanes, from the toll's level, at full peak on the worst
ground: the highest the meter reaches is 50 with the gap and 150 without, 106 of 1300 release
points over 100 without it. The run's own shape is a test: the patrol is refused, and the
barriers, which cannot be, are survivable as one source.

**She was drawn at the entry because two clocks shared the job.** The teleport was already
right. The instance showed her again from a drawn frame the moment its hold ran out, and the
manager moved her from the physics frame after it; every drawn frame between had her visible at
the place she went in. The release now moves her, shows her and hands the camera back on one
physics frame. The test drives the two clocks apart and fails with the old order put back. The
burst is `docs/evidence/m178-gates-let-her-out-alive-2026-09-20/`.

**Left to M176, the loose dog is past her before it is loud:** how much the one source emits.
