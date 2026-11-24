# No suite checks a standing event's physics body against the map's record

**The gap.** The map records the tiles a standing event blocks, and the event's physics body is what stops the stroller and the crowd. Nothing compares the two. The check "a body and its record are one footprint" in `tests/test_world_passability.gd` (`_test_a_body_and_its_record_are_one_footprint`) reads only the record and the laid-out pieces. For each planned event it builds the record's footprint from the plan (`EventSpawner.footprint_of(BodyStance.of(...))`), builds an `EventInstance` from the same plan, lays its standing pieces' shapes into a second `Footprint`, and compares the two tile lists. The instance's physics body is never read, so despite its name the check says nothing about the body the engine collides with.

**The break that shows it.** Making the physics body ignore its piece's direction (its axis) passes every suite, on this branch's base and on main: the record and the laid-out pieces still agree, and the body, which is the one that is wrong, is not read. Found by the review of pull request 1721 (https://github.com/JosuaKrause/nappy/pull/1721#pullrequestreview-6047484812).

**Two ways a fix could go.** Neither is picked here.

- **A check that reads the body.** The suite lays down the tiles the instance's physics body covers (its collision shapes, placed and turned as the engine has them) and compares them with the record's tiles, so the break above fails it.
- **Rename the check to what it reads.** The check keeps its comparison and is named for it (the record against the pieces' own footprint), and its comment says that the physics body is not compared, so a reader is not told more than the check does.

**Shown fixed.** Either the break above is tried and a suite fails on it, or the check's name and comment say what it reads and no sentence claims the body is compared.
