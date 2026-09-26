## Texture integration process — 2026-09-08

PLAYTEST-45 reported a missing illustrated player, slanted east/west mustard/red legs, outward
north/south leg movement, excessive mother-to-pram spacing that stretches the arms, and a
pixelated pram. The player explicitly asked for reproducible texture-addition skills and a
record of traps. This continues PLAYTEST-43's anatomy/scale repair, retaining PLAYTEST-44's
approved transparent v3 pram. The symptoms remain repair requirements; this documentation pass
does not mark them visually accepted or regenerate the approved source.

The complete supplied run is preserved at
`docs/evidence/run-195148-seed1407488451-v0.7.0-34-g4ae11f4/`, including its log, map and
`asked/008s-attempt1-asked.png`. It began at 19:51:48 and predates the local import repair.
The frame shows the legacy mother/pram comparison with the illustrated player absent. It cannot
establish motion or the illustrated pram's post-import filtering quality. The player's reference
to a generated diagnostic image does not name its exact file; it remains a posture report and
does not promote a diagnostic into an approved style reference.

After the PR branch was checked out in the main folder, a headless illustrated boot reproduced
the reported `ModularPerson.new()` and nil-method cascade. The first error was a missing imported
`pram-layered-v3-draft-transparent.png` `.ctex` under that checkout's `.godot/imported/`, followed
by a preload parse error in `modular_person.gd`. `tools/run.sh` only checks missing global classes;
it did not detect this missing imported texture. Running `./tools/check.sh` in the main checkout
rebuilt the cache. An explicit headless `--illustrated --walk south` boot then exited without
script errors. No source change was required for that failure. The checkout should have been
imported before being handed to the player; an import in another worktree was insufficient.

The player objected to `.import` removal. Only untracked screenshot sidecar copies in temporary
implementation worktrees had been removed; committed screenshot sidecars remained intact. The
distinction was still the wrong cleanup rule: generated `.import` files carry import settings
and resource identity and belong with source and evidence images. Only the ignored `.godot/`
cache is rebuildable checkout state. This distinction is now explicit in the Godot and
illustrated-png skills.

Read-only inspection confirmed that the illustrated pram anchor consumes the legacy 34px lead
with a 0.7 vertical projection, and the arms fit shoulder-to-grip endpoints without establishing
natural reach. Modular sprites inherit filtering, with the project default setting at `0`.
These are concrete
inspection points, not proof of the cause of every reported pixel or pose. The fixed knee-bend
convention, projected lift, measured rest axes and explicit profile-source reuse also require
directional review; a single frame cannot select a gait fix. No global filtering, collision or
movement constant was changed to disguise these presentation defects.

The existing illustrated-png skill was expanded rather than adding a second competing workflow.
Its linked texture-integration procedure records exact source/extraction provenance, measured
direction/crop/joint coordinates, alpha and filter checks, full assembly scale, natural arm reach,
directional motion, actual-checkout imports and distinct acceptance gates. It explains why exact
endpoint tests, a sampled pose sheet, legacy boot and pre-correction screenshots cannot establish
complete visual acceptance. PLAYTEST-45, the repair brief, TODO and HANDOFF carry the remaining
defects and the procedure's entry point.
