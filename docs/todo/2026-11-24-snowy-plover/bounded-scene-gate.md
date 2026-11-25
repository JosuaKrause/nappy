# A bounded scene's check that no event body stands outside the authored ground

The runtime refuses a bounded scene with an event body outside its authored ground ("event ... is
outside authored bounds", in `src/dev/scene_recipe_runtime.gd`). No suite holds the refusal, because
the ground holds on today's recipes by construction: no recipe puts a body outside, so no test can
reach the check. The test wants a bounded recipe that names a gate, a body placed outside the
ground, and the runtime's refusal.
