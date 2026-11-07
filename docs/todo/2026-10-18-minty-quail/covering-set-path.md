# The covering-set placement no row reaches

*Proposed, not asked for:* the orchestrator's, after the player's correction "why are there copies
on the other routes? we designed so that the event is placed dynamically" (inbox #1173 in gray-dolphin).

`EventScheduler._place_a_set_piece()` plans a one-shot at every site of a covering set and spends the
rest of its group once she meets one (`EventStreaming._spend_the_rest_of_the_group()`). No row of the
catalogue reaches it: the only one-shot, the burning building, is owed to her walk (`on_her_way`) and
sited dynamically on her way, and the stairwell's fire is placed by the building's plan. Its doc
comment still reads as live ("several fire engines"), which misled the orchestrator into describing
copies on every route to the player.

**Build:** confirm nothing reaches it (a scene recipe or a rig included), then delete it, its group
spending where nothing else uses it, and their comments.
