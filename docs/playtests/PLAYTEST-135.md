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

## Then, where the guard sets off from

Draft PR #355 stood the guard beside the band, on the side she is on. It left one question open:
the chase is still measured from the band's centre. A guard really setting off from 23–46px
closer to her would already be inside his 164px stand-off when he notices her, and he would lunge
on the first frame with no warning. Offered: (a) measure his stand-off from his 28px catch reach
instead of his 86px field core, giving 106px; (b) widen his field by the post distance; (c) he
holds his ground through the warning. The orchestrator proposed two guards, one on each side,
only the one on her side giving chase, together with (a).

> "have one guard on each side?"

> "only the guard on her side can chase since the other one will be blocked"

3. **A roadblock has a guard on each side of its band.**
4. **Only the guard on her side gives chase**, since the band blocks the other.
5. **The chasing guard sets off from his post, and his stand-off is measured from his catch
   reach** (option (a)), so he notices her outside his stand-off and lunges from it rather than on the
   first frame. Proposed with statements 3 and 4;
   the player answered the proposal without objecting to it.

## Then, on the draft's pictures

> "all good, only the barrier doesn't actually reach the full width/height is that intentional?"

6. **The barrier's picture reaches across the whole street it closes**, on both axes, as far as
   its body does.

## Then, before the release

The draft's picture fix showed the gap honestly: the catalogue roadblock's body is 120px long on
a 192px street and centred on a road-lane tile 16px off the street's middle, which leaves 20px on
one side and 52px on the other, wider than the 28px pram, so she can walk round every catalogue
roadblock on one sidewalk. Offered: close the street fully as its own item after this release
(the orchestrator's pick), or keep the gap as a feature.

> "close the street fully"

7. **A catalogue roadblock closes its whole street**, as its own item after this release.

A region wall across a street stands as three roadblock bodies (sidewalk, road, sidewalk, 64px
each), and with a guard on each side of every band it draws six guards. Offered: one pair of
guards per wall crossing (the orchestrator's pick), or leave six.

> "maybe four? one on each sidewalk. would that cover everything?"

8. **A region wall across a street has four guards, one on each sidewalk on each side of the
   wall.** Asked with a question — whether four covers everything — answered in conversation the
   same day: a wall's guards never chase, so they are a drawing only, and four puts a guard on
   whichever sidewalk she walks up to, from either side; the road lane between them has none.

On the draft's new pictures, and whether #355 can merge:

> "lgtm"

9. **The end-on segment, the two posted guards and the barrier reaching its body's ground are
   approved as drawn.**

## Then, on the walled alley

A region wall across an alley is one roadblock body at each mouth, each drawing two guards, and the
inner one of each pair stands inside an alley walled at both ends, where she cannot reach.
Offered: one guard per mouth, on the street side (the orchestrator's pick).

> "one guard in alleys on each end"

10. **A walled alley has one guard at each end**, on the street side of its mouth.
