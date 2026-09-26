## M158, the staircase follows the corrected tile grammar — 2026-09-19

[PLAYTEST-81](../playtests/PLAYTEST-81.md) replaces the first live stair assembly with the player's
literal 10-column cell grammar. `InteriorMap.STAIRWELL_ROWS` is the authority for drawing,
walkability, collision and stair direction: `F` is level floor; `D` keeps the corresponding
corridor transition; `t`/`m` and `T`/`M` are the two-row walkable slopes; `b`, `c`, `C` and `.`
are solid. The right-side `b` in `.....TMCb.` is present. The same alternation extends only far
enough to join the lobby.

Seven 32×32 SVG roles draw the grammar directly. The upper and lower east/west pairs make the
walkable flights, east/west continuation triangles close their diagonal sides, and the neutral
block's 16px-deep gray top rectangle matches the adjacent continuation. The old broad decks,
landing overlays and every rail remain absent. This preserves the reviewed lateral-flight source
shapes while letting the map, rather than a decorative overlay, own the stair.

The focused interior suite drives the real 14px player body across complete east- and
west-descending flights in both normalized directions, checks the blocked side/background cells
and checks every door pairing. The complete capture folder at
`docs/evidence/archive/session-captures/2026-09-19/rig-110853-seed3349946719-v0.11.1-38-g2663c361-dirty/`
retains the normal-scale left shaft and its run provenance.

[PLAYTEST-83](../playtests/PLAYTEST-83.md) gives the played verdict: *"the stairs look good."* That
accepts the corrected live assembly without adding a railing or restoring any discarded deck.

### M160, main reconciliation and identity audit — 2026-09-19

The synchronization used original father tip `7a97598958532abf56f278d50b3fc8d6f90d545b`,
prepared installation tip `e29c0eb90eeb44eeca0eabd326d61f74c91018cc`, incoming main
`0afb8c679a5d4a1b67b032e543a6de0681d98bfd`, and common ancestor
`b1e7263f78168771a2e58f4e8ab2972ad2f6eddd`. The pending merge's actual first parent is the
prepared tip. Each conflict was shown as Theirs (main), Ours (father), and Base before resolution.

DECISIONS retained both the independent staircase record and the father's attempt/acceptance
history. HANDOFF retained main's removal of completed staircase and save work, replacing stale
father/performance state with the current independently owned threads. TODO retained main's
completed-save removal and M165 escape brief, plus the distinct M167 leg-drawing follow-up;
the redundant separators were removed. No identifier mapping was needed: main's PLAYTEST-81,
83, 84 and 85 remain separate from father records 79 and 87–91 and PR #216's PLAYTEST-86.
M158, M159, M160, M162, M163, M164, M165, M166 and M167 retain their own subjects.

The clean-file semantic review checked more than the conflict paths. Incoming saves preserve
`player_is_male`, and `main.gd` restores it into the stroller, so resumed father runs use the
same corrected pushing assets. Incoming stair changes use the carrying family, untouched here.
The resolver, atlas, stroller and sprite callers are unchanged by incoming main; matching native
canvases and existing paths bind the four PNGs without runtime scale or offset changes. Import
sidecars remain unchanged. Main's save/stair docs and review questions, no-save guard and
model-independent delegation guidance survive intact; performance measurements stay on PR #216.

### M167, first drawing refinement rejected; woman's legs proposed — 2026-09-19

The first one-call lower-body refinement in PR #234 added knee and trouser definition without
changing the accepted contact endpoints. It preserved all protected frames and reproduced
exactly, but [PLAYTEST-92](../playtests/PLAYTEST-92.md) still rejected its drawing: "still bad legs --
maybe use the legs of the woman in those cases?" — "they have the same pants". The first preview
remains retained, not used as a style reference. The next attempt may borrow the woman's accepted
pushing legs for E/W and SE/SW B while retaining the father's upper body and opposite-contact
ownership. This expands the earlier father-only donor permission for this trial; it does not
authorize runtime installation or change the other protected frames.

### M160, reconcile the externally merged escape work — 2026-09-19

Main advanced while the contact PR was being verified. The second synchronization used
original father tip `c3116321fcb7ac20518d3c71c8d7b0e4385cc30c`, prepared feedback tip
`3d8bf4ff1af4cd2b8521073ebaedc1090e68547a`, incoming main
`aca1cf6658689179f29afabc7212a760902c4656`, and ancestor
`0afb8c679a5d4a1b67b032e543a6de0681d98bfd`. It merged without textual conflicts.

The whole-result review retained main's M165 escape completion and review questions, including
fixed timer-driven steam, staircase paths, spawn-relative placement and archived unused stair art.
The father change touches pushing pictures, not carrying pictures, placement, collision, event
definitions or save selection; all incoming runtime/test files match main and all father assets
match the prepared tip. Main's early-preview guidance also survives. Numbered records remain
distinct, with the mother's-leg proposal added as PLAYTEST-92 rather than modifying an earlier
primary source. M165 leaves TODO; M167 remains open. Boot, focused visuals/player-presentation/
interior/finale suites, forced-SVG visuals, document lint and diff checks passed on this tree.
