# The pictures not taken, each with what would stage it

Each line is a picture the end remeasure's evidence README lists as not taken, with what would stage it.

- **Overlapping badges** (minty-quail-15): several chasing events off one screen edge. A scene recipe's
  `setup.events` takes several pinned rows, each with a world `at` and a `charging` flag; what
  stops a second charging dog or a fire engine off one edge is ordinary placement
  (`EventScheduler.recipe_placement()`, the director's siting for a non-map row) and the per-day cap.
  Read, not tried. A recipe whose rows pass those rules, or a recipe field that waives placement for
  a scene, would stage it.
- **A departure round a building, the neighbor at a barricade, a walk-back round a body**
  (minty-quail-5): each needs a solid in a mover's way. A recipe places events at production sites, and
  no flag puts a body on a mover's route; a recipe field that places a solid by world position would
  stage them.
- **The halo and the debug view over the tunnel's dark, and the warning guard in the escape's city**
  (minty-quail-6): `--spawn` is ignored on the escape city's boot and a raised meter showed no
  halo. A spawn point or a walk script that works on the escape's city would stage them.
- **The cordon's taper and the escort beside the street musician** (minty-quail-9):
  `scene-recipes/task-12-swing.json` ends 0.7 s after the swing and `--press` conflicts with a
  recipe. A recipe that plays on past the swing and takes a burst would stage them.
- **The walking bob and the arrow field's and officers' stepping at 30 Hz** (minty-quail-21, -26): a
  burst's frames are about 83 ms apart. `tools/record.sh` writes 60 frames a second but turns
  physics interpolation off, so a recording shows the tick's stepping and not the interpolated
  drawing -21 is about; it was not tried for the arrow field and officers.
- **The escape city's sealed home door** (minty-quail-8): no flag or recipe field sets the
  `sealed_door` scar (a recipe's `setup.progression` accepts only `blackout` and `escape_part`). A
  progression field for the scar would stage it.
- **The epilogue** (minty-quail-4): `RouteRig` quits the game at any day ending, so a route run never
  shows it. A rig that walks her to the exit and stays up, or a flag that opens the epilogue, would
  stage it.
- **From minty-quail-7: the mark over her head in the stairwell, and the masked man leaving round the
  walls at the top of the shaft**: no burst of the route rig caught either; a longer or retimed burst
  of the same run would.
