# M109 roof equipment in-engine context

`roof-context.png` is a Godot-rendered review frame at the game's 1280×720 landscape resolution.
It uses the runtime building, roof, facade, sidewalk and road atlas regions at native scale. The
eleven roof objects are manually arranged on one oversized roof so the whole family can be judged
in one frame; this is a presentation rig, not a claim that ordinary generation places every kind
on one building.

After `./tools/check.sh`, reproduce it with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 \
  scenes/dev/roof_context_preview.tscn -- --no-save
```

The scene exits after writing the frame. Its roof objects use the same bottom-center foot anchors
and `Entities` y-sort parent as the generated city.
