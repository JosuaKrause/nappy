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
- **A conversion of a field to a method shows a search for the field's old name in its pull request**, every remaining hit listed with its reason.
- **A method that replaces a yes-or-no field takes a name the field did not have.**
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
folder and file is in which layer; `tools/check_layers.py` holds the code to it in CI, and where this
list and the file differ, the file is what CI enforces and the list is corrected. No break of it
stands:

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

**No break of the map stands, and the rule outlives the list that held them** (inbox #1268 in
olive-ferret). A break that has to stand is the exception, and it is held in two places in the
pull request that adds it: listed in `tools/layer_map.py` (`EXCEPTIONS`, by file and by what it
names or fetches) with its reason, and declared in this section with the same reason. CI reads
only the map: a break not listed there fails, and so does a listed one that is gone, so the pull
request that fixes one deletes it from both. The declaration here is held by the review, through
**pr-review**'s architecture questions, and no check fails a break that is listed but not declared.

**The map lookup stays with the city maps in the model** (inbox #904 in freckled-moose), and a
record the map holds is placed on the map's layer as it appears. Each thing's own drawing is on the
layer of the thing it draws. A fix lands in the shared mechanism rather than a branch keyed
on one row's id or picture; new code follows these layers; a brief names the layer its work belongs
to.

**A legacy implementation never holds back a clean design** (minty-dolphin #852): the clean design
is established, and the old implementation is replaced, not kept beside it.

**Code that nothing reaches is deleted, not kept, and so is code that only serves a feature the game
no longer has** (inbox #1180 in gray-dolphin). It costs maintenance, and it misleads whoever reads it, an agent
included: a doc comment on unreached code reads as live behavior. A feature wanted back is built
fresh, which also makes it keep to the current principles. A member only tests read is
**writing-tests**' to rule on (the kept groups of
`tools/test_only_members.txt`), so "nothing reaches" does not delete one a test holds on purpose.
`tools/dead_code.py` lists the candidates.

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

**A method that replaces a yes-or-no field takes a name the field did not have**, on the object
the field was read from: in the events' design `is_finished` becomes `is_gone()` and `hard_fail`
becomes `ends_the_day()`. Under the field's old name a read left behind without its parentheses is
a reference to the function, always true in a condition. The field-read check fails it on a
receiver it types as a class under `src/`, and on a receiver whose class it cannot tell, such as a
Variant, unless its `--help` excuses the name; nothing reports it on a receiver typed too wide (a
`Node` holding the class; **godot**, "Types"). Under a new name the read left behind names nothing
and fails: at the parse on a typed receiver (the engine's `unsafe_property_access` is an error
everywhere), and when the line runs everywhere else (a receiver typed too wide, a Variant). The rule
stops at yes-or-no fields: a field of another kind can be read in ways that take a function as silently (a test against null, a
`match`, a lookup), and this rule does not cover it. One method that predates the rule keeps a
yes-or-no field's name, `EventDef.investigates()`, with no read of it left without parentheses.

**Every conversion of a field to a method, of whatever kind, shows one search in its pull request's
description** (inbox #1385 in silver-tapir): the field's old name read without parentheses, across
`src/`, `tests/` and `tools/` (`rg -P '\.old_name\b(?!\()' src tests tools`, or the equivalent), coming
back with no hit that reads this class's field from outside its file. The description lists every remaining
hit with its reason (another class's field of the same name, a write, a read inside the class's own file, a
comment), and only a read of this class's field from outside its file fails the step (the filer's proposal,
below). It finds the read a conversion missed at the cost of one command. A yes-or-no field's new
name makes the compiler find such a read; a field of another kind keeps its name, so a read left
behind is the silent function reference above, which the field-read check reports only in the
cases the paragraph above names.

**One check holds "Fields are not API".** `tools/check_field_reads.py` (CI's `gates` job) fails a
change that adds a read of another class's field. The list of reads that may stand,
`tools/field_reads.txt`, is empty and only shrinks; a read that only moved passes as the check's own
rules say (inbox #1350 in grassy-trout): its reader file renamed, code moved into a new file with no
more uses of that class's field, or an inner class lifted into a file of its own, whose reads the
list then gains as lines; the check cannot count those, so review reads a
lifting diff for a reader that is new. `project.godot` makes the engine fail an access it cannot
type: the warnings `untyped_declaration`, `unsafe_property_access` and `unsafe_method_access` are
errors. No file carries an `@warning_ignore` of them, since code is typed wherever the language can
type it (inbox #1280 in olive-ferret): CI's run of the check fails a file that does (**godot**, "Types",
owns that rule and says what the errors are and how a value is typed). In every file under `src/` the check fails a field's or a method's
name read through a receiver whose class it cannot tell, since the engine warns of nothing on a
property read off a Variant. In no file does it see a further read of a field its reader file is
already listed for, so review still reads the diff for those; which names it counts and the rarer
blind spots are in the text `uv run python tools/check_field_reads.py --help` prints.

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

- **No break of the layer map stands**: the design review's reading of the player's wish that no
  listed break be forgotten, which the player approved (inbox #1268 in olive-ferret). **That one
  that has to stand is listed in the map with its reason and declared in "Code is designed by
  layer" with the same reason, in the pull request that adds it** is the design's own addition,
  open to the player's correction; the player objected to marking what they had approved as only
  proposed (inbox #1268 in olive-ferret), so the two parts are told apart here.

- **Which layers there are**, apart from the two points the player decided, the observers and the
  view as siblings and the map lookup in the model (plush-kestrel).
- **A fix lands in the shared mechanism, new code follows the target shape, and a brief names its
  layer** (plush-kestrel).
- **The composition root above everything, and each thing's drawing on the layer of the thing it
  draws**, proposed by the layer map's builder (minty-quail-35). The player's words on the layers
  (inbox #904 in freckled-moose) decide the siblings and the map lookup, and name neither of
  these.
- **"A legacy implementation never holds back a clean design" covers an old path, a forwarder kept
  for an old name so callers or tests need not change, and a rule that holds only "in practice"**,
  the filer's reading of minty-dolphin #852, whose words are general: not to let legacy
  implementations prevent a clean design.
- **A member a test holds on purpose is not deleted as unreached**, a reading of inbox #1180 in
  gray-dolphin.
- **One interface and composition for anything many classes use, not only events**, a reading of
  inbox #1173 in gray-dolphin.
- **Which members "Fields are not API" covers**, a reading of inbox #1173 in gray-dolphin.
- **A method that replaces a yes-or-no field takes a name the field did not have** ("Fields are not
  API"): the orchestrator's proposal (minty-quail-coral-trout). The events' interface design has
  it; that it holds for every conversion is the orchestrator's. The player's words on fields
  (inbox #1173 in gray-dolphin) say nothing of a method's name. The plainer alternative is the
  field's name kept, with a read a conversion misses staying true and unreported.
- **Every conversion's pull request shows a search for the field's old name read without
  parentheses, coming back empty, whatever the field's kind** ("Fields are not API"): the player's
  (inbox #1385 in silver-tapir); the new-name rule above stays at yes-or-no fields.
- **What a hit of the search means**: every remaining hit is listed with its reason, and only a read of
  this class's field from outside its file fails the step. The filer's proposal (inbox #1385 in silver-tapir),
  since the player's "yes" answered the step as "coming back empty", which a name shared by several classes
  cannot do.
- **New code reads no field across objects, and a touched read moves behind a method**
  (inbox #1173 in gray-dolphin).
- **Which moves count as a read that only moved** (a reader file renamed, a new file with no more
  uses, an inner class lifted out), the planning agent's proposal (minty-quail-breezy-bison). That
  such a read passes the field-read check and the list gains its lines is the player's
  (inbox #1350 in grassy-trout).
- **A design where a fake has nothing to be handed to is wrong** (inbox #1156 in gray-dolphin).
- **What no caller would miss goes** (inbox #1156 in gray-dolphin).
