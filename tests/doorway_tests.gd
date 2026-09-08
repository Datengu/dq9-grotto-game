extends "res://tests/playthrough_3d.gd"
func run():
	game = load("res://src/main.tscn").instantiate(); root.add_child(game)
	await process_frame
	for info in Content.table("hub").buildings:
		for side in [-0.4,0.0,0.4]:
			game.world.enter_building(info)
			game.world.leader.command_override = true
			game.world.leader.desired = Vector3(side,0,1).normalized()
			var low = 0.0
			for i in 100:
				await physics_frame
				low = minf(low,game.world.leader.position.y)
				if game.world.mode == "hub": break
			check(game.world.mode == "hub" and low > -0.1,"Automatic exit without E: "+info.id+" approach "+str(side))
			check(flat_distance(game.world.leader.position,cell_target(info.door)) < 1.5,"Return to correct physical doorway")
			check(absf(game.world.leader.model.rotation.y-PI) < 0.01,"Face away from exited building")
	# Inject failure: no transition listener. The collision backstop must hold.
	game.world.enter_building(Content.table("hub").buildings[0])
	game.world.interaction.disconnect(game.on_interaction)
	game.world.leader.command_override = true
	game.world.leader.desired = Vector3.BACK
	for i in 240: await physics_frame
	check(game.world.mode == "interior" and game.world.leader.position.y > -0.1,"Failed transition cannot cause a fall")
	check(game.world.leader.position.z-game.world.geometry.position.z < 8.1,"Exit collision backstop contains the actor")
	game.world.leader.position += Vector3(20,-6,20)
	await physics_frame; await physics_frame
	check(game.world.leader.position.y > -0.1 and absf(game.world.leader.position.x-game.world.geometry.position.x) < 8.1,"Bounds safety recovers an out-of-map actor")
	game.world.interaction.connect(game.on_interaction)
	game.world.enter_building(Content.table("hub").buildings[0])
	await walk_to(game.world.geometry.position+Vector3(0,0,-1.4))
	game.world.interact()
	check(game.ui.screen == "service","Deliberate counter interaction still requires E")
	print("DOORWAYS: ",failures.size()," failures")
	game.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
