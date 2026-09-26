## Main reconciled with prepared SVG authoring — 2026-09-10

The main update uses common ancestor `f27860dda82b3f950e5814d0d59a5366f180e0c7`, incoming
main `d56a34905b9927f47c74a80112546baf4ec4a92f`, and original graphics tip
`cfbe5c15aae7a3c4425bee6842fcd65a867c5248`. Identity preparation produces
`e17e998d0898399aa0588a3e65880b9d25abf40e`, the merge's first parent.

Main's PLAYTEST-52 records crowds passing through seals, and its M110 is the crowd goes round
a seal. The independently authored graphics PLAYTEST-52 becomes PLAYTEST-53, preserving the
player's words and their order; its M110, cars follow their turns, becomes M111. The identifiers
are allocated from the union of both tips. Graphics-specific references move with their record;
main's seal references retain their identities. No other independently numbered addition collides.

The sole textual conflict is at the opening of `DECISIONS.md`: main adds the M61 shape/body/shadow
record, the graphics branch adds SVG authoring/retention history, and the base has neither. Both
sections are retained above the existing eight-direction transfer record.

The semantic review retains main's complete runtime and test changes: `GroundShape` supplies
shadows and collision bodies, shape copies survive heat/seal variants, and the retired generic
shadow SVG stays absent. The graphics branch adds prepared sources and source-review evidence,
without selecting them in any caller or TileSet. The catalogue therefore describes main's
code-drawn shadows alongside the new unbound art. Import-sidecar cleanup below `.gdignore`
coexists with main's new evidence; active source import metadata remains tracked.

M108, eight-direction entity graphics, keeps shape and strike geometry independent of the chosen
view. M111, cars follow their turns, must orient both the picture and shape shadow along actual
travel, while maintaining the separate lethal strike contract. M110, the crowd goes round a seal,
owns which crowd lanes are blocked; M111 owns the continuous path through the selected diversion.
Neither item subsumes the other's implementation or resolves the open question about ordinary
solid obstacles. Main's remaining M61 field work stays open.

The review also corrects overbroad documentation inherited from main: segment shadow caps are
circular rather than squashed ellipses, crash scenes retain authored shadow textures, and the
player's physics circle is independent of the mother/pram shadow shapes. The car-shape test
compares axial extents, not containment of the strike rectangle's corners. Moving-van obstruction
is a capsule, while skip and burnt-out-car obstructions remain circles; live silhouette/body
agreement remains a debug-view review, not a claim established by adding the shape datum.

Merge verification passes in the actual checkout: import/boot, focused shapes/visuals/events/crowd
suites, documentation/XML lint and whitespace checks. The focused run has no failures.
Both playtest bodies are compared to their recorded tips; only the graphics title's
identity changes. Runtime sources and tests match incoming main exactly. No additional gameplay
capture is needed for this merge because the branch adds no runtime selection or behavior.
