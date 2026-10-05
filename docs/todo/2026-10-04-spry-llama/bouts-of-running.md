**Every bout of her running sends `nappy-day-N-ran`, once, when the bout begins**, whether or not
the run excites the baby. A run that starts again less than 10 s after she stopped running is the
same bout and sends nothing more; one 10 s or more after is a new bout. *Proposed, not asked for:*
she is running whenever `Stroller.run_excess_ratio()` is above 0 (faster than walking pace), the
test the run log and `EventManager` already use, and the 10 s is one constant. `docs/TELEMETRY.md`
lists the name in the same pull request.
