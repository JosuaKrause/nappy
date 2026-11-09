# A test walks a planned day and finds every lethal field kept clear

The events skill's rule is that nothing else is placed inside a lethal event's field. The
placement rules do it (`StreetInvalidation.room_around()`), one case is held (a queued mast is
never generated inside a lethal field, `tests/test_resistance_reach_contacts.gd`), and
`tests/test_events_costs.gd` holds who is exempt. No suite walks a planned day to check the rule
for every row, and `docs/EVENTS.md` says one does.

**Build:** a check over planned days (several seeds, the days with lethal rows) that no placement
stands inside another's lethal field unless it is exempt, in the suite that holds the dawn's plan;
`docs/EVENTS.md`'s sentence names it.
