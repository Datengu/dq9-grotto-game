extends SceneTree
var game: Node
var failures: Array = []
var frames_walked = 0
var battles = 0
var captures = false
var chasing_seen = false

func _init(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failures.append(message); push_error(message)
	else: print("PASS: "+message)
func capture(name: String):
	if not captures: return
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(TestOutput.path(name+".png")) == OK,"Capture "+name)
func click_text(text: String, node: Node = null) -> bool:
	if node == null: node = game.ui.root
	if node is Button and text in node.text and not node.disabled:
		node.pressed.emit()
		return true
	for child in node.get_children():
		if click_text(text,child): return true
	return false
func stop():
	game.world.leader.desired = Vector3.ZERO
	for i in 14: await physics_frame

func exit_building():
	await walk_to(game.world.geometry.position+Vector3(0,0,7.2))
	game.world.leader.command_override = true
	game.world.leader.desired = Vector3.BACK
	for i in 90:
		await physics_frame
		if game.world.mode == "hub": return
	check(false,"Walking through doorway exits automatically")

func walk_to(target: Vector3, reach: float = 0.2):
	if game.world.nav is SurfaceNavigation:
		for i in 30:
			if game.world.nav.ready(): break
			await physics_frame
	var version = game.world.map_version
	var path = game.world.nav.path(game.world.leader.global_position,target)
	if path.is_empty():
		print("NAV DIAGNOSTIC ",game.world.mode," start=",game.world.leader.position," goal=",target)
		if game.world.nav is SurfaceNavigation: print("NAV ready=",game.world.nav.ready()," polygons=",game.world.nav.navigation_mesh.get_polygon_count()," nearest=",game.world.nav.closest(target))
		check(false,"Navigation route exists: "+str(target)); return
	game.world.leader.command_override = true
	for waypoint in path:
		var ticks = 0
		while flat_distance(game.world.leader.global_position,waypoint) > 0.18:
			if flat_distance(game.world.leader.global_position,target) <= reach: await stop(); return
			if game.world.map_version != version: return
			if game.battle != null:
				await fight()
				if game.world.map_version != version: return
			for brain in game.world.enemies.values():
				if brain.mode == "chase": chasing_seen = true
			var offset = waypoint-game.world.leader.global_position; offset.y = 0
			game.world.leader.desired = offset.normalized()*minf(1,offset.length()/0.3)
			await physics_frame
			frames_walked += 1; ticks += 1
			if captures and game.world.mode == "dungeon" and frames_walked%600 == 0: await capture("moving-%d" % frames_walked)
			if ticks > 300:
				check(false,"Physical route blocked at "+str(game.world.leader.global_position)+" toward "+str(waypoint))
				await stop(); return
	await stop()
func flat_distance(a: Vector3,b: Vector3) -> float: return Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))
func cell_target(p: Array) -> Vector3: return Vector3(p[0]*game.world.tile_size,0,p[1]*game.world.tile_size)

func fight():
	battles += 1
	await stop()
	if battles == 1: await capture("combat-3d")
	var turns = 0
	while game.battle != null and turns < 120:
		var action = BalanceStrategy.choose(game.battle)
		var prefix = {"attack":"1  Attack","spark":"2  Spark","mend":"3  Mend","guard":"4  Guard"}.get(action,"")
		if action.begins_with("item:"): prefix = Content.item(action.substr(5)).name
		check(click_text(prefix),"Combat action via UI: "+action)
		turns += 1
		await process_frame
	check(turns < 120,"Combat resolves")
	check(game.world.mode == "dungeon","Prepared surveyor survives")
	if game.ui.screen == "reward": await capture("new-map-3d"); game.ui.close()

func run():
	captures = DisplayServer.get_name() != "headless"
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.state.maps.is_empty(),"Fresh hero in 3D town")
	check(game.world.leader is CharacterBody3D and game.world.followers.size() == 2,"Physical hero and two companions")
	check(game.world.camera.projection == Camera3D.PROJECTION_PERSPECTIVE,"Following perspective camera")
	await capture("hub-3d")
	await walk_to(cell_target([13,7]))
	game.world.interact()
	check(game.ui.screen == "board","Walk to physical board and interact")
	check(click_text("Accept commission"),"Accept map commission")
	check(game.state.maps.size() == 1 and game.ui.screen == "reward","Acquisition moment adds permanent map")
	game.ui.close()
	game.world.interact()
	check(click_text("Accept commission"),"Accept depth commission")
	check(click_text("Accept commission"),"Accept hunt commission")
	game.ui.close()
	await walk_to(cell_target([5,6]),0.8)
	game.world.interact()
	check(game.world.mode == "interior","Physical shop entrance transitions inside")
	await walk_to(game.world.geometry.position+Vector3(0,0,-1.4))
	await capture("interior-3d")
	game.world.interact()
	check(click_text("Buy · 65"),"Buy copper sabre at counter")
	game.ui.close()
	game.ui.show_inventory()
	check(click_text("Equip"),"Equip new weapon")
	game.ui.close()
	await exit_building()
	check(game.world.mode == "hub","Exit shop to correct town door")
	game.ui.show_book()
	var entry = game.state.maps[0]
	var meta = entry.meta.duplicate(true)
	check(click_text(meta.name),"Atlas selects acquired chart")
	await capture("atlas-3d")
	var original = GrottoGenerator.generate(meta)
	check(click_text("Begin expedition"),"Expedition through atlas UI")
	check(game.floors == original,"Persistent seed generates expedition")
	game.world.population.rng = SeedRng.new(2007)
	check(game.world.enemies.is_empty(),"Floor starts without pre-instantiating fixed enemies")
	await capture("dungeon-3d")
	for i in 420:
		await physics_frame
		if not game.world.enemies.is_empty(): break
	var initial_positions: Dictionary = {}
	for id in game.world.enemies: initial_positions[id] = game.world.enemies[id].actor.position
	for i in 180: await physics_frame
	var roaming = false
	for id in game.world.enemies:
		if initial_positions.has(id) and game.world.enemies[id].actor.position.distance_to(initial_positions[id]) > 0.3: roaming = true
	check(roaming,"Visible enemies physically wander")
	var chest_count = 0
	for index in int(meta.depth):
		if game.world.mode != "dungeon": break
		var data = game.floors[index]
		if index == 0 and not game.world.enemies.is_empty():
			var enemy = game.world.enemies.values()[0]
			await walk_to(enemy.actor.position)
			if game.battle != null: await fight()
		for chest in data.chests:
			await walk_to(cell_target(chest.pos),1.1)
			if game.battle != null: await fight()
			game.world.interact()
			check(game.ui.screen == "chest_reward","Chest pauses for acknowledged item acquisition")
			if game.ui.screen == "chest_reward":
				chest_count += 1
				await capture("chest-reward-3d")
				var before = game.world.leader.position
				game.world.leader.desired = Vector3.FORWARD
				for tick in 15: await physics_frame
				check(game.world.leader.position.distance_to(before) < 0.01,"Reward freezes exploration")
				check(click_text("Continue exploration"),"Acknowledge treasure")
		game.ui.map_visible = true
		if index == 2: await capture("treasure-floor-3d")
		await walk_to(cell_target(data.stairs),0.4)
		if game.battle != null: await fight()
		game.world.interact()
		check(game.floor_index == index+1,"Physical stairs descend")
		if game.floor_index == index: break
	check(chest_count > 0,"Chest reward earned")
	check(chasing_seen and battles > 0,"Enemies detect, pursue and initiate contact encounter")
	if game.world.mode == "dungeon" and game.floor_index == int(meta.depth):
		await walk_to(cell_target(game.world.floor_data.boss),2.0)
		await capture("keeper-chamber-3d")
		game.world.interact()
		if game.battle != null: await fight()
	check(entry.clears == 1 and game.state.maps.size() >= 2,"Keeper rewards new map; original retained")
	game.return_home()
	await walk_to(cell_target([13,7]))
	game.world.interact()
	check(click_text("Claim reward"),"Claim first commission at board")
	check(click_text("Claim reward"),"Depth commission awards map")
	game.ui.close()
	check(game.state.maps.size() >= 3,"Collection includes boss and quest maps")
	var explored = entry.explored.duplicate(true)
	game.begin_expedition(entry)
	check(game.floors == original,"Revisit reproduces original structure")
	check(entry.explored == explored and not game.world.discovered.is_empty(),"Revisit keeps explored map")
	check(game.floor_progress[0].opened.is_empty() and game.floor_progress[0].defeated.is_empty(),"Fresh expedition replenishes treasure and encounters")
	game.return_home()
	check(SaveStore.write(game.state,TestOutput.path("playthrough-save.json")),"Save complete expedition")
	var loaded = GameState.new()
	check(SaveStore.read(loaded,TestOutput.path("playthrough-save.json")),"Reload save")
	check(loaded.maps.size() == game.state.maps.size() and loaded.maps[0].explored == explored,"Reload retains atlas, fog and completion")
	var file = FileAccess.open(TestOutput.path("playthrough-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"physics_movement_frames":frames_walked,"battles":battles,"maps":game.state.maps.size(),"level":game.state.player.level,"hp":game.state.player.hp,"chasing":chasing_seen,"captures":captures},"\t"))
	print("PLAYTHROUGH: ",failures.size()," failures, ",frames_walked," movement frames, ",battles," battles")
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
