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

**The first cut was not the ask, and the player said so.** The tunnel was reported done with a
before-and-after picture, and the bridge was mentioned as having the same two dotted-line tiles;
the player first said *"let's fix the bridge too"*, and then, on the pictures:

> "how does the tunnel get improved? the ask was that the progressively shaded part to be added
> in the mouth. i don't see that in the evidence and I don't see evidence of a car getting darker
> when driving in as well? all you did is make the mouth taller which was *not* the ask"

> "why did you remove the crossing texture in front of the bridge? it's a valid pedestrian
> crossing"

Both right. The first cut had cut only the side walls out of the sprite and left the arch's inner
face across the hole, so no road showed and nothing faded — and the sprite had been made a tile
taller, which nobody asked for. The bridge's crossing goes back: it is a real crossing in the open.
What the note asks for, restated: **the shading is a gradient inside the mouth the sprite already
has, and a car driving in gets darker as it goes** — and the evidence has to show a car doing it.

**Built in the same session.** The record, with the numbers and what was rejected, is in
[DECISIONS.md](DECISIONS.md) under "The tunnel swallows the road".
