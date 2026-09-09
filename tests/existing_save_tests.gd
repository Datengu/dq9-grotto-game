extends "res://tests/playthrough_3d.gd"
func run():
	var fixture = OS.get_environment("LANTERN_VALIDATION_SAVE")
	if fixture.is_empty() or not FileAccess.file_exists(fixture):
		check(false,"Supply a read-only v0.2 save fixture with LANTERN_VALIDATION_SAVE")
		quit(1); return
	var original_hash = FileAccess.get_sha256(fixture)
	var old = GameState.new()
	check(SaveStore.read(old,fixture),"Existing v0.2 campaign loads")
	if old.maps.is_empty(): check(false,"Existing campaign has a chart to revisit"); quit(1); return
	var metadata: Array = []
	for entry in old.maps: metadata.append(entry.meta.duplicate(true))
	var inventory = old.player.inventory.duplicate(true)
	game = load("res://src/main.tscn").instantiate(); root.add_child(game)
	game.state = old
	game.ui.update_hud(); game.ui.show_book()
	captures = DisplayServer.get_name() != "headless"
	await capture("existing-save-atlas")
	game.ui.close()
	var entry = old.maps[0]
	var structure = GrottoGenerator.generate(entry.meta)
	game.begin_expedition(entry)
	game.world.authority_enabled = false
	await walk_to(cell_target(structure[0].stairs),0.4)
	check(flat_distance(game.world.leader.position,cell_target(structure[0].stairs)) < 0.6,"Existing chart can be physically traversed")
	check(game.floors == structure,"Existing chart structure retained")
	await capture("existing-save-grotto")
	game.return_home()
	var copy_path = TestOutput.path("existing-save-roundtrip.json")
	check(SaveStore.write(old,copy_path),"Save continued campaign to isolated copy")
	var reloaded = GameState.new()
	check(SaveStore.read(reloaded,copy_path),"Reload continued v0.2 campaign")
	check(reloaded.player.inventory == inventory,"Existing inventory survives continuation")
	check(reloaded.maps.size() == metadata.size(),"Existing chart collection retained")
	for i in metadata.size(): check(reloaded.maps[i].meta == metadata[i],"Existing chart identity retained")
	check(FileAccess.get_sha256(fixture) == original_hash,"Input save remains untouched")
	print("EXISTING SAVE: ",failures.size()," failures; ",metadata.size()," retained charts")
	game.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
