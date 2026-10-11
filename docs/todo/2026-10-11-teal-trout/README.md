priority: now

# teal-trout — Every charger is neutral, then warns, then charges · filed 2026-10-11

[velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #699:

> Also I'm general entities that charge towards the player when the player gets too close need three stages: neutral (with neutral visuals), warning (when the player gets close; needs to be visually distinct), and then the actual charging. Some already do this but not all

and, said just before it, #698:

> Also I noticed the waiting charging dog needs a proper resting frame when in wait. It looks like it's flying

**The rule asked for.** Anything that waits until she comes too close and then charges her shows
three distinct stages: **neutral**, drawn as an ordinary thing in the street; **warning**, once she
comes close, drawn visibly differently from neutral; and **the charge** itself. "Some already do
this but not all": the work is finding the ones that do not and giving them the missing stage.

**Where to start looking**, the rows with a trigger distance being the ones that wait for her. The catalogue rows with a trigger distance, `pursues_within` or
`pursues_within_after_first_day` in `src/events/event_catalogue.gd`: `alley_mouse`,
`pigeon_flock`, `charging_dog` (it waits from day 4, the [M96](../../decisions/2026-09-13-M96-the-dog-waits-from-day-4-and-the-day-3-charge-sprinkles-in.md)
record), `alley_robbery` and `masked_pursuer`. **The pursuers that notice her and lunge** rather
than trigger at a distance, the policemen on foot and the guards, are under the rule too
([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #704: "whether the police and guards
who notice and lunge count, -- yes, why wouldn't they?").

**A pursuer that arrives already charging is outside the rule**, such as day 3's dog sited off
screen, since it has no neutral or warning stage to show (#705: "whether chargers that arrive
already charging count. -- how would that make sense?", read as no).

**What it must keep.** The warning stage is a danger cue and falls under the cues rules (what may
be drawn to signal danger, and no rings), and every pursuer keeps the events skill's telegraph
fairness contract. A charger's warning must not read as one of the existing cues meaning something
else.

The work is [audit-every-charger.md](audit-every-charger.md), then
[the-waiting-dog-rests.md](the-waiting-dog-rests.md) and one change per charger the audit finds
short of a stage.
