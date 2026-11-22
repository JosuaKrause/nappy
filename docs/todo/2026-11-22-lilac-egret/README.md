priority: later

# lilac-egret — The crowd-yields probe leaves its signal connections behind · filed 2026-11-22

**Found** by the agent of pull request #1631 (minty-quail row 4b), in its parity run.

**What holds.** `tests/probes/minty_quail_crowd_yields.gd` exits 1 on main. The suite runner reports shared state left changed on three `EventBus` signals after the probe: `car_near_miss`, `crowd_bumped` and `hard_fail_triggered` each keep one connection, the probe's anonymous lambda, because the probe connects lambdas and never disconnects them. Its own output is complete (twelve `CROWD_YIELDS_JSON` lines); the failure is the runner's leak check, three `FAIL` lines and a nonzero failure count in the summary.

**The command that shows it:**

    tools/test.sh probes/minty_quail_crowd_yields.gd; echo $?      # 1, three LEAK / FAIL lines, about two minutes

**What the fix must hold.** The probe leaves `EventBus` as it found it (each connection is made with a named callable it disconnects on every path out, a run that ends early included), the runner's leak check passes, and the `CROWD_YIELDS_JSON` lines are the same as before the change.
