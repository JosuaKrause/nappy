## M112 — Escape interior graphics from the references, 2026-09-12

Playtest 59 asked to use the playable ending section and reference images to fix its graphics.
The four apartment sketches and two stair references were compared with the existing runtime
pictures. The accepted layout from playtests 54 and 55 remained: opposite-end stairwells,
three hallways, the lobby and basement, joined on one map by fade-and-teleport doors.

The graphics pass gave each switchback continuous broad tread decks, separate foreground and
rear rails, enclosed shaft bays and end caps, and level landing platforms. The floor platforms
fit the door/landing/clearance strip; turn platforms fit the existing cleared corner cells.
The short basement entry got a matching deck and rails. The original walking cells, collision,
slope redirection and door behavior were not changed. Apartment recesses became four distinct
locked thresholds per hallway, including the start; usable south-edge doors became open notches.
The wide lift and entrance are centered on their own widths and drawn after neighboring wall
strips so they cannot be cropped. The lobby chandelier was removed to expose the furniture
barricade, and brick-wall pictures were omitted at the basement's two walkable passage mouths.

**Choices open to overturn.** The locked recesses occupy columns 2, 5, 7 and 10. Floor-starting
flights have a rear rail; return flights keep that edge open to avoid an incoming foreground
rail crossing it at the turn. Floor platforms are 96×32 and turn platforms 64×96, chosen from
the existing physical clearance rather than added walkable space. A first assembly's crossing
rails and oversized platform were rejected internally; those drafts were not retained. The
repeating south-edge threshold source shown in the earlier human-review build is preserved in
`docs/evidence/archive/rejected-graphics/escape-interior-before-reference-fix-2026-09-12/`;
the remaining original stair sources stay in the tile kit, and the earlier runtime pictures
stay in `docs/evidence/m112-escape-2026-09-10/`.

**Verification.** Godot import/boot, the focused interior suite and XML/document lint passed.
Every new or changed source was rendered with Godot at native and 3× size and inspected; sheets
and an assembled stair preview are in `docs/evidence/m112-escape-graphics-2026-09-12/`.
The final 1280×720 runtime pass captured all seven parts plus both stair directions, lower
landings and the basement passages. Real input carried the collision-enabled player around the
first switchback of both stairwells to the second-floor landing, within 4px of its center.
Both walks have complete three-second bursts with actual frame timing, original PNGs and MP4s.
The run and capture rig are preserved under
`docs/evidence/archive/session-captures/2026-09-12/run-043554-seed4242-v0.8.2-704-g4f3cfb7-dirty/`.
The human readability and control-feel questions are in `REVIEW.md`; this pass does not build
the finale events, clock or city escape.

**Integration review.** Main's street-tree body removal and checkpoint/release-flag queue
additions were retained alongside the interior graphics. The tree/debug-layer edits have no
interior caller; the new apartment door-flag request remains open under the finale rather than
being silently implemented by an art pass. Playtests 58 and 59 remain separate primary sources.
The archive's prepend conflict retained both histories, and the merged boot, interior suite,
document lint and whitespace checks passed.
