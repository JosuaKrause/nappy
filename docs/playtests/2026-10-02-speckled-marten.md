# Playtest speckled-marten — Spread ground compositing across frames

2026-10-02.

## The issue

Filed from #446, [split ground visuals creation into multiple frames](https://github.com/JosuaKrause/nappy/issues/446).
The issue is written by the player. Its complete body is:

> The compositing process of creating ground visuals can be smeared across multiple frames. That would improve stuttering 

## Pick up the work

While PR 448's save review is complete, the player asks this session to pick up issue 446.
They are unsure whether the issue-implementation workflow rules have landed and give a direct
instruction for this work:

> can you pick up 446? I'm not sure if proper rules around implementing issues have landed yet -- for now just record this as a new todo and start working on it

## The nearby ground regions are the subject

The assistant describes the shared image sheet as synchronously built at boot and repaint,
then says it will delegate spreading that composition over frames. The player corrects the
scope to the existing nearby-region loading and distant unloading:

> what are you talking about? we made a change so ground composition happens dynamically surrounding the player

> regions that are too far away are unloaded

The assistant acknowledges that nearby regions are already prepared around the player and
distant regions unloaded. Issue 446 targets spreading work in that dynamic region preparation
across frames. Optimizing the loading-time shared image sheet alone does not answer this ask.
