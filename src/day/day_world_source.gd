class_name DayWorldSource
extends RefCounted
## Where the day director gets the world a spec is walked in (`DayDirector.start()`): asked to stand
## a spec's world (`DaySpec.world`), it answers that world standing, with her in it (`DayWorld`). A
## world is built the first time it is asked for and is the same world on every later ask, so a
## retried day or section walks the world it already has.
##
## The composition root implements it from what builds the worlds (`main`: the day's city, built at
## boot, and the escape's building and city, built as each section first begins); a test hands a
## fake answering a world of fakes. This base stands nothing.

## The world `spec` is walked in, standing, with her in it and her start in it worked out. Null from
## this base.
func stand(_spec: DaySpec) -> DayWorld:
	return null
