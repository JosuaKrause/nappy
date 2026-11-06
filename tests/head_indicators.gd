extends RefCounted
## The regions the UI's page bakes for the stroller: the two warning marks over her head and the
## baby's three over the pram. Shared by the suites that check where they are drawn from. A helper,
## not a suite: the runner loads only `test_*.gd`.

const ALL: Array[String] = [Stroller.ALERT, Stroller.ALERT_CLOSE, Stroller.BABY_ZZZ,
		Stroller.BABY_FUSS, Stroller.BABY_CRY]
