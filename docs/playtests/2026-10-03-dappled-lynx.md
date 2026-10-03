# Playtest dappled-lynx — Authored scenes choose existing events explicitly

2026-10-03.

After the numbered review in [downy-egret](2026-10-03-downy-egret.md), the assistant
attributes the unwanted water-main break to normal day-three background event
scheduling, proposes keeping ordinary street activity while excluding that break,
and says the repeated buildings share the same construction setup. The player says:

> why does the normal event scheduler run in authored scenes? choosing the events deliberately is the *point* of the scene builder

The assistant acknowledges that treating the earlier request for ordinary bustle as
permission to choose extra events automatically was mistaken. It states that authored
recipes should specify their events and closures deliberately, with pedestrian and
traffic simulation separate from choosing extra events.

The player then quotes the assistant's preceding progress message:

> The scene revision can use an existing production gate for the horizontal approach, so it needs no new gate artwork. The agent is also adding recipe-specific placement controls for the restaurant guests, barriers, and roof fixtures while keeping normal game population and event budgets unchanged.

The player responds:

> what are you talking about here? just use the standard vertical gate -- don't create anything -- only use things already in the game!

The assistant confirms the standard existing vertical gate with the father walking
horizontally toward it. Scene objects use existing game objects, not new artwork,
new event types or substitutes.
