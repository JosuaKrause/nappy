# M183, the power station and the blackout — the blackout and the dark escape

Captures on `feature/m183-blackout`, seed 4242, 1280×720, all with `--invincible` so the day clock
and the meter stand still while the capture waits. The developer readout is on in each.

**The blackout, as a burst across the moment it happens** —
`rig-112545-seed4242-v0.16.0-13-gc05dfda9/`, from
`tools/shot.sh … 10 --seed 4242 --day 14 --blackout --spawn power_station --walk west --invincible --press snapshot_burst 5.5`.
`--blackout` stands in for the sabotage; she starts at the station's front door and walks west,
and the city goes dark once she is `Tuning.BLACKOUT_DISTANCE` from the station's lot. The block
to the west comes into view from frame 20 with some of its windows lit; they are lit in frame 31
and every one of them is off in frame 32, the next frame, with the HUD's one line, "The
loudspeakers cut out mid-sentence." The run log's `quiet` line sits between the burst's start and
end. `burst-9388293-001.mp4` is the same frames as a clip.

**The station's hall on the last night, lit** — `station-door-day14-lit.png`, the same flags
standing at the door for three seconds: the clerestory band is dimly lit from inside
(`power_station_clerestory_lit.svg`). After the blackout it is the unlit band the station is
drawn with on every other day.

**A dark spine junction with a car coming** — `dark-junction-car-coming.png`, the first frame of a
burst from `--day 14 --blackout --spawn signal --walk west`, far enough from the station that the
city is dark from the start. The signal heads on the junction's corners show no lamp, a car is
coming down the spine from the top of the frame and another is turning in the box. She is inside
the region door's checkpoint hut at the middle of the frame, held there, so she is not drawn.

**The escape in the dark**, one still each, `--start-escape [part] --invincible --press ui_accept 0.5`
three seconds in:

- `escape-hallway-third.png` — her own floor's hallway in the gloom, the wall lamps and the
  chandelier unlit.
- `escape-stairwell-right.png` — the right stairwell's top landing under the red emergency
  lighting (`stairwell:right`).
- `escape-basement.png` — the basement, darker than the hallways, with a steam vent on its jog
  (`basement`).

`tests/test_blackout.gd` is the verification of what goes dark when; these only show what it
looks like.
