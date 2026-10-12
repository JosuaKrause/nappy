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

**The audit** ([teal-trout-2026-10-11](../../evidence/teal-trout-2026-10-11/README.md), a table and
a clip of each charger) found these short of a stage, each an item here:
[the-dog-rests-then-warns.md](the-dog-rests-then-warns.md) (neutral and warning both),
[the-robbers-warning-is-not-his-lunge.md](the-robbers-warning-is-not-his-lunge.md),
[the-roadblock-guards-warning.md](the-roadblock-guards-warning.md) and
[the-door-guards-stages.md](the-door-guards-stages.md). The policeman out of an investigating patrol
car and the men out of a hunting van show three distinct stages. The alley mouse, the pigeon flock
and the masked man do not charge her; the masked man's stages are drawn inverted, which is
[the-masked-man-waits-standing.md](the-masked-man-waits-standing.md).

**Open, for the player:** what a warning looks like. The cues rules limit what may signal danger,
and the existing flashing caret already marks a warning over most of them.
