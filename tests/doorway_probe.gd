extends SceneTree
func _init(): call_deferred("run")
func run():
	var game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.world.enter_building(Content.table("hub").buildings[0])
	game.world.leader.command_override = true
	game.world.leader.desired = Vector3.BACK
	var minimum_y = 0.0
	var exited = false
	for i in 240:
		await physics_frame
		minimum_y = minf(minimum_y,game.world.leader.position.y)
		if game.world.mode == "hub": exited = true; break
	print("DOOR PROBE: ",JSON.stringify({"automatic_exit":exited,"lowest_y":minimum_y,"mode":game.world.mode,"position":str(game.world.leader.position)}))
	game.queue_free(); await process_frame
	quit(0 if exited and minimum_y > -0.5 else 1)
