# Graphics work entry point

Read [HANDOFF.md](HANDOFF.md), then M108, eight-direction entity graphics, and
M109, convert the SVG catalogue to PNG, in
[TODO.md](TODO.md). [VISUALS.md](VISUALS.md) defines reference authority and the exact-size
texture replacement contract. [GRAPHICS.md](GRAPHICS.md) distinguishes live and prepared assets.

Every PNG asset needs a corresponding SVG authored and reviewed first. Follow the SVG art skill
for sources and the illustrated-png skill for their derivatives.
Implementation work takes a bounded scope from the orchestrating session and preserves gameplay,
existing drawing transforms and the opt-in flag.
