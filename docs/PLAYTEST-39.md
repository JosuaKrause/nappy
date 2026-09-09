# Playtest 39 — 2026-09-08

One note with a screenshot, from a run on `main` after M92 merged (`v0.8.0`, seed 435159537, day
1, standing on the pavement beside the tunnel). The run is copied whole to
[evidence/run-224434-seed435159537-v0.8.0/](evidence/run-224434-seed435159537-v0.8.0/); the
picture the note came with is `asked/059s-attempt4-asked.png` inside it.

---

## 1. The tunnel is wrong

> "the tunnel is wrong. the fading out should happen inside the tunnel entrance above the tunnel
> entrance should just be the mountain. and the road texture should be the normal road texture not
> the pedcrossing"

**What the picture shows.** Three things, each a sentence of the note:

- **The fade is in the wrong place.** The darkening ramp runs the whole depth of the border band —
  eight tiles — and the portal is three tiles tall, so five tiles of road fading to black stand
  *above* the arch, on the mountainside. Inside the arch the opening is painted solid black by the
  sprite, so nothing fades there at all.
- **Above the entrance is road, not mountain.** The border carries the spine's carriageway the full
  depth of the band at the north, the same as it carries it on to the bridge at the south.
- **The road into the tunnel is drawn as a crossing.** The spine's last two tiles before the edge
  are the border junction's outward crossing, painted with the main road's dotted lines, and the
  tiles beyond the edge copy that picture onward under the arch.

**Partly a re-report.** [PLAYTEST-24.md](PLAYTEST-24.md) finding 5 is *"the tunnel in the north has
its road texture above the tunnel entrance and the tunnel entrance itself is black"* — the same two
defects, three sessions ago. The picture-of-a-crossing half is new, and it sits on top of the
decision recorded under playtest 14 that a boundary junction's outward crossing is a real crossing:
that stands for the tile — a walker on the outer pavement still crosses there — and what the player
asks for is the *picture* of the two tiles that lead into the mouth.

**What this side reads into "inside the tunnel entrance".** The fade has to have room, so the
portal's opening is what sets its depth: the road runs under the arch exactly as far as the opening
is tall and is fully dark at the ceiling, and beyond that the ground is mountain. A car leaving by
the tunnel still drives on out of sight before it is recycled, so the mountain above the portal
has to be painted *over* the traffic as well as under it, or the car goes dark in the mouth and
comes out bright on top of the rock.

**And the bridge, when the tunnel was reported done.** The tunnel fix left the two dotted-line
tiles before the bridge deck as they were and said so; the answer was immediate:

> "let's fix the bridge too"

So both ends of the spine run plain asphalt into the border.

**Built in the same session.** The record, with the numbers and what was rejected, is in
[DECISIONS.md](DECISIONS.md) under "The tunnel swallows the road".
