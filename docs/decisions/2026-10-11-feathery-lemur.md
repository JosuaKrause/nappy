# feathery-lemur — A held input carries her on through a gatehouse's release · 2026-10-11

[velvet-marten](../playtests/2026-10-11-velvet-marten.md), #697: "with the gatehouses if I don't
lift my finger during the move I don't expect the movement to get reset. so, only reset if I lift my
finger. basically keep updating navigation"; asked about a key: "Keyboard holding is the same as
finger holding. If I don't lift it I expect it to remain active".

**What it overturns, with the player's word.** [downy-lark](2026-10-10-downy-lark.md) built "a held
input is ignored until released or changed, in every control mode, for every `redetains` hold" as
proposed at filing and open to the player's correction; this is that correction. downy-lark's
reset itself stays for an input that was lifted.

**What is built.** `Stroller` no longer remembers the input held at a hold's release and reads it as
zero; it reads `Input.get_vector()` as on any frame, so a key, a finger or a joystick drag still down
when the hold lets her out steers her from the first frame, and one lifted during the hold is already
gone and leaves her standing still. `TouchControls.stand_still_after_hold()` drops a locked heading
only when no finger is down. It holds for every `redetains` hold, which share the path.
`tests/test_checkpoints.gd`'s `_test_she_stands_still_when_a_hold_lets_her_out` checks both halves
for a key, a tap's finger and a joystick drag; `tests/test_telemetry.gd` loses the test whose premise
was the ignored held key, since a held key that goes nowhere now counts as blocked like any other.
`docs/MECHANICS.md`'s hold paragraph says it.

*Open to overturn:* a tap's locked heading with no finger down at the release counts as lifted and
resets (the filer's reading); likewise a joystick heading whose finger is up; a key lifted and pressed
again during the hold is a fresh choice and walks her.
