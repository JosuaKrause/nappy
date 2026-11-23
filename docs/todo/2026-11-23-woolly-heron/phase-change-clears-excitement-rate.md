# A phase change clears the live event's cached excitement rate

**What is wrong.** Nothing holds that a phase change clears the live event's cached excitement rate.
Removing the clearing from the phase change leaves every suite that runs it passing (pull request 1663's
review measured it on six suites), so the cache could go stale across a phase with no failure.

**What a test holds.** A live event whose phase changes while its rate is cached answers the new phase's rate at
its next ask, not the cached one: a rate cached before the change and asked after it differs from the one the
new phase gives.

**Shown fixed.** With the clearing removed from the phase change the new check fails, and with it restored the
check passes. The check goes in the suite of the module that holds the cache, with its collaborators faked.
