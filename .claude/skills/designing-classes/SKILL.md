---
name: designing-classes
description: How a class and its collaborators are shaped — the player's principles, the layers and which way a dependency may point, dependency injection, a mode as configuration, derived state held by one object that derives it once and is handed around, how an API's quality is checked, and how an interface and its implementations are named. Load this BEFORE designing or changing a class under src/, or writing a brief that does.
---

# Designing classes

## Code is designed by layer

**Every design, brief and change keeps to the player's principles** (minty-lemur #785, #796):
separation of concerns, composability, cohesion, low coupling and a layered architecture, with
**dependency injection** for modular, testable code (minty-lemur #794). A layer depends only on the
layers below it, through their interfaces, and tells a higher one what happened by an event or a
callback it was handed, never by calling it; a component is handed what it depends on rather than
fetching it from an autoload, a group or a static, so a test hands it fakes. A mode, the escape
included, is a configuration of the shared code, never a parallel copy of it (minty-lemur #785).

**Code that nothing reaches is deleted, not kept, and so is code that only serves a feature the game
no longer has** (inbox #1180 in gray-dolphin). It costs maintenance, and it misleads whoever reads it, an agent
included: a doc comment on unreached code reads as live behavior. A feature wanted back is built
fresh, which also makes it keep to the current principles. *Read as, the filer's reading and not the
player's words:* a member only tests read is **writing-tests**' to rule on (the kept groups of
`tools/test_only_members.txt`), so "nothing reaches" does not delete one a test holds on purpose, and
the one exception below, for a minimal fix ordered before the refactor, does not reach this rule.

**An event is asked through one consistent interface** (inbox #1173 in gray-dolphin). A caller uses it without
knowing its details: it never reads an event's settings or fields to work out an answer the event can
give itself, and callers never filter the raw list of the day's event plans themselves, since the
interface is there to carry that question. This holds for every aspect of events, not only the one a
change is about. An ability an event has is a part it is composed of, never a subclass: composition
over inheritance (inbox #1173 in gray-dolphin). *Read as, the filer's reading and not the player's words:* the same
holds for anything many classes use.

**Fields are not API** (inbox #1173 in gray-dolphin). One object never reads or writes another object's fields: every
interaction between objects goes through the other's methods, so a stored field can become a
computation without any of its readers changing. The calls are methods rather than GDScript
properties because a property and a plain field look the same where they are read, and GDScript has
no private fields, only the underscore convention; only a method call shows a reader that a member is
API, and it is the form a script could tell apart. A property is used only inside its own class (inbox #1173 in gray-dolphin). *Read as,
the filer's reading and not the player's words:* the rule covers the vars that classes under `src/`
declare; it does not cover an engine object's properties (`position`, `visible`, the tree's
`paused`, as **godot** uses them) or constants and enums (`Tuning.X`). Much of `src/` still reads
fields across objects: `tools/check_field_reads.py` (CI's `gates` job) fails a change that adds such a read, today's being listed in `tools/field_reads.txt`, a list that only shrinks, so a change that touches a listed read deletes its line. *Proposed by the filer, open to the player's correction:* new code does not,
a change that touches such a read moves it behind a method, and state another class needs is kept in
an underscore field behind a method.

*Proposed by the filer, open to overturn (plush-kestrel):* the target layers are minty-quail's (data
and configuration; the domain model; the world; simulation; run flow; observers); a fix lands in the
shared mechanism rather than a branch keyed on one row's id or picture; new code follows the target
shape and adds nothing to the divergence the open refactor entry lists; a brief names the layer its
work belongs to. **The one exception to this whole section** is a minimal fix the queue orders
before the refactor, which names itself as the exception in its entry, and **it holds only until the
refactor**: the refactor replaces the code the fix touched, and the PR that closes the refactor entry
removes the exception from this section, so it never outlives that PR (minty-lemur #799).

**Every pull request that changes code answers the architecture questions** in
**pr-review**'s `references/architecture-questions.md`, so the layering does not drift once the
refactor is done (plush-egret #892): its layer, its dependencies, what it is handed and what it
fetches, what it reuses, where a fix lands, how a test builds it, and the docs that say where it
lives. A brief asks for them; the builder answers them in its report and under the description's
`## Architecture questions`; CI checks they are there and the reviewer that they are true.
**Which folder and file is in which layer is `tools/layer_map.py`**, which `tools/check_layers.py`
holds the code to in CI; the list of breaks standing there only shrinks. *Proposed by its builder,
open to overturn:* the composition root (`main.gd` and the developer's rigs) above everything, and
each thing's own drawing on the layer of the thing it draws. *Two departures from minty-quail's
filed layering, decided by the player* (inbox #904 in freckled-moose): the view (the HUD, the screens, the badges, the controls) and the observers are **siblings at one level**,
neither above the other and neither naming the other, where minty-quail's README puts the UI inside
the observers; and the map lookup (`WorldMap` and its records) stays **with the city maps in the
domain model**, a correction to minty-quail's item 3, which puts one map interface in the world. A
record the map holds is placed on the map's layer as it appears.

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
- *Proposed by the filer, open to overturn:* a design where a fake has nothing to be handed to is
  wrong. Where a test can reach a reading only by building the real objects it reads from, the
  reading becomes a public piece of its own that is handed the object, and its test hands it a fake.

## An interface is judged by its callers

An API's quality is checked by these tests (inbox #1156 in gray-dolphin):

- would any caller miss a method, an argument or a field if it were removed? *Proposed by the
  filer, open to overturn:* what nobody would miss goes;
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
