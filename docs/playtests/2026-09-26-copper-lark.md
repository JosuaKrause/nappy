# Copper lark — Compare original sound styles

2026-09-26. Experimental sound design request in conversation.

> "besides that I want you to work on something experimental: can you create sound effects for the game from scratch. no precreated assets. we create the assets here from scratch. you can be creative in approaching this task. tell me how you want to do it and we can discuss"

The assistant proposed generating WAVs from original synthesis code and comparing a small set
before game integration. Asked whether the first set should be grounded, clearly synthetic, or
compare both styles, the player answered:

> "Compare both styles"

The assistant's sample selection is footsteps, stroller wheels, a car horn and loudspeaker
crackle. This is an initial listening experiment, not approval of runtime sound behavior.
Every sample is generated here from scratch; no recordings or precreated sound assets are used.

## Reproducibility and branch scope

> "write down your approach like we do with graphics. so it stays reproducible"

> "keep the sound experiment in its own branch. also where can I listen to the samples?"

The authoring method belongs in a repository skill, with recipes and regeneration settings
preserved beside the listening samples. The sound experiment has its own branch and pull request,
separate from the park fence repair. The samples are delivered as a comparison WAV and an offline
listening-page bundle.
