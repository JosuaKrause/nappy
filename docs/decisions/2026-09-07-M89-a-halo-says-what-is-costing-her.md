## M89 — A halo says what is costing her · built 2026-09-07

*Asked for on 2026-09-07: "lastly, let's create a shader (if that is possible in godot) to create a
soft halo surrounding entities that are currently actively causing excitement. this is meant as a
hint to the player so they know what to walk away from and what is causing excitement to go up."*

**It answers a question the visual vocabulary never had a cue for**: the meter is going up right now
and nothing on screen says which of the six things around her is doing it. A number says *how much*
and never *which*.

**Three shapes were built, and the first two were rejected on screenshots rather than on argument.
That sequence is the whole value of this entry.**

**1. The summed field, drawn at each source's own `outer_radius`.** This is what the milestone was
specified as — *"what is drawn is the falloff itself, which is why it is a shader rather than a
texture"* — and it washed most of the frame amber. `EventDef.outer_radius` reaches up to 200px
against a visible world of 640x360 at zoom 2, so the footprint alone is most of the screen.

**Three brightness curves were tried against the same two captures and none of them rescued it**,
which is the part worth remembering: `sqrt(total / saturates_at)` lifted a 1/25 tail to 0.2 of full
brightness across the whole area between the floor and the outer radius; linear measured the same
wash, because `Tuning.falloff()` is flat-ish for the first half of a field's own radius; squared was
measurably tighter and still lit two buildings on a day-6 corner; cubed killed the wash and also
flattened a lone leaf blower to nothing visible. **The footprint was the defect, not the curve** —
a lesson that cost four commits to learn and is cheap to re-learn wrong.

**2. A compact circle sized off `EventDef.obstructs_radius`.** Fixed the footprint and was still
wrong, and the player named why: *(2026-09-07: "halo meaning only the outline of the object not the
influence radius ... the halo should not extend more than a few pixels beyond the object's
outline.")* A circle is the shape of a **number**. It also has no answer for a row that is not one
body: a cafe is tables and sitters, a protest is a rank of figures, roadworks is a run of barrier
segments, and no single circle is any of their outlines. An earlier version of this shape also
clamped the radius to 32px, which drew a `barricade` (62px of body) a halo **inside** its own
silhouette — a glow smaller than the thing it names reads as a mark on the ground beside it.

**3. The sprite's own outline, traced. Shipped.** *(2026-09-07: "it should use the outline of the
sprite. that's why it needs to be a shader. or draw the sprite in a uniform color multiple times
(that's an inefficient hack for when shaders are unavailable)".)* `EventInstance._draw_body()` and
its ~15 `_draw_*` helpers take a `canvas: CanvasItem = self` parameter, so a child `Node2D` with
`show_behind_parent` re-runs the *same* drawing code at a ring of **12 offsets at
`HALO_MARGIN` (4px)**, flattened to one colour by `assets/shaders/excitement_halo.gdshader`. Every
row is therefore outlined as the shape it actually draws.

**A `canvas_item` shader on the entity's own sprite could not have done this alone**, and knowing
why saves the attempt: a fragment shader can only write inside the rect it is given, and every
sprite's rect is tight to its art — so a dilation is clipped at the silhouette's own edge and reads
as an inward outline rather than a glow around it. The offsets are what reach outside the rect.

**The facet question was answered by arithmetic rather than by another screenshot.** The outline is
the union of N discs of radius 4px, so the worst error is at a convex corner, `r(1 - cos(pi/N))`:
0.30 world px at 8 offsets, 0.14 at 12, 0.08 at 16 — all sub-pixel at zoom 2, so 12 is comfortable
and 8 would have done.

**`modulate` is not the per-instance channel, and two wrong turns found that out.** A fragment
function that writes `COLOR` is **not** re-multiplied by the node's own modulate afterward — a
screenshot came back with a pure white rim. A `MODULATE` fragment built-in does not exist in Godot
4.7 (`SHADER ERROR: Unknown identifier in expression: 'MODULATE'`, caught by `check.sh`). The
working channel is an `instance uniform` set through `set_instance_shader_parameter()`, which is
what lets one shared `ShaderMaterial` serve every instance.

**What is real and what is decoration, stated so the next reader does not blur them.** Size answers
*which thing* and is decorative — `HALO_MARGIN` is the same 4px for every row and says nothing about
reach. Brightness answers *how much* and is the real model:
`EventInstance.contribution_at(her position)` over `SATURATES_AT` (25/s, shared with
`Tuning.MARK_WORTH_A_DETOUR`, the same line the caret draws between ignorable and worth-a-detour),
capped at `MAX_ALPHA` 0.75. `ExcitementHalo` draws nothing at all now; it selects, once a frame, and
sets each instance's strength.

**The selection is untouched from the first version and is the only tested half.**
`CONTRIBUTION_FLOOR` (1.0/s), `MAX_SOURCES` (8, weakest dropped first), and `city_wide` rows
excluded by kind because they have no position to stand at — the vocabulary answers those with a HUD
line instead. `tests/test_halo.gd` holds the selection and nothing about the drawing, per the player:
*"proof for the UI is my playtest don't try to come up with a complicated rig to test it. that's
wasted effort."*

**The halo does not trace the drop shadow.** *(Playtest 35 finding 5: "the halo should not include
the shadow".)* `_draw_body()` puts the shadow down first, so the ellipse was being outlined too,
leaving an amber lobe on the pavement beside every glowing entity. Routed through an
`EventInstance._draw_shadow()` that returns early for the halo canvas, rather than guarded at each
of the fifteen call sites, so a `_draw_*` helper added later inherits the rule. **The shadow is the
ground under the thing, not the thing.**

**Two standing decisions were overturned to allow this, both narrowly.** `.claude/skills/cues/`'s
*"No circles around entities"* and *"Nothing draws a field"* were about **danger** — what a thing
will do to you — and that reasoning is untouched: nothing is ringed to say how bad it is. The
exception is one cue, for the cost being charged right now, traced at the thing's own outline. It is
written in the skill as "A glow, not a field" and in `docs/EVENTS.md` as the **Entity halo** row.

**What it leaves open is queued as a question**: the crowd gets no halo, because pedestrians are
`CrowdAgent`s rather than events. Measured on the arterial pavement on day 6 of seed 4242 — the bar
at 48 and `incoming 20.22 /s` with nothing glowing in frame. `CrowdAgent` already has its own
`contribution_at()`, so the plumbing is small and the design is not: a couple of hundred walkers a
day is exactly the *"a cue that marks everything says nothing"* failure the floor and the cap exist
to prevent. Three possible answers are written down in `TODO.md` and none is chosen.
