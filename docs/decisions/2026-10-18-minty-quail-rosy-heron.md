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
asks; the suites that ask it of many places (`tests/contact_touches.gd`) ask the day's own contact
directly, so the contact as the day shaped it is what is measured. Its only other reader is its own
class, so it has a line in the kept group of `tools/test_only_members.txt`, whose reason says no other
game code asks a contact that question. The swing's test derives its places from the frame's shadow and asks the
contact about them. `ContactTouches` is a plain function now, with no node argument to wait on.

**What checks the hand-ins.** A node handed its library through `use_atlas()` keeps it private, so
a suite reads what each asked of the library it was handed, through `tests/recording_atlas.gd`, an
`AtlasLibrary` that counts which script called `acquire()`:
- `test_atlas_boot` boots over a recording sitting library and requires every help text and mode
  button standing to have asked it (the screens' four `use_atlas()` calls in `main.gd` each fail it
  when removed); the nodes still holding a public `atlas` are checked as before, and their holders
  threshold is 5, not 10, since the screens' nodes moved to `use_atlas()` and are counted by the
  new checks instead;
- `test_park_cordon` hands a cordon a recording library and requires each officer, piece of tape and
  post to have asked it (the three `use_atlas()` calls in `park_cordon.gd` each fail it);
- `test_resistance_arrow` hands a director one and requires its contact to have asked it;
- `test_atlas_stroller_crowd` requires every agent the crowd makes to draw a region from the
  crowd's library.
Removing each hand-in in turn failed the check named for it.

Tests that read the plan follow: `test_interior` and its siblings ask the plan through the new
methods (its check that no tile needs collision cleared walks the plan's tiles).

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
