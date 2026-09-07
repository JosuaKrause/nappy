shader_type canvas_item;

// Draws the summed excitement field the meter is currently reading, over the small ground
// `ExcitementHalo` decided is worth it — see that script's `select_sources()`. A texture cannot
// be this: the inner/outer ratio of Tuning.falloff() differs per source, so the curve itself has
// to be evaluated per pixel rather than sampled off a fixed gradient.
//
// The per-source terms below are `Tuning.falloff()` restated in GLSL — flat inside the inner
// radius, easing to nothing at the outer one via `1.0 - t*t` — because `EventManager
// .total_excitement_at()` is a plain sum of exactly that function over live instances, and a
// halo that is not that sum is a picture of something else.

// Matched to `ExcitementHalo.MAX_SOURCES`. A uniform array is fixed-size in Godot's shading
// language, so the cap lives in both places and `source_count` is what keeps the unused tail of
// the arrays from being read.
const int MAX_SOURCES = 8;

uniform vec4 halo_colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Excitement/s at which the halo reads as fully as bright as it is ever allowed to. Below this
// the glow is real but dim, which is what lets a felt-out CONTRIBUTION_FLOOR stay low without
// the halo looking equally alarmed about a busker and a burning building.
uniform float saturates_at = 25.0;
// The most opaque the halo may ever draw, so it is a glow under the entities rather than a wall
// over them — see docs/EVENTS.md, "Soft, and under everything."
uniform float max_alpha = 0.55;
uniform int source_count = 0;
uniform vec2 source_position[MAX_SOURCES];
uniform float source_inner_radius[MAX_SOURCES];
uniform float source_outer_radius[MAX_SOURCES];
uniform float source_intensity[MAX_SOURCES];

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
		float inner = source_inner_radius[i];
		float outer = source_outer_radius[i];
		float d = distance(world_position, source_position[i]);
		if (d <= inner) {
			total += source_intensity[i];
		} else if (d < outer) {
			float t = (d - inner) / max(outer - inner, 0.001);
			total += source_intensity[i] * (1.0 - t * t);
		}
	}
	// A square root rather than a linear ramp, so a source only just above the floor still
	// registers as a visible glow instead of being rounded away beside a saturated one — the
	// same reason CONTRIBUTION_FLOOR is felt-small rather than derived.
	float level = clamp(sqrt(total / max(saturates_at, 0.001)), 0.0, 1.0);
	COLOR = vec4(halo_colour.rgb, level * max_alpha * halo_colour.a);
}
