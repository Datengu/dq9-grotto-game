extends SceneTree
var game: Node
var failures: Array = []
var steps = 0
var battles = 0
var captures = false

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
	else: print("PASS: " + message)

func capture(name: String) -> void:
	if not captures: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/"+name+".png")

func click_text(text: String, node: Node = null) -> bool:
	if node == null: node = game.ui.root
	if node is Button and text in node.text and not node.disabled:
		node.pressed.emit()
		return true
	for child in node.get_children():
		if click_text(text,child): return true
	return false

func walk_to(target: Vector2i) -> void:
	var queue = [game.world.player]
	var came = {game.world.player:game.world.player}
	var head = 0
	while head < queue.size() and not came.has(target):
		var p: Vector2i = queue[head]
		head += 1
		for delta in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var n: Vector2i = p + delta
			if not came.has(n) and game.world.walkable(n):
				came[n] = p
				queue.append(n)
	if not came.has(target):
		check(false,"Playthrough route reachable: " + str(target))
		return
	var path: Array = []
	var p = target
	while p != game.world.player:
		path.push_front(p)
		p = came[p]
	for next_pos in path:
		game.world.step(next_pos-game.world.player)
		steps += 1
		if game.battle != null:
			await fight()
			if game.world.mode != "dungeon": return
		await process_frame

func fight() -> void:
	battles += 1
	if battles == 1: await capture("combat")
	var turns = 0
	while game.battle != null and turns < 100:
		var p = game.state.player
		var action = "1  Attack"
		if p.hp < 35:
			if p.mp >= 5: action = "3  Mend"
			elif p.inventory.get("salve",0) > 0: action = "Moss salve"
			else: action = "4  Guard"
		elif game.battle.enemy.boss and p.mp >= 9: action = "2  Spark"
		check(click_text(action),"Combat button available: "+action)
		turns += 1
		await process_frame
	check(turns < 100,"Battle resolves within turn limit")
	check(game.world.mode == "dungeon","Surveyor survives combat")
	if game.ui.screen == "reward":
		await capture("new-map")
		game.ui.close()

func run() -> void:
	captures = not DisplayServer.get_name() == "headless"
	DirAccess.make_dir_recursive_absolute("res://test-output")
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.state.maps.is_empty(),"Fresh character starts in physical hub without maps")
	await capture("hub")
	await walk_to(Vector2i(13,7))
	game.world.interact()
	check(game.ui.screen == "board","Walking to physical bulletin board opens quests")
	await capture("board")
	check(click_text("Accept commission"),"Accept first board commission through UI")
	check(game.state.maps.size() == 1 and game.ui.screen == "reward","Map acquisition announces permanent chart")
	await capture("first-map")
	game.ui.close()
	game.world.interact()
	check(click_text("Accept commission"),"Accept depth commission")
	check(click_text("Accept commission"),"Accept hunt commission")
	game.ui.close()
	await walk_to(Vector2i(5,7))
	game.world.interact()
	check(game.world.mode == "interior","Shop has physical interior")
	await walk_to(Vector2i(13,9))
	game.world.interact()
	await capture("shop")
	check(click_text("Buy · 65"),"Buy copper sabre at counter")
	game.ui.close()
	game.ui.show_inventory()
	# First unequipped item button is the purchased weapon.
	check(click_text("Equip"),"Equip purchased weapon")
	check(game.state.player.equipment.weapon == "copper_sabre","Copper sabre equipped")
	game.ui.close()
	game.ui.show_book()
	check(click_text(game.state.maps[0].meta.name),"Empty search displays discovered map in atlas list")
	await capture("atlas")
	var meta = game.state.maps[0].meta.duplicate(true)
	var structure = GrottoGenerator.generate(meta)
	check(click_text("Begin expedition"),"Launch expedition from atlas")
	check(game.world.mode == "dungeon" and game.floors == structure,"Travel uses persistent map generator")
	await capture("dungeon")
	while game.world.mode == "dungeon" and game.floor_index < int(meta.depth):
		var index = game.floor_index
		var data = game.floors[index]
		# Explore and fight each visible enemy, testing viable starter balance.
		for enemy in data.enemies:
			await walk_to(Vector2i(enemy.pos[0],enemy.pos[1]))
			if game.world.mode != "dungeon": break
		if game.world.mode != "dungeon": break
		for chest in data.chests:
			await walk_to(Vector2i(chest.pos[0],chest.pos[1]))
			game.world.interact()
		if index == 2: await capture("treasure-floor")
		await walk_to(Vector2i(data.stairs[0],data.stairs[1]))
		game.world.interact()
		check(game.floor_index == index+1,"Stairs descend to next generated floor")
		if game.floor_index == index: break
	check(game.world.mode == "dungeon" and game.floor_index == meta.depth,"Keeper floor reached")
	if game.world.mode == "dungeon":
		await walk_to(Vector2i(17,9))
		await capture("keeper-chamber")
		game.world.interact()
		if game.battle != null: await fight()
	check(game.state.maps.size() >= 2,"Keeper awards another permanent treasure map")
	check(game.state.maps[0].clears == 1,"Original map marked completed")
	check(not game.state.maps[0].treasure.is_empty(),"Treasure remembered in atlas")
	game.return_home()
	await walk_to(Vector2i(13,7))
	game.world.interact()
	check(click_text("Claim reward"),"Turn in completed first commission at physical board")
	check(click_text("Claim reward"),"Turn in completed depth commission for map")
	game.ui.close()
	check(game.state.maps.size() >= 3,"Atlas retains old map plus boss and quest rewards")
	game.ui.show_book()
	await capture("atlas-after-expedition")
	check(click_text(meta.name),"Select original map in atlas")
	check(click_text("Begin expedition"),"Revisit original map")
	check(game.active_map.meta.id == meta.id,"Revisit targets original map identity")
	check(game.floors == structure,"Revisit recreates exactly the same underlying dungeon")
	check(game.floor_progress[0].defeated.is_empty(),"Wandering enemies reset on new expedition")
	game.return_home()
	var save_path = "res://test-output/playthrough-save.json"
	check(SaveStore.write(game.state,save_path),"Save completed playthrough")
	var reloaded = GameState.new()
	check(SaveStore.read(reloaded,save_path),"Reload completed playthrough")
	check(reloaded.maps.size() == game.state.maps.size() and reloaded.maps[0].clears == 1,"Reload retains collection and completion")
	var file = FileAccess.open("res://test-output/playthrough-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"steps":steps,"battles":battles,"maps":game.state.maps.size(),"level":game.state.player.level,"hp":game.state.player.hp,"captures":captures},"\t"))
	file.close()
	print("PLAYTHROUGH: %d failures, %d steps, %d battles, %d maps" % [failures.size(),steps,battles,game.state.maps.size()])
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
