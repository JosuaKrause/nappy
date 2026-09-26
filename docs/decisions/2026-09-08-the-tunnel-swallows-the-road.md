## The tunnel swallows the road · built 2026-09-08

[PLAYTEST-39.md](../playtests/PLAYTEST-39.md)'s one finding, and the second time the tunnel has been reported:
*"the fading out should happen inside the tunnel entrance above the tunnel entrance should just be
the mountain. and the road texture should be the normal road texture not the pedcrossing"*.
Playtest 24 finding 5 had said the first two things — *"its road texture above the tunnel entrance
and the tunnel entrance itself is black"* — and what was built for it put the ramp on the road but
left the ramp the depth of the border band and the opening painted solid.

**What was wrong, in numbers.** `City.OUTSIDE_DEPTH_TILES` is eight and the portal was three tiles
tall, so `CityEdge._swallow_the_road` drew five tiles of road fading to black on the mountainside
above the arch, at the full six-tile corridor width; the sprite's opening was an opaque
near-black rect, so inside the arch nothing faded at all; and `City._border_source` gave the
spine's carriageway the same eight-tile run north as it gives it south on to the bridge. The two
tiles before the edge are the border junction's outward crossing, drawn with the main road's dotted
lines, and every outside tile clamps to the map's edge row and copied that picture onward.

**What it is now.** One number, `CityEdge.TUNNEL_DEPTH_TILES` (2), is the depth of the portal's
opening, and three things read it:

- **The road runs under the arch exactly that far and no further.** `_border_source` carries the
  carriageway two tiles north and paints mountain beyond; the bridge keeps the whole band,
  because a deck is in the open and a tunnel is inside the rock.
- **The fade is the opening.** The ramp is one rect per `RAMP_STEP_PX` (8px, eight steps over the
  64px opening), alpha climbing linearly to `1.0` at the ceiling, only as wide as the carriageway
  (`Tuning.carriageway_width()`, 64px). A car's length spans several steps, so it is darker at the
  front than the back while it goes in, and gone by the top.
- **The sprite is a frame around a hole.** `tunnel_mouth.svg` stays 192×96; every rect in it is
  drawn *around* the 64×64 hole between the side walls, so the darkening road tiles show through.
  *Rejected on the way:* a first cut that only left the side walls out and let the arch's inner
  face fill the hole — the road never showed, nothing faded, and the portal had grown a tile
  taller for no reason. The height was never the ask; the fade was, and it lives inside the
  opening the sprite already had.

**The dark is drawn over the traffic, because y-sorting cannot darken a car as it goes in.** Every
sprite is anchored on its base, so a northbound car's origin is its rear bumper: sorted against a
piece anchored on the map edge, the car stays in front of it until the whole car is past the edge,
and then flips behind in one frame — bright, then black, with the nose never darkening at all. A
first cut had the ramp y-sorted and the screenshot showed exactly that: a car wholly inside the
mouth drawn at full brightness over the ramp. So the tunnel is two `CityEdge` pieces at the same
point: `TUNNEL_DARK`, the ramp, is a child of `City` at `OVERHEAD_Z_INDEX` (3, above `Entities`'
2), where it lands on whatever is under it and a car's nose darkens before its tail; `TUNNEL`,
the portal's face and the mountain over the road beyond it, stays y-sorted in the entity layer.
*Rejected on the way:* the whole piece in the overhead layer — that put the stone frame over the
heads of walkers on the pavement in front of it, which the y-sort had been getting right.

**The mountain is painted over the traffic as well as under it.** A car on the spine still overruns
the map by `Tuning.OUT_OF_SIGHT` (420px) before it is recycled, which is further than the portal is
tall, so `CityEdge._roof_the_tunnel` blits the same `mountain.svg` tile the border uses over the
corridor from the top of the portal to the far edge of the band. It is drawn by the y-sorted face
piece, which is enough there: a car far enough in to be under the mountain has its origin past the
edge and sorts behind it on its own. The pixels are identical to the ground beneath, so the lid is
invisible; without it a car went dark in the mouth and came out bright on top of the rock.

*Rejected on the way:* shortening the northbound car's overrun to the opening's depth instead.
That hides the leaver, but the same room bounds where a *southbound* car may be placed when its
entry rolls all fall outside the map, and it would then appear inside the opening in plain view —
the one thing `OUT_OF_SIGHT` exists to prevent. Painting the mountain over the band costs nothing
and keeps both ends of the rule.

**The two tiles into the mouth are drawn as road; the two on to the bridge stay a crossing.**
`GroundTiles._crossing_variant` returns the road picture for a main-road crossing in the map's
first `SIDEWALK_WIDTH` rows — the spine's approach to the tunnel and nowhere else — so the asphalt
runs plain from the junction box into the dark. **The tile type is unchanged**: playtest 14's
decision that a boundary junction's outward crossing is a real crossing stands, a walker on the
outer pavement still crosses there, and every rule that reads `CROSSING` reads what it read. Only
the picture moved, which is the same shape as the spine's zebras becoming dotted lines.

*Asked for the bridge too, then overturned on sight.* *(2026-09-09: "let's fix the bridge too",
then, seeing it: "why did you remove the crossing texture in front of the bridge? it's a valid
pedestrian crossing".)* So the rule is the tunnel's alone: the crossing at the foot of the bridge
is a real crossing in the open, and its paint says so.
