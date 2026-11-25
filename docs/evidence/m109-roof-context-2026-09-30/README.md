# M109 roof equipment in-engine context

`roof-context.png` is a Godot-rendered review frame at the game's 1280×720 landscape resolution.
It uses the runtime building, roof, facade, sidewalk and road atlas regions at native scale. The
eleven roof objects are manually arranged on one oversized roof so the whole family can be judged
in one frame; this is a presentation rig, not a claim that ordinary generation places every kind
on one building.

The rig's runtime and scene source is revision `58a472913bf0237504cca9352fd94928a8483f27`, the
squashed commit of pull request 441 that holds this folder and
`scenes/dev/roof_context_preview.tscn`. The scene is not in the current tree, so check that
revision out in a fresh checkout, run `./tools/check.sh`, and reproduce it with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 \
  scenes/dev/roof_context_preview.tscn -- --no-save
```

The scene exits after writing the frame. Its roof objects use the same bottom-center foot anchors
and `Entities` y-sort parent as the generated city.
