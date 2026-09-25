# Playtest 135 — The roadblock is end-on on a vertical street, and its guard stands beside it

2026-09-25. Said in conversation, from a rig window an agent had open (not a played run).

## What the player said

> "hmm, did the updated barrier graphics never make it in?"

> "the barrier is still the sideway view for each segment in vertical"

> "also the guards are on top of the barrier?"

> "I just saw it in the rig one of the agent uses"

## What was found

The street-obstruction rework (PR #301, released in v0.16.0) redrew the roadworks barrier with an
end-on picture for a band stacked down a north-south run (`barrier_segment_vertical.svg`), which
answered playtest 64's "sideways textures stacked on top of each other" for roadworks. The
roadblock (`roadblock_segment.svg`, `roadblock_end.svg`) was not in that rework and has only the
broadside picture, so a roadblock stacked vertically still repeats a side view per segment. Its
guard is drawn at the band's own centre (`EventInstance._draw_roadblock()`), over the barrier.

## The statements

1. **A roadblock stacked vertically draws an end-on segment**, the way the roadworks barrier does,
   so the band reads as one barrier rather than a stack of side views.
2. **The guard stands beside the barrier, never on top of it.**
