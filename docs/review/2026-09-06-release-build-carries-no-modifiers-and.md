**A release build carries no modifiers, and nothing has confirmed that on a real release build.**
`?telemetry=1` answers only when `OS.is_debug_build()` is true. The truth table is asserted in the
suites, so the *predicate* is proven; the build type itself has no seam to fake and is therefore
untested. **The deployed page is the first real check**, and what to watch is that it still starts
and still logs nothing.
