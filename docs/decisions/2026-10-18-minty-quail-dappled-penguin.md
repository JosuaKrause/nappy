# minty-quail — The pursuits' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The pursuits' four suites are typed and lose their opt-out line**: `test_events_pursuit`,
  `test_pursuer_on_foot`, `test_event_behaviours` and `test_events_chat`. Loop variables carry their
  element's type, and a saved behaviour's answer is read through a typed `Dictionary` local. No
  line under `src/` changed and no rig was edited.
- **The chat suite frees its two cast members one by one**: a typed loop over the pair failed the
  shard when one of them was already freed, so each is checked with `is_instance_valid()` and freed
  alone.

## Left, each with its reason

- **Search: none.** No class was this pass's to search: the row's, the live event's, the plan's and
  a pursuit's fields are `event-interface.md` row 4a's scripted rewrite, so no read was converted.
- **Other modules' fields stay for their passes.** Pull request #1360's description lists them by
  class, inner classes and the pursuit, notice and abduction records included, each with the method
  the game calls or "no method".

## Verified

The four suites pass, `tools/typing_census.py --check` holds, and the field-read check passes. No
check was deleted or moved.
