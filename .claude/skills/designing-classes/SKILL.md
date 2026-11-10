---
name: designing-classes
description: How a class and its collaborators are shaped — the player's principles, the layers and which way a dependency may point, dependency injection, a mode as configuration, derived state held by one object that derives it once and is handed around, how an API's quality is checked, and how an interface and its implementations are named. Load this BEFORE designing or changing a class under src/, or writing a brief that does.
---

# Designing classes

- **A layer depends only on the layers below it**: data, model, world, simulation, flow, observers and view side by side, root.
- **A lower layer tells a higher one what happened by an event or a callback it was handed**, never by calling it.
- **A component is handed what it depends on**, never fetching it from an autoload, a group or a static, so a test hands it a fake.
- **A mode is a configuration of the shared code, never a copy of it.**
- **Fields are not API**: one object reaches another only through its methods.
- **A receiver has a class the engine and the field-read check can tell**: a new file is typed from its first line.
- **An event is asked through one interface**, and an ability is a part it is composed of, never a subclass.
- **A fact derived from stored data lives in one object that derives it once** and is handed around.
- **Code nothing reaches is deleted.**
- **A pull request that changes code answers the architecture questions.**

## Code is designed by layer

**Every design, brief and change keeps to the player's principles** (minty-lemur #785, #796):
separation of concerns, composability, cohesion, low coupling and a layered architecture, with
**dependency injection** for modular, testable code (minty-lemur #794). A layer depends only on the
layers below it, through their interfaces, and tells a higher one what happened by an event or a
callback it was handed, never by calling it; a component is handed what it depends on rather than
fetching it from an autoload, a group or a static, so a test hands it fakes. A mode, the escape
included, is a configuration of the shared code, never a parallel copy of it (minty-lemur #785).

**The layers, lowest first, are the ones `tools/layer_map.py` lists**, the file that says which
folder and file is in which layer; `tools/check_layers.py` holds the code to it in CI, and the list
of breaks standing there only shrinks:

1. **data**: data and configuration. The catalogue, the balance numbers, the run's configuration,
   the specs, the on-screen texts, the art's pages and the value types the rows are written in.
2. **model**: the domain model, pure state and plans with no scene of their own. The map and its
   lookup (`WorldMap` and its records), its generation, the routes, the closures, the run's
   sub-states.
3. **world**: the navigator, passability, the draw layers, and the scene nodes that draw the
   world's own ground and furniture.
4. **simulation**: everything that moves or happens (her, the baby, the crowd, the events, the
   resistance), and the drawing of each.
5. **flow**: run flow. A day started and finished from its spec, and the screens' order.
6. **observers** and **view**, siblings at one level, neither above the other and neither naming
   the other (inbox #904 in freckled-moose). The observers only listen: the run log, GoatCounter,
   the save, the developer's readouts. The view is the screen's own furniture: the HUD, the
   screens, the badges, the controls.
7. **root**: the composition root, above everything. `main.gd`, which builds every layer and hands
   each what it needs, and the developer's rigs.

**The map lookup stays with the city maps in the model** (inbox #904 in freckled-moose), and a
record the map holds is placed on the map's layer as it appears. Each thing's own drawing is on the
layer of the thing it draws. The refactor entry (minty-quail, one engine: the codebase refactored
by layer) files the same seven layers in its README, under "The layering the code is moved to";
where that list and `tools/layer_map.py` differ, the file is what CI enforces and the list is
corrected. A fix
lands in the shared mechanism rather than a branch keyed on one row's id or picture; new code
follows the target shape and adds nothing to the divergence the refactor entry lists; a brief names
the layer its work belongs to.

**The one exception to this whole section** is a minimal fix the queue orders
before the refactor, which names itself as the exception in its entry, and **it holds only until the
refactor**: the refactor replaces the code the fix touched, and the PR that closes the refactor entry
removes the exception from this section, so it never outlives that PR (minty-lemur #799).

**Code that nothing reaches is deleted, not kept, and so is code that only serves a feature the game
no longer has** (inbox #1180 in gray-dolphin). It costs maintenance, and it misleads whoever reads it, an agent
included: a doc comment on unreached code reads as live behavior. A feature wanted back is built
fresh, which also makes it keep to the current principles. A member only tests read is
**writing-tests**' to rule on (the kept groups of
`tools/test_only_members.txt`), so "nothing reaches" does not delete one a test holds on purpose, and
the exception above, for a minimal fix ordered before the refactor, does not reach this rule.

**An event is asked through one consistent interface** (inbox #1173 in gray-dolphin). A caller uses it without
knowing its details: it never reads an event's settings or fields to work out an answer the event can
give itself, and callers never filter the raw list of the day's event plans themselves, since the
interface is there to carry that question. This holds for every aspect of events, not only the one a
change is about. An ability an event has is a part it is composed of, never a subclass: composition
over inheritance (inbox #1173 in gray-dolphin). The same
holds for anything many classes use.

**Fields are not API** (inbox #1173 in gray-dolphin). One object never reads or writes another object's fields: every
interaction between objects goes through the other's methods, so a stored field can become a
computation without any of its readers changing. The calls are methods rather than GDScript
properties because a property and a plain field look the same where they are read, and GDScript has
no private fields, only the underscore convention; only a method call shows a reader that a member is
API, and it is the form a script could tell apart. A property is used only inside its own class (inbox #1173 in gray-dolphin). The
rule covers the vars that classes under `src/`
declare; it does not cover an engine object's properties (`position`, `visible`, the tree's
`paused`, as **godot** uses them) or constants and enums (`Tuning.X`). New code does not read a
field across objects, a change that touches such a read moves it behind a method, and state another
class needs is kept in an underscore field behind a method.

**A method that replaces a yes-or-no field never takes the field's name**: `is_finished` becomes
`is_gone()`, `hard_fail` becomes `ends_the_day()`. A read left behind without its parentheses
then names nothing and fails, at the parse on a typed receiver and when the line runs on a
Variant. Under the field's old name it would be a reference to the function, which is always
true in a condition, and nothing reports that on a receiver whose class is known (**godot**,
"Types"). A number or any other value may keep its name (`speed()`), since a function used as a
number fails at once.

**Two lists hold the rule while `src/` is converted, and each only shrinks.** Much of `src/` still
reads fields across objects: `tools/check_field_reads.py` (CI's `gates` job) fails a change that
adds a reader file's first read of another class's field, today's being listed in
`tools/field_reads.txt`, and a change that converts a file's last read of a field deletes its line.
The second list is what makes the check see every read (inbox #1268 in olive-ferret), since a read through a
receiver whose class nothing can tell is a read no list holds. `project.godot` makes the engine
fail an access it cannot type: the warnings `untyped_declaration`, `unsafe_property_access` and
`unsafe_method_access` are errors. A file not yet typed carries one `@warning_ignore_start(...)`
line at its top naming the warnings it still trips, and the files carrying it are that second list:
a module's pass types its receivers and deletes the line, a new file never carries it, since code
is typed wherever the language can type it (inbox #1280 in olive-ferret), and CI's run of the check fails a file
that gains it (**godot**, "Types", owns that rule and says what the errors are and how a value is
typed). In a file under `src/` without the line, the check fails a field's or a method's name
read through a receiver whose class it cannot tell, since the engine warns of nothing on a
property read off a Variant; in a file with the line it skips such a read, and its `--summary`
counts the files and the skipped uses. In no file does it see a further read of a field its reader
file is already listed for, so review still reads the diff for those; which names it counts and
the rarer blind spots are in the text `uv run python tools/check_field_reads.py --help` prints.

**Every pull request that changes code answers the architecture questions** in
**pr-review**'s `references/architecture-questions.md`, so the layering does not drift once the
refactor is done (plush-egret #892): its layer, its dependencies, what it is handed and what it
fetches, what it reuses, where a fix lands, how a test builds it, and the docs that say where it
lives. A brief asks for them; the builder answers them in its report and under the description's
`## Architecture questions`; CI checks they are there and the reviewer that they are true.

## Derived state lives in one object, derived once

**A fact worked out from stored data lives in an object that derives it once, and that object is
passed around; nothing derives it again** (inbox #1156 in gray-dolphin). One object holding the answer removes the
private methods that each re-derive it and the risk that two of them resolve it differently.

- **How the game is stored is free, as long as one unified reader has the job of deriving the
  current state from it** (inbox #1156 in gray-dolphin). A save file and a save state are not necessarily the same
  thing: the reader is what derives the current state from whatever is stored.
- **That is encapsulation and isolation** (inbox #1156 in gray-dolphin): the stored form is the reader's own
  business, and everything else asks the reader.
- **A state object's interface is chosen from what its readers want out of it** (inbox #1156 in gray-dolphin):
  explore what the tests that build the real objects today want to get out of them, and use that to
  inform the design of the state object; then mock that out. It is judged and named as any
  interface is (below).
- **The resulting objects are injectable, so a test mocks them** (inbox #1156 in gray-dolphin), and a suite that is
  not about them hands in a fake holding the answers it needs (**writing-tests**).
- **A fact derived in more than one place is a code smell to look for** (inbox #1156 in gray-dolphin): the same
  reading of raw data written twice, or a private method working out what another place already
  has. Its fix is the one object above.
- **A design where a fake has nothing to be handed to is wrong.** Where a test can reach a reading
  only by building the real objects it reads from, the
  reading becomes a public piece of its own that is handed the object, and its test hands it a fake.

## An interface is judged by its callers

An API's quality is checked by these tests (inbox #1156 in gray-dolphin):

- would any caller miss a method, an argument or a field if it were removed? What nobody would
  miss goes;
- can the implementation underneath be swapped without breaking the interface?

Three distinct implementations are a good sign that an API is robust, as a rule of thumb and not a
requirement: nothing adds implementations to reach three (inbox #1156 in gray-dolphin). A fake or a mock is not an
implementation for either the swap test or that count: it only looks up what the API should return
in the situations its test sets, and gives no meaningful answer outside them (inbox #1156 in gray-dolphin).

**An interface, base class or abstract class is named for what a caller gets out of it, not for how
it is built, and a concrete implementation is named for what the implementation is** (inbox #1156 in gray-dolphin).

## Overrides say so

An override of a project class's method carries the doc comment line **godot**'s "Code style"
names, `## Overrides Class.method.` (inbox #1154 in gray-dolphin).

## Proposed, not asked for

These rules above are the filer's or the builder's proposals and readings, not the player's words,
and hold until the player corrects them. An entry cites the player's word it extends or the record
that proposes it, and says so where the player's words name nothing on the point:

- **Which layers there are**, apart from the two points the player decided, the observers and the
  view as siblings and the map lookup in the model (plush-kestrel).
- **A fix lands in the shared mechanism, new code follows the target shape, and a brief names its
  layer** (plush-kestrel).
- **The composition root above everything, and each thing's drawing on the layer of the thing it
  draws**, proposed by the layer map's builder (minty-quail-35). The player's words on the layers
  (inbox #904 in freckled-moose) decide the siblings and the map lookup, and name neither of
  these.
- **A member a test holds on purpose is not deleted as unreached, and the minimal-fix exception
  does not reach the deletion rule**, a reading of inbox #1180 in gray-dolphin.
- **One interface and composition for anything many classes use, not only events**, a reading of
  inbox #1173 in gray-dolphin.
- **Which members "Fields are not API" covers**, a reading of inbox #1173 in gray-dolphin.
- **A method that replaces a yes-or-no field never takes the field's name** ("Fields are not
  API"): the orchestrator's proposal, taken from the events' interface design and widened to every
  conversion (minty-quail-busy-heron); the player's words on fields (inbox #1173 in gray-dolphin)
  say nothing of a method's name. The plainer alternative is the field's name kept, with a read a
  conversion misses staying true and unreported.
- **New code reads no field across objects, and a touched read moves behind a method**
  (inbox #1173 in gray-dolphin).
- **The check fails an unknown receiver file by file, from the day a file loses its opt-out line**,
  the builder's choice (minty-quail-busy-heron). The player's words ask that the check be made to
  work and approve the design review's way to do it (inbox #1268 in olive-ferret), and that design has the check
  fail an unknown receiver only once no file carries the line.
- **A design where a fake has nothing to be handed to is wrong** (inbox #1156 in gray-dolphin).
- **What no caller would miss goes** (inbox #1156 in gray-dolphin).
