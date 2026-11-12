# minty-quail — The scenery residency is typed through a part its three kinds share · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell (inbox #1268 in olive-ferret), and the scenery
residency, which stands scenery up near the view and frees its pictures far away, needed a design of its own to be
typed (the record 2026-10-18-minty-quail-sandy-hedgehog): its items share no class below `Node2D`.

## What was built

- **A part, `SceneryResidence`** (`src/city/scenery_residence.gd`), held by each kind the residency stands up: a
  building, the city's home door and every scenery sprite. It holds the flag saying whether the pictures are resident,
  changes it only when it differs, and answers the item's bounds, the frame-record job it counts as, and whether its
  owner is freed or queued for deletion. Each kind hands the part two of its own methods (its bounds, and what it does
  when it becomes resident or not), and the city registers the part rather than the item.
- **The residency holds `Array[SceneryResidence]`**, so its loop over a copy of the list needs no Variant: a part
  outlives its owner while the residency holds it, and the freed-owner guard asks the part. `scenery_residency.gd`
  loses its opt-out line.
- **`scenery_resident` is gone** from all three kinds; the scenery ground's `chunks`, `pending` and `mode` go private
  behind `chunks()`, `pending()` and `mode()`, the city handing the mode in through `use_mode()`; the residency asks the
  frame record `is_on()`. Five lines leave `tools/field_reads.txt`.
- **Rejected**: three callables handed to `register()` per item, an adapter wrapping each kind's own flag, and a shared
  base class, which cannot exist since a building is a `StaticBody2D` and the home door a `Sprite2D`.
- **The queue item's paragraph on the residency goes**, and the files kept for a reason of their own are three;
  tall-llama's `scenery-loading.md` asks the ground's `chunks()` where it read the field.

## Verified

`tools/check.sh`, the field-read, test-only member, layer and typing checks and lint pass; the residency's, the
buildings', the ground's and the scenery suites pass; the three probes it edits are run before and after; CI is green.
