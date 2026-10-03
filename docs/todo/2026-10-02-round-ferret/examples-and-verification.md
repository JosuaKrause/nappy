# Reproduce the power-station roof and facade join

Construct the player's adjoining-building example directly, without seed hunting.
[M203, roofs covering adjoining facades](../../decisions/2026-09-26-M203-a-front-nobody-can-stand-at-is-covered-by-the-roof-in-front-of-it.md)
states: "a front column draws no facade only where a roof extension actually covers it."
The player confirms this is still the roof/facade case.

**Proposed coverage:** hall and fenced-yard variants exercise that distinction with
the actual components. M203 notes the yard guard "has no picture because no seed tried
has a column it applies to". This does not establish either possibility or impossibility.
The yard recipe passes if it breaks no existing explicit creation check; otherwise
require an explicit allow. The implementation reports which case it establishes.

Test the public loader and builder, not just parsed data: required geometry,
roof/facade coverage without blank tiles, consistent derived metadata, malformed
recipes, conflicting pins and existing-check refusal/explicit allow. If using the
proposed named-violation mechanism, test undeclared and missing expected violations.
Changing unrelated random fill must not move pinned choices; no whole-city seed
enumeration supplies required geometry.

Exercise real startup, unsuccessful error exits, save isolation and state at named
ticks. Run affected existing suites to guard ordinary generation. Provide rerun
commands and an early join still. Follow [verify](../../../.claude/skills/verify/SKILL.md)
and [session-captures](../../../.claude/skills/session-captures/SKILL.md) for provenance,
and [committing](../../../.claude/skills/committing/SKILL.md) for commit-pinned PR images.
A still proves composition, not motion. Movie rendering and load reproducibility are
M204's work, not gates on this slice.
