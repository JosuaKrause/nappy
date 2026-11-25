priority: now

# silver-egret — A shadow is where the object meets the ground · filed 2026-10-03

> "currently shadows are oval below objects. for most objects the oval spans the entire visual
> bounding box. this does not read as shadow. for example, the shadow of a car goes all the way above
> the roof of the car. it should only be where the wheels would reasonably be."

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 1 (note #423). **A shadow sits where the object meets the ground, not across its
whole picture**: a car's only where its wheels would be, never above its roof. The player gave two
ways and chose neither: "either we keep the oval for shadows and adjust their number and extent to
what makes them look reasonable or we draw a custom shadow for each object that resembles what we
would expect a shadow of that object to look like".

**Built, in [silver-egret](../../decisions/2026-10-03-silver-egret.md)'s record: the vehicles.** A car's
shadow, and every other vehicle's bar two, now lies under its wheels, one oval per wheel pair, the first of the player's two ways
(minty-hedgehog 1; the police car of azure-koala 10). The two ways are still the player's to choose
between (tiny-lark 18-19); the record says what was built and why it overturns nothing.

**What is left, two items:**

- `swing-frame.md`: the swing frame's shadow, built on the orchestrator's pick on the board
  (swing-frame-shadow, open to the player).
- `riot-and-moving-van.md`: the riot van and the moving van, whose ovals still span their whole
  body, wider than the van.
