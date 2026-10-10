# Whether the day-9 and station-door scenes show the sent pursuer

**Low, a question for the player · from the re-review of PR #592 (azure-beaver, the task scenes are
a handcrafted stretch).** Day 9's scene and the station-door corner show no pursuer a finished task
sends, since their stretches have no tile where a sent robber starts (`docs/SCENE_RECIPES.md` says
so). That makes them safer than the real day, against "the events should still spawn using the same
rules".

**Open, for the player:** should they get the robber's approach street (through `draft.include`)
and an observation that he pursues her?
