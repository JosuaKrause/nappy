## Gotchas learned in M37

- **A category in an enum is a list waiting to happen.** `Look.PERSON` was not a wrong value on any
  one row; it was a name that made "one more thing that is roughly a person" always the cheap
  answer, sixteen times over five names. When a field's values look like a taxonomy rather than
  like identities, ask what the *next* row will be tempted to reuse. Same shape as M34's
  `obstructs_radius` and worth recognising faster next time.
- **A second table of the same fact is where the fact goes wrong.** `DangerEdge._icon_for` and
  `EventInstance._draw_body` both answered "what does this look like", and the badge's copy was the
  one nobody looked at — so the cue whose entire content is *what is coming* had been showing a
  delivery van for a fire engine, an army truck and an abduction, with no test able to see it and
  no player having reached day 8 to notice. `EventInstance.icon_for()` is the one table now and the
  badge asks it.
- **Before fixing a comparison, ask whether it should be happening at all.** Finding 4's diagnosis
  was correct and pointed at a better sort. The actual fix is that buildings and entities can never
  legitimately be on opposite sides of each other — nothing walkable is inside a lot — so they do
  not sort against each other. A comparison that is *always* wrong in one direction is usually a
  comparison that should not exist.
- **A comment can outlive the thing it was true of by twenty-two milestones.** `building.gd` said
  the layout *"keeps every extrusion off the street, so the player is never hidden under a roof
  while walking past one"*. The first clause was true of the ground footprint and the second did
  not follow from it, and nothing ever re-read the sentence because the first half kept passing.
- **A decision that only exists inside `_draw()` cannot be asked about a moment.** M32 learned that
  a cue is a claim about a moment, and then wrote a new cue's placement as four lines inside a
  `_draw`, where no test could reach it — and that is exactly the one playtest 07 complained about.
  `Stroller.baby_cue_aside()` is those four lines with a name. The badge's `approach_speed` and
  `announces` are static functions for the same reason; this is that rule not being applied twice.
- **Art can be the thing deciding a gameplay number, and the catalogue can say so and still be
  wrong for a year.** `protest` obstructed one person's width with a comment explaining that the
  body may not claim ground the picture does not and that *"the art is the fix"*. It was right, it
  was written down, and it sat there because the fix looked like a drawing rather than a change.
- **A contact sheet is worth a screenshot rig.** Fourteen sprites judged one gameplay screenshot at
  a time is a day's work and mostly photographs of pavement. A throwaway scene that instantiates a
  real `EventInstance` per `Look` in a grid — real defs, real `_draw`, `process_mode` disabled and
  `age` set past the telegraph — takes ten minutes and shows every row at once, including the
  composites a texture viewer cannot. Deleted before committing, like a `test_zz_*` probe.
- **A `git worktree` for the before-and-after has one trap.** `.godot/` is gitignored, so a fresh
  worktree has no `class_name` registry and every typed line in the probe fails to parse — which
  looks like the probe being broken. Run `--headless --import` in it first. And delete the other
  suites in the throwaway worktree, or the comparison run costs six minutes of tests you are not
  reading.
