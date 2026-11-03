# minty-quail — The run is held by the Sitting; GameState is a stand-in only tests read (the run's state handed in) · 2026-11-02

minty-quail's `run-state-handed-in.md`, its first pull request: the run moves onto the `Sitting`.
The item stays open for the suites that still read the stand-in and for the last wave that removes
it.

**Built.**
- The run is `Sitting.run`. A sitting's first boot makes a fresh `RunState` as its child
  (`Sitting.take_the_run()`), so the run is parked with the sitting across every reload and freed
  with it; `main._take_the_sitting()` calls `_take_the_run()`, which sets the run and its parts
  from the sitting, and `main` hands the run down as before. `main.use_sitting()` takes the run at
  once, so a `main` built off the tree has one. The day-14 hand-over and a carried run keep the same
  object; a resume reads into it; a held restart starts a fresh run in it on the next boot. The save's
  shape, the run log and the GoatCounter names are unchanged.
- No class under `src/` names `GameState`, comments included; the docs that said the game reads
  `GameState.<part>` name the run as the code does.
- The `GameState` autoload is a stand-in only tests read. The runner hands it to every `Sitting`
  that enters the tree holding no run (`SceneTree.node_added`, `_hand_the_stand_in()`), before
  `main` takes its run, so a suite not yet moved that sets `GameState.header.day` and boots `main`
  works unchanged; a sitting a suite hands its own run keeps it. Nothing under `src/` knows of the
  stand-in.
- Suites changed only where the move broke them: `test_atlas_loading.gd`, `test_run_checkpoints.gd`,
  and the two scene-recipe probes that boot `main` in a process of their own, which read the run
  off the booted `main`'s sitting.

**Rejected:** parking one sitting holding the stand-in at the root, which would share its atlas
library, controls word, restart stamp and save across every boot in a suite; and the sitting
looking the stand-in up itself, a test-only global read in `src/`.

**Open to overturn** (the builder's choices where the brief was silent): the runner's `node_added`
hand-off as the bridge; the sitting making its run lazily as its child; `use_sitting()` taking the
run at once; a held restart resetting the same run object until the stand-in goes, where the item's
reading of record fluffy-lark has it replaced; `RunState` staying a node while the stand-in, an
autoload, must be the same object.
