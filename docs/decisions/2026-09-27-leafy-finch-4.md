# leafy-finch-4 — The inbox's first filing · built 2026-10-03

*([dotted-quail](../playtests/2026-09-27-dotted-quail.md), statement 3: "you can use this to test the
implementation" · "as a first real test" · [velvet-otter](../playtests/2026-09-27-velvet-otter.md):
"the test of 423 shouldn't happen in a code PR" · the player, 2026-10-03, asked whether #423 goes
alone: "file everything in one PR")*

**Built (this filing PR).** The first real use of `tools/inbox.py`: every open note — #423 ("shadows
are misplaced"), #431, #432, #433, #434, #435, #436, #437, #442, #446, #447, #449, #450, #451 and
#459 — was copied word for word into one playtest file,
[minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), with the player's comments and each of
the day's answers after the question it answers; the queue was filed from it, one entry per note
that needs work (#446 was already built by silky-rabbit and files none); and the batch was closed
with `tools/inbox.py close --pr` right after the PR was pushed, as the inbox skill says. The
questions a note still leaves open are written into its entry and stay open for whoever picks the
task up (the player: "The questions come later after the ingestion is merged"). With this, the
leafy-finch entry has nothing left.
