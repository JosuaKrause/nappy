class_name RouteRigNoQuit
extends RouteRig
## A `RouteRig` that finishes without quitting the process. The real rig ends a `--route` run by
## quitting the tree, and the runner lets frames pass after a suite, so a quit left pending by a
## suite that drives a rig to its end would stop the whole run after that suite, silently and
## with a zero exit.

func _quit() -> void:
	pass
