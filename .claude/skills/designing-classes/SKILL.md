---
name: designing-classes
description: How a class and its collaborators are shaped — the player's principles, the layers and which way a dependency may point, dependency injection, a mode as configuration, and derived state held by one object that derives it once and is handed around. Load this BEFORE designing or changing a class under src/, or writing a brief that does.
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
passed around; nothing derives it again** (inbox #1156). One object holding the answer removes the
private methods that each re-derive it and the risk that two of them resolve it differently.

- **How the game is stored is free, as long as one unified reader has the job of deriving the
  current state from it** (inbox #1156). A save file and a save state are not necessarily the same
  thing: the reader is what derives the current state from whatever is stored.
- **That is encapsulation and isolation** (inbox #1156): the stored form is the reader's own
  business, and everything else asks the reader.
- **A state object's interface is chosen from what its readers want out of it** (inbox #1156):
  explore what the tests that build the real objects today want to get out of them, and use that to
  inform the design of the state object; then mock that out.
- **A class is named for what a caller gets out of it, not for how it is built** (inbox #1156).
- **The resulting objects are injectable, so a test mocks them** (inbox #1156), and a suite that is
  not about them hands in a fake holding the answers it needs (**writing-tests**).
- **A fact derived in more than one place is a code smell to look for** (inbox #1156): the same
  reading of raw data written twice, or a private method working out what another place already
  has. Its fix is the one object above.
- *Proposed by the filer, open to overturn:* a design where a fake has nothing to be handed to is
  wrong. Where a test can reach a reading only by building the real objects it reads from, the
  reading becomes a public piece of its own that is handed the object, and its test hands it a fake.

## Overrides say so

An override of a project class's method carries the doc comment line **godot**'s "Code style"
names, `## Overrides Class.method.` (inbox #1154).
