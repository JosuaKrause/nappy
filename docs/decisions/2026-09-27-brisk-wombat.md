# brisk-wombat — The mark and its robber never appear in front of her · built 2026-09-27

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 7: "I just had one appear out
of nowhere while I was walking through an alley and then a robber also appeared out of nowhere and
instakilled me.")*

**Two causes, both fixed (PR #414).** A relocated mark took the nearest reachable alley with no
check of her sight, often the one she stood in; it now skips any alley she can see. And the guard's
band was drawn against the mark only, so he could land inside his own reach of her; it now keeps
out of his `pursues_within` and catch of where she stands. A test for each.
