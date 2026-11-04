priority: now

# gentle-goose — Measure what the baked atlas pages cost · filed 2026-11-01

[tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #931: "I cannot plug in via usb so we can close that. the frame record is enough. file each of the remaining items, though".

**Context.** Split from M159 (a slow frame names the frame that was slow), closed in the queue review (inbox #922 in tiny-lark). Its steps so far are recorded (`tools/decisions.sh M159`). The desktop stutter is gone: "I feel like the stuttering is gone (so it was always what I predicted -- a proper atlas implementation solved it)" ([PLAYTEST-112](../../playtests/PLAYTEST-112.md)). The phone is where the frame record points: `?debug=1&framerecord=1` on the released page keeps every frame's time by system ([M159, every frame's time by system](../../decisions/2026-09-19-M159-5.md)). The deliverable of this work stays an optimization with its measurement retained as evidence ([PLAYTEST-86](../../playtests/PLAYTEST-86.md): "well the point was to actually do some optimizations. measurement is nice and make sure it's fully recorded but the core is to make things faster"): reduce a demonstrated cost without changing gameplay, with controlled before and after distributions over equal active-play windows and identical behavior verified.

**The phone profiling item is dropped**, a full browser trace from a phone plugged in by USB; the frame record is enough (the quote above).

**Read as:** the band is `now`, the closed entry's own, which the board's pick kept for the six and the player did not change.
