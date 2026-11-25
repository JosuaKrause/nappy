# An engine warning stands in the run-config suite: a Camera2D overridden to physics process mode

`tests/test_run_config.gd`'s `_test_the_city_hands_each_value_to_its_part` builds a `Camera2D` as a child of a `Stroller` and leaves its `process_callback` at the default (idle). With physics interpolation on, the engine prints `WARNING: Camera2D overridden to physics process mode due to use of physics interpolation.` (`scene/2d/camera_2d.cpp:88`) and the run goes on. The **godot** skill leaves no warning the engine prints standing.

**How it shows:** `tools/test.sh test_run_config.gd` prints the warning once and still ends "0 failures".

**What would fix it:** the camera is given `camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS` where it is made, as the camera in `_test_the_forced_row_is_handed_to_the_director` in the same file already is. A builder re-runs the suite and any other that builds a bare `Camera2D` under a `Stroller`, since the same warning would stand there.
