# The day-9 and station-door scenes show the sent pursuer

**Low · from the re-review of PR #592 (azure-beaver, the task scenes are
a handcrafted stretch).** Day 9's scene and the station-door corner show no pursuer a finished task
sends, since their stretches have no tile where a sent robber starts (`docs/SCENE_RECIPES.md` says
so). That makes them safer than the real day, against "the events should still spawn using the same
rules".

**They get it** (inbox #650 in [mossy-beaver](../../playtests/2026-10-10-mossy-beaver.md)), asked whether they should
get the robber's approach street: "yes include his approach street." Each scene's draft takes the
street a sent robber starts on (through `draft.include`), and an observation checks that he
pursues her after the task is done.
