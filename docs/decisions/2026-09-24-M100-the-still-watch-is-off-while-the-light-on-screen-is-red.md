## M100 — The still watch is off while the light on screen is red · built 2026-09-24

*([PLAYTEST-128](../playtests/PLAYTEST-128.md), statements 13 and 14: "How about just deactivating
the watch when the light is red and the intersection is visible. If she's stuck she will be stuck
when it turns green still".)* `StillWatch.facing_a_red_light()` takes the camera's world-space
view and holds `--quit-when-still` while the signalled junction nearest her, among those whose
6-tile box is on screen, shows her red (its main-road arm green or amber). Where she stands no
longer matters, on the road included. Follows M189, a hold is not a stand, whose rule held the
watch only on the sidewalk inside that junction's own box. The green wave gives each junction its
own offset, so two junctions on screen can disagree, and the nearest decides.
`tests/test_still_watch.gd` covers far away, on the road, green, no junction on screen, a red one
off screen and two that disagree.

**Open to overturn, chosen by the agent:** nearest is measured to the centre of the junction's
box.
