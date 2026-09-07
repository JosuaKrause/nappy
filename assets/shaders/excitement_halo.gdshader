shader_type canvas_item;

// Draws a soft circle of light around each source `ExcitementHalo.select_sources()` picked, out to
// that source's own outline and four pixels further — an identification cue for *which* entity is
// costing her, not a picture of the field `EventManager.total_excitement_at()` sums.
// *(2026-09-07, the player: "halo meaning only the outline of the object not the influence
// radius ... it's only meant to show which objects currently affect the player (and how much
// depending on the strength of the halo)".)* That field spans each source's own `outer_radius` (up
// to 200px), which is most of what the camera shows at all at this game's zoom — a 640x360 world
// view — so drawing it, however the brightness inside it was shaped, painted most of the screen
// whatever curve sat on top. See `ExcitementHalo.glow_radius()` for the size instead.
//
// **The sum is still real, only smaller.** Two sources' circles overlapping still add in the loop
// below, so standing between two things that are both costing her reads brighter than standing
// near either alone — the one part of "it draws the falloff itself, summed" worth keeping once the
// footprint stopped being the field. What no longer holds is that each circle *is*
// `Tuning.falloff()`: the radius is the entity's own outline and says nothing about reach, and only
// the brightness — `EventInstance.contribution_at()` — still comes from the real excitement model.

// Matched to `ExcitementHalo.MAX_SOURCES`. A uniform array is fixed-size in Godot's shading
// language, so the cap lives in both places and `source_count` is what keeps the unused tail of
// the arrays from being read.
const int MAX_SOURCES = 8;

uniform vec4 halo_colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Excitement/s at which a source's own circle reads at its brightest. Below this the glow is
// real but dim, which is what lets a felt-out CONTRIBUTION_FLOOR stay low without a source that
// barely clears it looking as loud as one near its own peak.
uniform float saturates_at = 25.0;
// The most opaque one source's circle may ever draw, so even a saturated source is a glow rather
// than a solid disc — see docs/EVENTS.md, "Soft, and under everything."
uniform float max_alpha = 0.75;
uniform int source_count = 0;
uniform vec2 source_position[MAX_SOURCES];
// `ExcitementHalo.glow_radius()`: the source's own outline (`EventDef.obstructs_radius`, half its
// silhouette) plus a 4px margin, and never the field it reaches. 15px for a person, 66px for a
// barricade — the thing's own size, whatever that is.
uniform float source_radius[MAX_SOURCES];
// `EventInstance.contribution_at(her position)`, in excitement/s. Answers *how much* for a
// circle whose *where* and *how big* are already decided.
uniform float source_brightness[MAX_SOURCES];

// `ExcitementHalo` draws a plain rect sized to the sources' own bounds, in its own local space —
// which is world space, since the node never moves — so the untransformed vertex position is
// already the coordinate every source position is given in.
varying vec2 world_position;

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	float total = 0.0;
	for (int i = 0; i < MAX_SOURCES; i++) {
		if (i >= source_count) {
			break;
		}
		float radius = source_radius[i];
		float d = distance(world_position, source_position[i]);
		if (d < radius) {
			// A soft circle rather than a hard-edged disc: the same (1-t*t) shape the real
			// falloff used to draw, kept because it still looks like a glow and not a coin, not
			// because this radius means anything about how far the source's own field reaches.
			float t = d / max(radius, 0.001);
			float spatial = 1.0 - t * t;
			float ratio = clamp(source_brightness[i] / max(saturates_at, 0.001), 0.0, 1.0);
			total += spatial * ratio;
		}
	}
	float level = clamp(total, 0.0, 1.0);
	COLOR = vec4(halo_colour.rgb, level * max_alpha * halo_colour.a);
}
