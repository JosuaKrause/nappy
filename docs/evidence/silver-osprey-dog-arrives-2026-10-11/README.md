# A loose dog sent from behind arrives and passes

Claim: a loose dog the director sent while she was walking south, with her then turning round and
walking north, comes up behind her from off screen, closes on her and runs past. The montage is
frames 1, 6, 10, 14, 18 and 22 of one three-second burst, left to right, top to bottom (tiles are
640x360 downsized). The run-log excerpt shows the dog at 139px, 73px, 36px and 17px from her.

Limits: this shows a dog that is closing (she walks at 92px/s, it runs at 132). The retirement of a
dog she outruns is pinned by `tests/test_loose_dog_arrives.gd`, not by a still. `--invincible`.

Command: `godot --path . -- --seed 4242 --day 5 --spawn arterial --force loose_dog 5 --walk 6s10n
--press snapshot_burst 7.8 --after 14 --invincible --no-save --no-focus-pause --player-view`
Retained: the montage, `burst.json` (frame times) and the dog's lines of `run.log`.
