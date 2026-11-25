# polite-tapir — No layer break stands: the standing layer breaks are done · 2026-11-23

**What was asked.** A design review of the refactor found 133 listed layer breaks in 37 groups that no
open item owned, and the player: "let's not forget about those" (inbox #1268 in olive-ferret). The
item (`standing-layer-breaks.md`) read: each group ends fixed by a named pull request, corrected in
the map because the file was in the wrong layer, or declared permanent with its reason.

**What was built.** Eight pull requests and this closing one. Earlier work and the refactor's own
steps took the list from 133 uses to the eleven the design counted; the design's pull requests
fixed those: the row reads the view's least boundary from `Offscreen` (#1664), the button tokens
are the texts' (#1665), a save's change is answered on the settled signal (#1666), the building
says she came through a door (#1667), the narrow target's pool is the model's (#1670). Then the
events folder was split by layer, which the player's answer on where the settings files live
already picked (inbox #1278 in olive-ferret): `src/events/data/` (#1675), `src/events/model/`
(#1677), `src/events/simulation/` with the folder's default gone (#1679), so a file dropped in
`src/events/` itself is in no layer and fails CI. No break was moved in the map or declared
permanent: each was fixed.

**What holds now.** `uv run python tools/check_layers.py --list` prints no finding and `EXCEPTIONS`
in `tools/layer_map.py` is empty. The tool keeps `Exception_`, `EXCEPTIONS` and the matching, since
"declared permanent with its reason" is one of the three outcomes the player approved. This pull
request writes the rule that outlives the list into designing-classes' "Code is designed by layer":
no break stands; one that has to is listed in `tools/layer_map.py` with its reason and declared in
that section with the same reason, in the pull request that adds it. `docs/ARCHITECTURE.md` and
pr-review's `references/architecture-questions.md` say the same in their own words, the item file
is deleted, and polite-tapir's and minty-quail's READMEs no longer name the standing breaks.

**Set aside.** Deleting `Exception_` and the matching, so the map could excuse nothing: it removes
the third outcome the player approved. The design's other findings: `SpawnSiting.least_distance()`'s
removal (azure-egret, filed in #1674) and the five simulation files that name nothing of the
simulation (azure-marten, filed with this pull request).
