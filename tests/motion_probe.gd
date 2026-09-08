extends SceneTree
var game: Node
var samples: Array = []
var tick_rate = 60
var frames = 240
var label_name = "motion"
func _init():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ticks="): tick_rate = int(arg.trim_prefix("--ticks="))
		if arg.begins_with("--frames="): frames = int(arg.trim_prefix("--frames="))
		if arg.begins_with("--label="): label_name = arg.trim_prefix("--label=")
	Engine.physics_ticks_per_second = tick_rate
	call_deferred("run")
func run():
	game = load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.world.show_hub()
	game.world.leader.command_override = true
	game.world.leader.desired = Vector3.RIGHT
	# Short clear stretch across the square; no test-speed increase.
	for i in frames:
		await process_frame
		await RenderingServer.frame_post_draw
		var actor = game.world.leader
		var visual = actor.get_global_transform_interpolated().origin if ProjectSettings.get_setting("physics/common/physics_interpolation",false) else actor.global_position
		var screen = game.world.camera.unproject_position(visual+Vector3(0,1,0))
		samples.append({"frame":i,"time":Time.get_ticks_usec(),"physics":Engine.get_physics_frames(),"x":visual.x,"physical_x":actor.global_position.x,"camera_x":game.world.camera.position.x,"screen_x":screen.x})
	var file = FileAccess.open("res://test-output/"+label_name+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"ticks":tick_rate,"interpolation":ProjectSettings.get_setting("physics/common/physics_interpolation",false),"samples":samples}))
	game.queue_free(); await process_frame
	quit()
