**The counter counts her running, "excluding gaps smaller than 10s"**: a run that starts again
less than 10 s after she stopped running is the same bout, and one 10 s or more after is a new
bout. *Proposed, not asked for:* each bout sends `nappy-day-N-ran` once, when it begins, whether or
not the run excites the baby (the alternative is sending it when the bout ends, once its 10 s gap
has passed); she is running whenever `Stroller.run_excess_ratio()` is above 0 (faster than walking
pace), the test the run log and `EventManager` already use; and the 10 s is one constant.
`docs/TELEMETRY.md` lists the name in the same pull request.
