class_name AbductionSpec
extends Resource
## **The unmarked van takes somebody first** (`EventDef.abduction`, `EventAbduction`): the first time
## she comes close enough to see it, a bystander is walked to the van and taken. Drawing and
## telemetry only — nothing here reaches into the crowd, and nothing here changes the van's field.
## The hunting copies carry the same take (`EventDef.at_heat()` keeps it), which stops the moment
## the van notices her.

## How long the walk to the van takes once it starts, in seconds.
@export var taken_over := 2.5
## How far to the side of the van the bystander stands before the walk begins, in px.
@export var standing_offset := 32.0
