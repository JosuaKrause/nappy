# M213 — the chalk mark's robber stands at the far end of its alley, 2026-09-27

Two stills, `tools/shot.sh <name>.png 3 --seed <seed> --day <day> --spawn contact --invincible
--no-title`. `--spawn contact` stands her beside the day's own chalk mark; `--invincible` only
freezes the clock and the meter so the shot is not racing a day loss. Retaken after the review of
#414 found the first pass still drew from the old 66-176px band around the mark, only leaning
toward the far end — `ResistanceDirector._draw_guard_position_near_far_mouth()` now stands him at
the alley's own far mouth instead, or as near it as the alley allows.

## `seed4242-day6.png`

Seed 4242, day 6's mark: the readout's own `chalk mark guarded (far mouth): robber 200px away`
(`run.log`) is this run's draw — past `pursues_within` (140px) plus `ContactPoint.REACH` (36px),
so a walk in from the mark's own end stays outside his own trigger range. She stands at the top of
a north-south alley, on the mark; the robber (the dark hooded figure, with his own glow) stands
near the bottom edge of the frame, at the alley's far, southern mouth — the far end from her, past
where the old band could ever have reached.

## `seed555555-day6.png`

Seed 555555, day 6's mark, a different city and a different alley (`chalk mark guarded (far
mouth): robber 113px away`, `run.log`) — a shorter alley, inside `pursues_within` plus `REACH`
even at the far mouth itself, which is the "as near it as the alley allows" case rather than the
safe one the first still shows: the mark sits toward the alley's right-hand mouth and the robber
(the hooded figure at the left) stands toward its far, left-hand one, the same far-mouth rule
holding on a horizontal alley as the first still shows on a vertical one, even where the alley
itself is too short to also clear his trigger range.
