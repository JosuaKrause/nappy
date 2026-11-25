# Playtest silver-tapir — naming-rule-everywhere: keep the search step

2026-11-11.

## #1385

1. **Context** (the assistant's):

   The player's answer on the Nappy board, question naming-rule-everywhere ("when the refactor puts a field behind a method, how far beyond yes-or-no fields should 'the method gets a new name' go?"), on the You line under the orchestrator's reply. The player had answered "A" (stop at yes-or-no fields) in an earlier batch, filed with #1356. The reply answered here, as shown:

   "A taken: the new name stays a yes-or-no field's rule, and no accessor of the events' design is renamed. One part left: my pick added a step, each conversion's pull request showing a search for the old name read without parentheses coming back empty (one command, finds the read a conversion missed). Keep that step? Nothing is written into a rule until you say."

   The pick it refers to, as shown: "A, plus one step in every conversion: its pull request shows a search for the old name read without parentheses coming back empty. That covers the read a conversion misses at the cost of one command, without renaming the design's accessors."

2. **The note.**

   > yes

3. **Read as:** (the assistant's interpretation, not the player's words)

   The step is kept: every pull request that puts a field behind a method shows, in its description, a search for the field's old name read without parentheses coming back empty, whatever the field's kind. It goes into designing-classes beside "A method that replaces a yes-or-no field takes a name the field did not have", whose rule otherwise stays at yes-or-no fields, and into the conversion briefs from then on; written at the next skill or queue update.
