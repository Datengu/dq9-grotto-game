extends SceneTree
var failures: Array = []
func _init(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failures.append(message); push_error(message)
	else: print("PASS: "+message)
func run():
	for f in [[0,2,"46115e5c7ba4e0a0768faa063c11236e12d4a9a61b5094217cd25ac049718581"],[123456,248,"373d16f09ee17021f3f38ee2cb048d7f6964f205620145fb55552621b1be81a9"],[54321,120,"e401a07ca5b98fa765aecc1a1ff1f3375f95ff62c21d829af40f03070c2736cf"]]:
		check(JSON.stringify(GrottoGenerator.generate(GrottoGenerator.create(f[0],f[1],f[1],2))).sha256_text() == f[2],"Version-two geometry fingerprint")
	var old = GameState.new()
	old.add_map(GrottoGenerator.create(54321,120,120,1),"legacy chart")
	old.maps[0].favourite = true; old.maps[0].notes = "A place worth keeping"
	var structure = GrottoGenerator.generate(old.maps[0].meta)
	var data = old.serialise().duplicate(true)
	data.save_version = 1
	data.maps[0].erase("explored")
	var migrated = GameState.new()
	check(migrated.restore(JSON.parse_string(JSON.stringify(data))),"Actual v1 schema loads without explored field")
	check(migrated.maps[0].meta == old.maps[0].meta,"Old map identity and metadata unchanged")
	check(migrated.maps[0].notes == old.maps[0].notes and migrated.maps[0].favourite,"Migration preserves player knowledge")
	check(GrottoGenerator.generate(migrated.maps[0].meta) == structure,"Migrated map recreates v1 structure")
	migrated.add_map(GrottoGenerator.create(54321,120,120),"new graph chart")
	check(migrated.maps.size() == 2,"Both generator versions coexist in collection")
	migrated.maps[0].explored = {"0":{"44":true,"45":true}}
	check(SaveStore.write(migrated,"res://test-output/migration-save.json"),"Write upgraded versioned save")
	var loaded = GameState.new()
	check(SaveStore.read(loaded,"res://test-output/migration-save.json"),"Reload mixed-version collection")
	check(loaded.maps[0].explored == migrated.maps[0].explored,"Discovered fog survives save/load")
	check(GrottoGenerator.generate(loaded.maps[0].meta) == structure,"Old layout survives upgraded save")
	var world = ExplorationWorld.new(); root.add_child(world)
	world.show_floor(structure[0],old.maps[0].meta,{"seen":{},"opened":[],"defeated":[],"boss_dead":false})
	for i in 20: await physics_frame
	check(world.leader.position.y > -0.1 and world.floor_data == structure[0],"Old v1 chart renders with physical 3D floor and actors")
	world.queue_free(); await process_frame
	print("VERSIONS: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
