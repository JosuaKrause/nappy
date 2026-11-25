priority: later
after: 2026-10-18-minty-quail

# silver-finch — The frames that carry the physics tick take 17 ms, not 10 · filed 2026-11-25

**The ask.** None. The remeasure's reading: yes, by the planner's bar. The physics runs at 30 Hz, so one frame in four carries a tick (the crowd, the events and the player step on it), and those frames are the slow ones.

**Evidence.** Profiler off, three rounds, `frame_ticks.py`: the frames carrying the tick average 16.9, 17.0 and 17.2 ms on head against 9.9, 10.0 and 9.9 on v0.29.0 (16.9 to 17.8 on after-4b), and the ten longest frames average 21.5 to 22.4 ms against 11.3 to 11.4; the other three frames in four got faster (5.4 to 5.5 ms against 7.8), so the mean frame is not slower (callback interval 6.8 to 7.4 ms against 8.6). A tick frame now takes longer than a 60 fps frame (16.7 ms). The rise dates from the crowd and the events moving onto the tick (minty-quail-21, minty-quail-33). The tables are in `docs/evidence/minty-quail-end-timings-2026-11-25/README.md` (T3) and `docs/evidence/minty-quail-end-timings-2026-11-25/frame_ticks.py`, `docs/evidence/minty-quail-end-timings-2026-11-25/raw/fp/` and `docs/evidence/minty-quail-end-timings-2026-11-25/raw/fp_v029/`; the reading is in minty-quail-downy-finch.

**Proposed, not asked for:** the band `later` and the bar (every round beyond spread, and by more than a tenth) are the filer's proposal (the remeasure's planner, minty-quail-downy-finch), open to the player's correction; the plainer alternative is to file no entry and let a phone's frame record (polite-plover) decide first.

**What would close it.** The frame profile's launcher on head beside v0.29.0 (`docs/evidence/minty-quail-end-timings-2026-11-25/README.md` says how), three rounds, the tick frames' mean and the ten longest, after a change that spreads the tick's work or shortens it: tick frames under the frame budget of 16.7 ms or the cost accepted by the player. Whether a phone shows it is what polite-plover's frame record decides, so the record comes first.
