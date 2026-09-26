## The probes are parked in the tree, not on a branch · built 2026-09-09

M64's two measurement probes had been kept on a branch of their own, `feature/normal-density-on-
the-path`, so that *measure it again afterwards* meant running the same file. The reason was
mechanical: the runner discovers every `tests/test_*.gd`, so on `main` they would have run in CI on
every pull request, printing twenty seconds of numbers nobody reads. *(2026-09-09: "why keep the
measurement probes off main? just park them somewhere".)*

So they live at `tests/probes/m64_measure.gd` and `tests/probes/m64_density.gd`. `run_tests.gd`
still discovers only the top of `tests/`, and a filter containing a `/` is taken as a path under
`tests/` — `tools/test.sh probes/m64_density.gd` — so a probe runs only when named. The branch is
deleted: a branch is invisible from the tree, and `git branch` should answer only *is there work
that is not on `main`*. The verify skill says where a probe worth keeping goes.
