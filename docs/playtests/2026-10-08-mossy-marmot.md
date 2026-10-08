# Playtest mossy-marmot — Finish the open PRs and fully handcraft the task scenes

2026-10-08.

## #618 — Finish the open pull requests

The remaining open work was PR #580 (trailer), #588 (task arrows), #592 (task scene layouts)
and #597 (warnings). Interrupted Claude changes on the arrows and scenes had been preserved
and pushed, but implementation had not resumed. Warnings had a fresh independent approval
and awaited its automatic merge. The trailer agent was preparing the apartment-window preview.
The player asked:

> can you pick up all open PRs?
>
> and finish them?

The orchestrator then asked: "For #592, task scene layouts, the interrupted version still
regenerates streets and buildings from a seed; only the people, traffic, and events are
explicitly placed. Your original request was for everything to be editable by hand. I recommend
finishing that original design in this PR, which takes more work. Should I make the layouts
independent of city generation now, or finish the smaller version and leave fully handcrafted
layouts for later?"

The choices were "Finish fully handcrafted layouts now (Recommended)" and "Keep generated
layouts; handcraft later". The player chose:

> Finish fully handcrafted layouts now (Recommended)
