# M108, "every living thing that moves has a stride" — the event half

Two review sheets and one motion capture for the item's event side: a second SVG frame for
fourteen families (`docs/GRAPHICS.md`'s rows list which) and the distance-driven/timer-driven
alternation in `EventInstance` that picks between the two.

## The review sheets

`event-strides-native.png` and `event-strides-3x.png`, rendered by
`tests/probes/m108_event_strides_sheet.gd` (`tools/test.sh probes/m108_event_strides_sheet.gd`)
straight from the SVG source files under `assets/events/`, before either texture was wired into
`EventInstance` — the same "review before binding" order the walker's own precedent
(`docs/evidence/m108-walker-stride-2026-09-11/`) used. Seventy rows, frame a beside frame b, one
per family per view. Reviewed for drift above the waist on the humanoid families' cardinal and
side columns (none found — coat, head and held things hold still) and for a visible leg or pedal
shift in every b column (present in all seventy; subtle on the families whose coat covers most of
the leg, such as the yeller's long coat, and on the cyclist's own pedal swap, which is a small
picture to begin with).

## The burst

A dog walker paces continuously from the moment he stops telegraphing, so he needs no
`--invincible` waiting for a chase or a turn to happen in view — he is already moving the instant
the day starts. One `tools/shot.sh` run, standing beside him from the first frame:

```
tools/shot.sh /private/tmp/m108-strides-shot.png 6 --seed 4242 --spawn event:dog_walker \
    --invincible --press snapshot_burst 1
```

`--spawn event:dog_walker` puts the player just off his own siting; `--invincible` is included on
the reasoning the **verify** skill gives for any capture whose timing is not trivial to hit, even
though this one did not end up needing the day to be held open. Kept whole under
`dog-walker-burst/` (`run.log`, `maps/day01-attempt1.png`, and `asked/burst-3904358-001/` with its
36 numbered frames, `burst.json` and the `tools/clip.sh`-made `burst-3904358-001.mp4` beside it) —
day 1, act 1, seed 4242.

**What it shows.** Cropping the walker and his dog out of frames 18–23 (elapsed 1.425s–1.850s) and
scaling 7× with nearest-neighbour: frames 18–21 hold the walker's legs together and the dog's own
front leg tucked, then frame 22 (elapsed 1.760s) shows both bodies flip together — the walker's
trouser cuffs flare into the crossed stride and the dog's near leg lightens into its own second
frame at the same instant — and frame 23 holds that pose. The two never disagree about which frame
is up, which is `_gait_stepping()`'s own "one lookup for the pair" read directly off the picture
rather than only off the source. Frames 1–7 (elapsed 0–0.5s) show the dog only partway into the
crop from the left edge as he first walks into shot, not a separate posture — nothing here is the
telegraph, which is already over by the time this instance is on screen this close.

**Not caught in this run:** a second full flip back to the rest pose — the walker had mostly
walked past the crop box by frame 30 or so, and a wider or re-centred crop was not worth a second
`shot.sh` invocation for what frames 18–23 already establish. One clean alternation, actor and
held thing agreeing, is what this capture is asked to prove and what it shows.
