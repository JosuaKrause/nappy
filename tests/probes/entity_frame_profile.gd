extends SceneTree
## Receives the native debugger's every-frame profiler without modifying game scripts.
## Launch headless with --script; configuration is documented in the evidence README.

var server := TCPServer.new()
var stream: StreamPeerTCP
var packets := PacketPeerStream.new()
var messages: Array = []
var child := -1
var started := 0
var connected := false
var enabled := false
var disconnected_at := -1
var output := OS.get_environment("ENTITY_PROFILE_OUTPUT")

func _initialize() -> void:
	if output.is_empty():
		push_error("ENTITY_PROFILE_OUTPUT must name an output prefix")
		quit(2)
		return
	var port := 6127
	if server.listen(port, "127.0.0.1") != OK:
		quit(2)
		return
	Engine.max_fps = 240
	var args := PackedStringArray(["--path", ProjectSettings.globalize_path("res://"),
		"--remote-debug", "tcp://127.0.0.1:%d" % port, "--disable-vsync", "--max-fps", "120",
		"res://tests/probes/entity_frame_profile.tscn"])
	if OS.get_environment("ENTITY_PROFILE_RENDERED") != "1":
		args.append("--headless")
	else:
		args.append("--always-on-top")
	args.append_array(PackedStringArray(["--", "--seed", "4242", "--day", "1",
		"--spawn", "arterial", "--walk", "north", "--no-title", "--no-focus-pause",
		"--no-save", "--no-telemetry", "--frame-trace", "--after", "20"]))
	child = OS.create_process(OS.get_executable_path(), args)
	started = Time.get_ticks_msec()
	print("PROFILE_LAUNCH " + JSON.stringify(Array(args)))

func _process(_delta: float) -> bool:
	if not connected and server.is_connection_available():
		stream = server.take_connection()
		packets.stream_peer = stream
		packets.set_input_buffer_max_size(8 << 20)
		connected = true
	if connected:
		stream.poll()
		while packets.get_available_packet_count() > 0:
			var message: Variant = packets.get_var()
			if message is Array:
				messages.append(message)
				if not enabled and message.size() == 3:
					enabled = true
					if OS.get_environment("ENTITY_PROFILE_DISABLED") != "1":
						packets.put_var(["profiler:servers", message[1], [true, [16384, false]]])
	if child > 0 and not OS.is_process_running(child):
		if disconnected_at < 0:
			disconnected_at = Time.get_ticks_msec()
		if Time.get_ticks_msec() - disconnected_at > 300:
			_finish(false)
	elif Time.get_ticks_msec() - started > 45000:
		_finish(true)
	return false

func _finish(timed_out: bool) -> void:
	if timed_out and child > 0:
		OS.kill(child)
	var file := FileAccess.open(output + "-profiler.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info(),
		"timed_out": timed_out,
		"profiler_enabled": OS.get_environment("ENTITY_PROFILE_DISABLED") != "1",
		"requested_max_functions": 16384,
		"messages": messages}))
	file.close()
	print("PROFILE_SAVED %s messages=%d timeout=%s" % [output, messages.size(), timed_out])
	quit(1 if timed_out else 0)
