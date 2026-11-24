# A closed street, before and after the closure pieces draw through the scenery drawer

**Claim.** The roadworks closure on day 1 of seed 4242, seen from its junction, looks the same on main
(`f2dbd524f`, `before.png`) as on the branch (`a644cde11`, `after.png`): the barrier, its sign and the
roadworks lying in the street are laid in the same places. The cars on the cross street differ because
the two runs are not frame-locked; that is the only difference.

**Limits.** One closed street. The spent park's fence is drawn through the same functions but is not
photographed: a fenced park needs a run that has used a park in act III, which no dev flag stands up.

**Command** (each worktree): `tools/shot.sh out.png 4 --seed 4242 --day 1 --spawn closure --invincible --no-save`.
Both PNGs are the whole retained output of that command.
