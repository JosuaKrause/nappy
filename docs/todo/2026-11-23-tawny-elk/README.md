priority: later

# tawny-elk — Reads of an inner class's fields are seen by no check · filed 2026-11-23

**What is wrong.** `tools/check_field_reads.py` finds a read of a `var` that another class under `src/` declares at the top level of a file with a `class_name` or an autoload name. A var only an inner class declares is not a var to it (its header says so). So reads of another file's inner-class fields appear in neither `tools/field_reads.txt` nor any item: `SealPlanner.Candidate`'s `id`, `strength` and `def_ids` and `SitedSeal`'s `segment`, `candidate`, `along` and `bodies` (`src/routes/seal_planner.gd`), and `ResistanceSteps.Step`'s `is_pickup`, `index`, `title` and `target_kind` (`src/resistance/resistance_steps.gd`), read from other files such as `src/resistance/resistance_director.gd`, `src/ui/hud.gd` and `src/dev/route_rig_planner.gd`. The field-reads rule (**designing-classes**, "Fields are not API") is unenforced there. A filing from a review, not from the player's words; the band, `later`, is the filer's proposal.

**Found by** the design of the scene recipes' pass (`.claude/briefs/designs/minty-quail-scene-recipes-pass.md`, untracked in the orchestrator's checkout).

**What a builder does.** Either teach the check inner classes reached as `Outer.Inner` (listing today's reads in `tools/field_reads.txt`, a list that only shrinks), or put each of these behind methods by hand, and say which and why. The reads are found with `rg -n '\.(is_pickup|target_kind|bodies|def_ids)\b' src`, run again. A check's count change is explained to the check before the pull request opens.

**Shown fixed.** `tools/check_field_reads.py` fails on a read of one of these fields from another file, or no such read remains.
