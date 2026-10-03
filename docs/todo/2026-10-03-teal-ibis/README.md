priority: now

# teal-ibis — Remaining disk headroom and browser scratch safeguards · filed 2026-10-03

[snowy-newt, disk accumulation and safeguards](../../playtests/2026-10-03-snowy-newt.md)
asks for storage measurements and safeguards against filling the drive, and for
completed jobs to clean up their temporary data. The
[storage measurement and cleanup record](../../decisions/2026-10-03-teal-ibis.md)
contains the measured accumulators and the implemented retirement, build and updater
safeguards.

The measured disk-space preflights and the browser scratch cleanup are built
([their record](../../decisions/2026-10-03-teal-ibis-2.md)). This entry holds what is left:
`tools/trailer.sh` checks its headroom like the other capture tools (`headroom.md`).

**Proposed, not asked for:** retain the urgent band for this remaining safeguard.
