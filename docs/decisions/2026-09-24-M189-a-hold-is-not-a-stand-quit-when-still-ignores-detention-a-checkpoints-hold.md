## M189, a hold is not a stand — quit-when-still ignores detention, a checkpoint's hold and a red light · built 2026-09-24

*([PLAYTEST-127](../playtests/PLAYTEST-127.md): "a guard house triggers the stand still flag -- it
shouldn't", generalised to "in general is_detained shouldn't trigger it -- same with stroller
lady", and extended to "yes also red light (a human player would like pace back and forth with a
red light to minimize excitement)".)* Follows M189, a still mother ends the run with a picture:
while she is held, `--quit-when-still`'s watch no longer counts the hold as standing still.

**Held is three cases, all read-only — no new query needed anywhere.** `Stroller.is_detained()`
is the single call site every `EventDef.detain_seconds` row runs through
(`EventManager._check_detentions()` → `body.detain()`), so it alone covers `chatting_mother`
("Another mother" and her pram, 5s) and all three checkpoint rows (`checkpoint_hut`,
`checkpoint_gate`, `checkpoint_post`). `EventManager.door_holding_her_at()` — already public, used
by the excitement meter — covers the one frame a checkpoint's own hold
(`EventInstance.is_chatting()`, ticked in a drawn `_process()`) can still be running after the
input lock (`Stroller`, ticked in `_physics_process()`) has already cleared. And
`StillWatch.facing_a_red_light()` (new, pure) covers standing on the junction's own sidewalk band
— the whole of the `Tuning.STREET_WIDTH` (6) tile box `route_tree.gd` already treats as one piece
of ground — facing a main road whose light has not yet turned hers; stepping onto the road or a
crossing ends it, since she has then committed to crossing.

**A held frame restarts the count rather than freezing it.** `StillWatch._feed()`'s `held`
argument re-anchors her at wherever she actually is on every frame it is true, so a mother
released from a hut, waved off a chat or let off a curb needs the whole of the wait again rather
than being caught the instant she can move — freezing would let whatever had accumulated before
the hold survive it and fire the instant she is free, which is the checkpoint bug itself.

**Rejected:** a tighter radius around the crossing paint, in place of the whole sidewalk band —
the band already reads as one piece of ground everywhere else in the city.
