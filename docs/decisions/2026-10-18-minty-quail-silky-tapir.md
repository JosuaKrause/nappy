# minty-quail — The crowd is handed its settings through methods and LaneMover.kind goes private · 2026-11-24

**Built.** The simulation builder tells the crowd what it is equipped with through two calls,
`Crowd.equip(screen, frame_timing, library)` (what the screen shows, the frame record's sink, the
baked atlas pages) and `Crowd.leave_out(drawing, motion)` (`--skip crowd` and `--skip motion`),
named as `City.leave_out()` is. The five fields they set (`view`, `timing`, `atlas`,
`skip_motion`, `skip_agent_drawing`) are private. `LaneMover.kind` is private (`_kind`): an agent
is made of its kind (`CrowdAgent.new(kind)`, the crowd's `_make_an_agent(kind)`), `setup()` and
`setup_at()` take the same kind again, which changes nothing, and everything outside asks
`is_car()`. The five lines left `tools/field_reads.txt`.

**Why the kind is a constructor argument.** A public writer would be called by tests alone: the
game never changes a built agent's kind. Suites build the agent the way the game does.

**Tests read what the crowd does.** The builder's suite reads whether the crowd's agents move,
whether they ask for their pictures from the atlas handed in (a counting library), and whether the
screen and the frame record handed in are asked (counting stand-ins); `test_run_config` reads
that a `--skip motion` crowd stands and walks once let. `test_atlas_boot` reads that the crowd
asks the sitting's library for its page.

**One check dropped on purpose.** `test_prediction_reuse` re-kinded a built agent to check its
projection followed (6 checks across the two kinds); the game cannot do that, so the check went
with the setter.
