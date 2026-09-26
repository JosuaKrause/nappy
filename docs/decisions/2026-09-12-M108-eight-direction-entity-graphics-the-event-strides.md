## M108 — Eight-direction entity graphics · the event strides, built 2026-09-12

*(2026-09-11, playtest 56: "all living things should have movement animation"; "cafe sitters
should have an idle animation, too"; "busker should have a two frame animation strumming the
guitar".)* The event half of the stride item, after the walkers' half. Five agent commits on
`feature/event-strides`, reviewed here against the sheets. **Art first, as SVG**: seventy `_b`
files under `assets/events/`, one beside every a-frame source of fourteen families — the dog
walker's person and his dog (shared with the loose dog), the chatting mother walking, the yeller,
the lunging robber, the plain protester rank, the leaf blower, the van victim, the running cat,
the charging dog, the mouse, the cyclist, the café sitter and the busker — each on the a frame's
own canvas and feet anchor, following the walker rule: the b frame moves only the legs and shoes,
the coat, head and held thing hold still, cardinal and side views lifting the body a pixel the
way the mother's do and the diagonals leaving it untouched. The animals get legs only, since the
bob already carries their vertical motion; the cyclist's b frame swaps the two pedals; the mouse
has no leg to cross at its size, so its tail curls instead. The sheets,
`docs/evidence/m108-event-strides-2026-09-12/event-strides-{native,3x}.png`, rendered by
`tests/probes/m108_event_strides_sheet.gd` from the sources before binding, were reviewed for
drift above the waist and found none.

**The alternation** is the walker's, one phase per instance advanced by ground actually covered
at `GAIT_RATE` (0.09 per px, the mother's rate pinned as a literal), frame b while moving and the
doubled phase's sine is positive, frame a at rest and whenever the instance stops — a queue, a
give-way, a chatting mother, a waiting robber — and reset in `setup()` and `resume()` so a stride
never starts mid-cycle; `_draw_eight_view()` takes a second table and one lookup picks the frame
for actor and held thing together, so the walker and his dog can never disagree. The van victim
derives her stride from her scripted walk's own age and constant speed rather than a persistent
phase, since nothing resets between takes otherwise. The protester rank and the leaf blower are
wired and never reach frame b, because those rows never move; the talking mother stays on her one
picture, since chatting freezes her. **The sitters and the busker never move**, so they alternate
on the instance clock: `SITTER_IDLE_PERIOD` (3.4s) and `BUSKER_STRUM_PERIOD` (0.5s), each offset
by a hash of the instance's siting so a row of sitters does not lean in unison and nothing draws
from an RNG on stream-in. The distance-driven bob stays on every family as it was. **Chosen where
the design was silent**: the two periods; the shift magnitudes, matched to the mother's in kind
rather than value; the mouse's tail. **Tests**: `tests/test_event_strides.gd` — a b texture for
every a texture and the two differ, a moving instance alternates and a stopped one holds frame a,
the sitters and busker alternate on time without moving, the halo canvas draws the body's own
frame, SVG fallback resolves with no PNG present. **Evidence of motion is a burst**: the run
folder under the same evidence path, a dog walker beside her from frame one; frames 18 to 23
show the walker and his dog flip together at 1.76s and hold, and the README says the flip back
was not caught inside the run. Whether the strides read at street scale is in `REVIEW.md`.
