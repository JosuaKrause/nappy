# Tuning holds shared balance numbers only, and its checks fail the build

`src/autoload/tuning.gd` holds 261 constants, 141 of them used by exactly one file; it also holds
logic (`falloff`, `field_eccentricity`, `field_scale`, `offscreen_lead`, `pursuit_standoff`,
`braking_distance`) and the fairness validators (`validate_traffic`, `validate_signals`,
`validate_pursuit`, near 2109-2580), which run in `Tuning._ready()` and only `push_error` and return
false, so an unfair number ships with a console line.

**Build:** constants used by one owner move to it; the field maths into a static `Field` class; the
validators into a test suite that fails CI. Read **balance** before moving any number a player can
feel; nothing changes value.
