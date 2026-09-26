## M109 — Stroller hand contact — 2026-09-12

PLAYTEST-65 asked to draw the stroller much closer so the mother's hands connect. The canonical
PNG and SVG source assemblies cover both pushing gait frames and all eight directions. The
selected continuous projection uses horizontal distance 22px, north 14px, south 8px, the existing
0.7 Y factor and a shared 4px upward lift. A single 22px lead left the south grip disconnected;
the vertical lift fixed the profile gap, and reducing north to 14px also aligned the diagonal grip.
The side A hand and handle tip coincide; B is one native pixel apart, with diagonal pairs under
half a pixel apart. These placement choices remain open to visual judgment.

`pram_draw_offset()` supplies the art, shadow, baby cue and debug field position. Its directional
Y contribution reaches zero at east and west, so changing north/south distance does not make the
stroller jump while turning. The unsquashed collision body remains `facing * PLAYER_BODY_RADIUS`
(14px), with its existing 8px radius. Touch stop keeps its 24px radius and lifted center; the
side-view pram center remains about 29px from that center and a tap there steers.

The integrated root checkout passed import/boot and 273 focused stroller, touch, orientation and
presentation checks. Relationship tests cover collision independence, shared drawing offset and
continuity at east/west sign boundaries. The reproducible PNG/SVG assemblies and measurements are
in `docs/evidence/pram-contact-2026-09-12/`. They establish canonical source contact, not live-turn
appearance; that remaining human check is in REVIEW. No additional windowed run was taken.

The player also required every graphics, rollout and GIF script to remain reproducible and easy
to find. The illustrated-PNG skill now requires retained recipes, immutable inputs or hash guards,
exact timing and regeneration commands; `docs/evidence/README.md` indexes the families and reviews.

The player then identified floating wheels in the connected drawing and suggested increasing the
stroller's scale to match the handle-to-wheel and hand-to-foot heights. The grounded stroller scale
record above covers that correction. The first comparison recipe also selected draw order from lifted screen Y
instead of facing Y. The corrected primary sheets use the runtime's facing rule; the original
review assemblies and their fixed inputs remain reproducible snapshots.
