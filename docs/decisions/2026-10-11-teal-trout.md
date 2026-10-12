# teal-trout — Every charger's three stages, audited · 2026-10-11

[velvet-marten](../playtests/2026-10-11-velvet-marten.md), #699: "entities that charge towards the
player when the player gets too close need three stages: neutral (with neutral visuals), warning
(when the player gets close; needs to be visually distinct), and then the actual charging. Some
already do this but not all"; #704 puts the police and guards who notice and lunge in; #705 leaves
out a pursuer that arrives already charging.

**The audit** ([teal-trout-2026-10-11](../evidence/teal-trout-2026-10-11/README.md)) lists every
entity that waits and then comes at her, what it draws in each stage and the code that picks it,
with a frame-locked clip and a key-frame strip of each from a scene recipe. Short of a stage: the
charging dog (neutral and warning both, one gallop picture throughout), the alley robber (his
warning is his lunge), and the hunting roadblock's guard (his warning is his post); the door guard has no neutral of his own,
and whether he falls under the rule is the player's to say. The investigating patrol car's policeman and the hunting van's men show
three distinct stages. The alley mouse, the pigeon flock and the masked man do not charge her; the
masked man's stages are drawn inverted. Each finding is an item under the entry.

**To make the clips**, a scene recipe event takes an optional integer `heat`, installing its row
through `EventCatalogue.heated()` (`src/dev/scene_recipe_runtime.gd`; `docs/SCENE_RECIPES.md`;
`tests/test_scene_recipe_runtime.gd`), since no dev flag reaches a resistance level on an ordinary
day.

**Seen and not explained:** in the robber's clip, under `--invincible`, she stops being drawn after
his catch; no lost day is logged, as `--invincible` intends, and no code was found that hides her. It
is not an item until it is seen in a normal run.

*Chosen by the implementer, open to overturn:* recipe recordings rather than `shot.sh` bursts, which
stood her across the street from the event and ran at a few frames a second under load; the cat left
out as sited already crouched, with no waiting stage.
