# minty-quail — Atlas, cordon setup and the interior plan go behind methods (minty-quail, field-reads) · 2026-11-08

The second step of the field-reads conversion outside the city, events and routes, on top of the
first (the record dappled-bunny). It follows the readings the orchestrating session gave for what
the first record left open (inbox #1173 in gray-dolphin: "fields are not API interaction between
different objects need to go through APIs"; open to the player's overturn). 42 more lines of
`tools/field_reads.txt` are gone: `InteriorMapPlan` 23, `ContactPoint` 6, `CordonTape` 4,
`CrowdAgent` 3, `ModeButton` 3, `HelpText` 2, `CordonOfficer` 1. No behaviour change.

## What was done

- **The atlas is handed in once, by a method.** `HelpText`, `ModeButton`, `CordonTape`,
  `CordonOfficer`, `ContactPoint` and `CrowdAgent` keep their library in an underscore field and take
  it from `use_atlas(library)`, which the creator calls once. A node built in code from a scene
  (the title's buttons, the HUD's help text) is set up by that call rather than a constructor
  argument, since the scene instantiates it. `CrowdAgent.picture_region(name)` answers the look's
  question, so the looks no longer read the agent's library.
- **A node's configuring writes are one setup call.** `CordonTape.set_out(piece, across, length)`
  replaces three writes; `ContactPoint` takes `complete_by_crossing()`, `complete_within(reach)`
  and `complete_on_ellipse(semi)`, and answers `touch_reach()`, `task_step()` and `is_finished()`.
- **`InteriorMapPlan` is painted and asked through methods.** Its twelve fields are private; the
  builder (`InteriorMap`) paints with `paint_floor`, `paint_wall`, `open_wall`, `paint_decal`,
  `add_waypoint`, `add_door`, `lock_threshold`, `add_entrance`, `add_corridor_narrow`,
  `add_collision_clearance`, `put_rubble_on`, `start_on` and `exit_on`, and the scene asks with
  `floor_tiles`, `floor_kind_at`, `wall_tiles`, `wall_kind_at`, `decal_tiles`, `door_ids`,
  `start_position`, `exit_position`, `rubble_area` and the like. A kind asked of a tile with none is
  `NONE`, as the plan's own lookups already read it.

`ContactPoint.would_complete_at(her)` is the contact's own pure touch question, which its physics frame
asks; the suites that ask it of many places (`tests/contact_touches.gd`) now ask the day's own contact
directly instead of a re-shaped twin, so the contact as the day shaped it is what is measured. Its only
other reader is its own class, so it is a line of `tools/test_only_members.txt`'s kept group, with that
reason. The swing's test derives its places from the frame's shadow and asks the contact about them.
The atlas boot test no longer reads a private library by string: it checks the nodes that still
hold a public one, and a new test in `test_atlas_stroller_crowd` checks that every agent the crowd
makes draws a region from the crowd's library (it fails, 0 of 234, when the hand-in is removed).

Tests that read the plan or the atlas follow: `test_interior` and its siblings ask the plan through
the new methods (its check that no tile needs collision cleared walks the plan's tiles), the
atlas boot test finds a node's library under either name, and the contact twin is shaped the way
the director shapes a contact (`_shape_the_touch`) with the live one's reach copied.

## Not done

- **`LaneMover` and `LaneStrategy` (about 63 lines)**: the reading is a narrow interface the mover
  builds and hands each strategy, with methods named for what the strategies ask. About 330 uses of
  the mover's fields in the two strategies would each become a call, in the code that runs for
  every agent every frame, so it needs a measurement of the crowd's per-frame cost with it; not
  attempted here.
- **`RunState`'s parts (about 75 lines)**: methods `header()`, `calendar()` and the parts' own
  `day()` and the like cannot share a name with the vars they replace, so each var is renamed, and
  `main.gd`, `day_director.gd` and the tests read them directly. The fence on the third hand-ins
  pull request's files keeps this until it has merged.
- **`BlockedLayer` (5 lines)**: its readers are `CityMap`'s property wrappers in `src/city/`, the
  city conversion's files; methods without their callers would be unreached code.
