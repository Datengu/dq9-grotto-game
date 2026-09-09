extends SceneTree
var game: Node
var samples: Array = []
var tick_rate = 60
var frames = 240
var label_name = "motion"
var started = 0
var simulation_time = 0.0
var context = "hub"
func _init():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ticks="): tick_rate = int(arg.trim_prefix("--ticks="))
		if arg.begins_with("--frames="): frames = int(arg.trim_prefix("--frames="))
		if arg.begins_with("--label="): label_name = arg.trim_prefix("--label=")
		if arg.begins_with("--context="): context = arg.trim_prefix("--context=")
	Engine.physics_ticks_per_second = tick_rate
	call_deferred("run")
func run():
	game = load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.world.show_hub()
	if context == "grotto":
		var meta = GrottoGenerator.create(123456,150,150)
		var floor_data = GrottoGenerator.generate(meta)[0]
		game.world.show_floor(floor_data,meta,{"seen":{},"opened":[],"defeated":[],"boss_dead":false})
		var room = floor_data.rooms[0]
		for candidate in floor_data.rooms:
			if candidate[2] > room[2]: room = candidate
		place_party(Vector3((room[0]+1.5)*1.8,0,(room[1]+room[3]/2.0)*1.8))
	elif context == "interior":
		game.world.enter_building(Content.table("hub").buildings[0])
		place_party(game.world.geometry.position+Vector3(-4,0,4))
	game.world.authority_enabled = false
	game.world.leader.command_override = true
	game.world.leader.desired = Vector3.RIGHT
	started = Time.get_ticks_usec()
	# Short clear stretch across the square; no test-speed increase.
	for i in frames:
		await process_frame
		await RenderingServer.frame_post_draw
		var actor = game.world.leader
		var render_delta = game.get_process_delta_time()
		simulation_time += render_delta
		if simulation_time > 1.7: actor.desired = Vector3(-1,0,-1).normalized()
		var visual = actor.get_global_transform_interpolated().origin if ProjectSettings.get_setting("physics/common/physics_interpolation",false) else actor.global_position
		var screen = game.world.camera.unproject_position(visual+Vector3(0,1,0))
		samples.append({"frame":i,"time":Time.get_ticks_usec(),"simulation_time":simulation_time,"render_delta":render_delta,"physics":Engine.get_physics_frames(),"x":visual.x,"z":visual.z,"physical_x":actor.global_position.x,"camera_x":game.world.camera.position.x,"screen_x":screen.x,"model_yaw":actor.model.get_global_transform_interpolated().basis.get_euler().y})
	var velocities: Array = []
	var wall_clock_velocities: Array = []
	var screen_steps: Array = []
	var frozen = 0
	for i in range(1,samples.size()):
		var a = samples[i-1]; var b = samples[i]
		var elapsed = b.simulation_time
		if elapsed < 0.5 or elapsed > 1.6: continue
		var step = b.x-a.x
		if absf(step) < 0.00001: frozen += 1
		# GPU completion/OS scheduling can delay this callback then bunch the next
		# one (e.g. 29 ms then 4 ms at a 60 FPS cap). Judge transform cadence with
		# the actual engine render delta; retain wall-clock variance as evidence.
		velocities.append(step/b.render_delta)
		wall_clock_velocities.append(step/((b.time-a.time)/1000000.0))
		screen_steps.append(b.screen_x-a.screen_x)
	var stats = {"sample_count":velocities.size(),"frozen_frames":frozen,"mean_speed":mean(velocities),"speed_std":deviation(velocities),"wall_clock_speed_std":deviation(wall_clock_velocities),"screen_step_std":deviation(screen_steps)}
	var passed = velocities.size() >= 10 and frozen == 0 and absf(stats.mean_speed-4.4) < 0.4 and stats.speed_std < 0.5 and stats.screen_step_std < 0.8
	var file = FileAccess.open(TestOutput.path(label_name+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"context":context,"ticks":tick_rate,"interpolation":ProjectSettings.get_setting("physics/common/physics_interpolation",false),"stats":stats,"samples":samples}))
	print("MOTION: ",label_name," passed=",passed," ",stats)
	game.queue_free(); await process_frame
	quit(0 if passed else 1)

func mean(values: Array) -> float:
	var sum = 0.0
	for value in values: sum += value
	return sum/maxi(1,values.size())
func deviation(values: Array) -> float:
	var average = mean(values); var squares = 0.0
	for value in values: squares += pow(value-average,2)
	return sqrt(squares/maxi(1,values.size()))

func place_party(pos: Vector3) -> void:
	game.world.leader.position = pos+Vector3(0,0.05,0)
	game.world.leader.reset_physics_interpolation()
	game.world.trail.reset(pos)
	for i in game.world.followers.size():
		game.world.followers[i].position = pos-Vector3((i+1)*1.35,0,0)
		game.world.followers[i].reset_physics_interpolation()
	game.world.camera.reset_tracking()
