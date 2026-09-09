extends "res://tests/playthrough_3d.gd"

func run():
	captures = DisplayServer.get_name() != "headless"
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	# Every door/counter must be usable via physical movement, including return paths.
	for info in Content.table("hub").buildings:
		await walk_to(cell_target(info.door),0.8)
		game.world.interact()
		check(game.world.mode == "interior" and game.world.building.id == info.id,"Enter "+info.id)
		await walk_to(game.world.geometry.position+Vector3(0,0,-1.4))
		game.world.interact()
		check(game.ui.screen == "service","Approach service: "+info.id)
		if info.id == "inn": check(click_text("Rest until morning"),"Rest at physical inn")
		else: game.ui.close()
		await exit_building()
		check(game.world.mode == "hub","Return from "+info.id)
	var npc = game.world.npcs[0]
	await walk_to(npc.actor.position,1.3)
	game.world.interact()
	check(game.ui.screen == "dialogue","Patrolling NPC has contextual dialogue")
	await capture("dialogue-3d")
	game.ui.close()
	game.ui.show_camera_settings()
	await capture("camera-settings-3d")
	game.ui.close()
	# Controlled arena checks physical motion and collision independently of encounters.
	var tiles: Array = []; tiles.resize(20*16); tiles.fill(0)
	for y in range(1,15):
		for x in range(1,19): tiles[y*20+x] = 1
	for y in range(1,12): tiles[y*20+10] = 0
	var data = {"width":20,"height":16,"tiles":tiles,"entrance":[4,5],"stairs":[15,5],"enemies":[],"chests":[],"boss":[],"rank":1,"index":0,"unusual":""}
	var meta = GrottoGenerator.create(444,2,2)
	game.world.show_floor(data,meta,{"seen":{},"opened":[],"defeated":[],"boss_dead":false})
	game.world.authority_enabled = false
	var leader = game.world.leader
	leader.command_override = true
	for i in 20: await physics_frame
	leader.desired = Vector3.RIGHT
	await physics_frame; await physics_frame
	check(leader.velocity.x > 0 and leader.velocity.x < leader.speed,"Movement accelerates smoothly")
	for i in 30: await physics_frame
	check(absf(leader.velocity.x-leader.speed) < 0.01,"Stable cardinal movement speed")
	leader.desired = Vector3(1,0,1)
	for i in 30: await physics_frame
	check(absf(Vector2(leader.velocity.x,leader.velocity.z).length()-leader.speed) < 0.02,"Diagonal input does not move faster")
	await stop()
	check(leader.velocity.length() < 0.1,"Smooth deceleration reaches rest")
	await walk_to(cell_target([9,7]))
	leader.desired = Vector3.RIGHT
	for i in 120: await physics_frame
	check(leader.position.x < 10*game.world.tile_size-0.9,"Real wall collision stops character")
	await stop()
	await walk_to(cell_target([15,5]))
	for i in 100: await physics_frame
	check(flat_distance(leader.position,cell_target([15,5])) < 0.3,"Navigation goes around wall to destination")
	for follower in game.world.followers:
		check(follower.position.y > -0.1 and follower.position.distance_to(leader.position) < 4,"Followers traverse route without snapping or stranding")
	check(game.world.followers[0].position.distance_to(game.world.followers[1].position) > 0.7,"Followers retain spacing at rest")
	check(game.world.camera.anchor.distance_to(leader.position) < 0.1,"Follow camera settles on leader")
	check(not game.world.nav.visible_between(cell_target([9,5]),cell_target([11,5])),"Walls block enemy detection")
	var detour = game.world.nav.path(cell_target([9,5]),cell_target([11,5]))
	var route_length = 0.0
	for i in range(1,detour.size()): route_length += detour[i-1].distance_to(detour[i])
	check(detour.size() > 2 and route_length > 20 and flat_distance(detour[-1],cell_target([11,5])) < 0.3,"Enemy surface route follows opening around geometry")
	# Drive the real brain/body along that detour, not just the path query.
	var walker = game.world.spawn_actor("route-enemy",cell_target([9,5]),Color("ac9874"),"wolf")
	walker.role = "enemy"
	var roaming_brain = EnemyBrain.new(); roaming_brain.setup(walker.actor_id,walker,64,1)
	var endpoint = game.world.nav.closest(cell_target([11,5])+Vector3(0.17,0,0.31))
	roaming_brain.grace = 999; roaming_brain.mode = "wander"
	roaming_brain.route = game.world.nav.path(walker.position,endpoint)
	var largest_step = 0.0; var non_grid_samples = 0; var moving_samples = 0
	for tick in 1400:
		var before = walker.position
		roaming_brain.update(1.0/60.0,game.world.actors,game.world.nav)
		await physics_frame
		var step = flat_distance(before,walker.position)
		largest_step = maxf(largest_step,step)
		if step > 0.001:
			moving_samples += 1
			if absf(walker.position.x/1.8-roundf(walker.position.x/1.8)) > 0.02 and absf(walker.position.z/1.8-roundf(walker.position.z/1.8)) > 0.02: non_grid_samples += 1
		if roaming_brain.mode == "idle": break
	check(flat_distance(walker.position,endpoint) < 0.3,"Enemy body follows a wall detour to an arbitrary endpoint")
	check(largest_step < 0.1 and moving_samples > 100 and non_grid_samples > moving_samples/2,"Enemy motion is continuous and occupies space between grid axes")
	game.world.actors.erase(walker.actor_id); walker.queue_free()
	var actor = game.world.spawn_actor("test-enemy",cell_target([15,8]),Color("ac9874"),"wolf")
	actor.role = "enemy"
	var brain = EnemyBrain.new(); brain.setup(actor.actor_id,actor,23,1); brain.grace = 0
	brain.update(0.1,game.world.actors,game.world.nav)
	check(brain.mode == "chase" and brain.target_id == leader.actor_id,"Detection targets actor identity")
	# A host could supply a different player registry; local leader is not hardcoded.
	var second = game.world.spawn_actor("player-2",cell_target([15,9]),Color("789dac"))
	brain.disengage(); brain.grace = 0
	brain.update(0.1,{"player-2":second},game.world.nav)
	check(brain.target_id == "player-2","AI supports another player actor without networking")
	brain.chase_time = 11
	brain.update(0.1,{"player-2":second},game.world.nav)
	check(brain.mode != "chase","Pursuit expires and returns to wandering")
	brain.disengage()
	check(brain.grace > 0 and actor.desired == Vector3.ZERO,"Flee grants physical disengagement time")
	check(game.world.snapshot().actors.size() == 5,"Runtime snapshot separates actor state from seeded geometry")
	var obstruction = Node3D.new(); game.world.geometry.add_child(obstruction)
	obstruction.add_to_group("camera_occlusion_cluster")
	WorldGeometry.box(obstruction,leader.position+Vector3(0,1.4,1.4),Vector3(3,2.8,0.35),Color("6a7772"),true)
	for i in 15: await physics_frame
	check(not game.world.camera.occlusion.faded.is_empty(),"Occluding scenery fades to keep leader visible")
	await capture("camera-occlusion-3d")
	var file = FileAccess.open(TestOutput.path("exploration-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"physics_movement_frames":frames_walked},"\t"))
	print("EXPLORATION: ",failures.size()," failures")
	game.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
