priority: later

# amber-panda — Retire tools/inbox.py ask · filed 2026-11-22

No player's words name this; it follows [#1640](https://github.com/JosuaKrause/nappy/pull/1640) (questions about an inbox note go on the board, inbox #1639 in gentle-penguin).

**Found.** No rule asks through `tools/inbox.py ask` now: the inbox skill says so ("No rule asks through `tools/inbox.py ask` now") and the using-tools catalogue marks it unused.

**What holds today.** The subcommand, its help and docstring in `tools/inbox.py`, its tests in `tools/test_inbox.py` and its case in `tools/test_rules_hooks.sh` (the write guard allowing it as the orchestrator) still exist.

**What the fix must hold.** The subcommand is deleted, with its help, its tests in `tools/test_rules_hooks.sh` and `tools/test_inbox.py`, its using-tools line and the inbox skill's sentence about it; nothing else calls it (`rg -n "inbox.py ask|\bask\b" tools .claude`). `tools/pycheck.sh` and `tools/test_rules_hooks.sh` pass.

*Proposed, not asked for:* the band `later`.
