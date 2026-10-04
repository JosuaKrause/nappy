priority: now

# teal-ibis — Remaining disk headroom and browser scratch safeguards · filed 2026-10-03

[snowy-newt, disk accumulation and safeguards](../../playtests/2026-10-03-snowy-newt.md)
asks for storage measurements and safeguards against filling the drive, and for
completed jobs to clean up their temporary data. The
[storage measurement and cleanup record](../../decisions/2026-10-03-teal-ibis.md)
contains the measured accumulators and the implemented retirement, build and updater
safeguards.

The measured disk-space preflights and the browser scratch cleanup are built
([their record](../../decisions/2026-10-03-teal-ibis-2.md)). The trailer's own check is
built too ([its record](../../decisions/2026-10-03-teal-ibis-3.md)). This entry holds what is left:
the Web-template build's scratch outside its work directory is found (`browser-build-scratch.md`).

**Proposed, not asked for:** retain the urgent band for these remaining safeguards.
