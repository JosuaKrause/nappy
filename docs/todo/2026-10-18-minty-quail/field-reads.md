# Every read of another object's fields goes through its methods

**The ask.** On the board's events-one-interface, asked whether "all aspects of events" means a pass
of its own over every place that still reads an event's details: "yes. also never read fields
directly. always read through a method (does gd support python style properties?) so you can swap
out a field with a computation if needed. fields are not API interaction between different objects
need to go through APIs" (inbox #1173 in gray-dolphin). On api-methods-or-properties, "yes" to methods across
objects and a property only inside its own class (inbox #1173 in gray-dolphin).

**Read as:** the rule is designing-classes' ("Fields are not API", "An event is asked through one
consistent interface"). This item is the survey and the conversion of the code that predates it,
events first: outside `src/events/`, 20 files under `src/` read an event definition's settings
directly (its body's width, whether it holds her again, how long, whether it ends the day), and many
more classes read each other's fields. It comes after the hand-ins (`city-hand-ins.md`), which move
many of the same reads.

*Proposed, not asked for:* a design on the board first, listing the reads by class and the methods
that replace them, then one pull request per area.

**Open on the board, not blocking** (each pick runs unless the player answers otherwise):

- **tests-read-fields:** whether a test counts as another object, so it too reads through methods.
  Pick: yes.
- **field-read-check:** whether a script fails a change that adds a read of another class's plain
  field, with today's reads in a list that only shrinks, as the test-only-members list does. Pick:
  yes.
