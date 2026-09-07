extends SceneTree
var checks = 0
var failures: Array = []
var distributions: Dictionary = {"depth":{},"monster_rank":{},"boss_tier":{},"chest_rank":{},"environment":{},"unusual":0,"invalid":0,"floors":0}

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func tally(key: String, value: Variant) -> void:
	var name = str(value)
	distributions[key][name] = int(distributions[key].get(name,0)) + 1

func _init() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-output")
	var count = 1000
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--count="): count = int(arg.substr(8))
	var start = Time.get_ticks_msec()
	check(SeedRng.new(0).next() == 48271,"RNG golden vector")
	for fixture in [[0,2,"0c937bf95af6c74ad11e421ef908441ec081677101a09159394955aa82e7d91b"],[123456,248,"c182daad4a908bfaa9dc8365d9f2ad1b40619c9a8a908f533dfa36fe8f2f7c83"],[54321,120,"b4ba448d07903067a831a3da1d7d7dbddc032aa7bc19895f15042e053f3d4512"]]:
		var fixed = GrottoGenerator.create(fixture[0],fixture[1],fixture[1])
		check(JSON.stringify(GrottoGenerator.generate(fixed)).sha256_text() == fixture[2],"Version-one geometry fingerprint remains unchanged")
	var starter = QuestSystem.starter()
	check(starter.depth == 3 and starter.starting_monster_rank == 1 and starter.boss_tier == 1,"Starter has approachable three-floor expedition")
	var original = GrottoGenerator.generate(starter)
	check(original == GrottoGenerator.generate(starter),"Repeated generation matches exactly")
	var alternate = GrottoGenerator.generate(GrottoGenerator.create(9999,2,2))
	check(original != alternate,"Different seeds produce different structures")
	# Sweep every quality threshold at least once; all floors flood-filled.
	for i in count:
		var quality = 2 + i % 247
		var meta = GrottoGenerator.create(i * 7919,quality,quality)
		var floors = GrottoGenerator.generate(meta)
		tally("depth",meta.depth)
		tally("boss_tier",meta.boss_tier)
		tally("environment",meta.environment)
		check(floors.size() == meta.depth + 1,"Boss floor exists: %s" % meta.id)
		check(meta.displayed_level >= 1 and meta.displayed_level <= 99,"Displayed level bounds")
		var bracket = Content.table("generation").quality_brackets[meta.grotto_rank-1]
		check(meta.depth >= bracket[1] and meta.depth <= bracket[2],"Depth bracket")
		check(meta.starting_monster_rank >= bracket[3] and meta.starting_monster_rank <= bracket[4],"Starting monster bracket")
		check(meta.boss_tier >= bracket[5] and meta.boss_tier <= bracket[6],"Boss eligibility")
		for f in floors:
			distributions.floors += 1
			tally("monster_rank",f.rank)
			if f.unusual != "": distributions.unusual += 1
			var reached = FloorGenerator.reachable(f.tiles,f.entrance)
			check(reached.size() == f.tiles.count(1),"All floor tiles connected: %s B%d" % [meta.id,f.index+1])
			check(f.rank >= 1 and f.rank <= 12,"Enemy rank bounds")
			check(f.rank == mini(12,meta.starting_monster_rank + int(f.index/4)),"Rank steps every four floors")
			var occupied = {str(f.entrance):true}
			var target = f.stairs if f.index < meta.depth else f.boss
			check(target.size() == 2,"Required stair or boss exists")
			if target.size() == 2:
				check(reached.has(int(target[1])*35+int(target[0])),"Entrance reaches stairs / boss")
				check(target != f.entrance,"Stairs distinct")
				occupied[str(target)] = true
			check(f.chests.size() == 0 if f.index < 2 or f.index == meta.depth else f.chests.size() >= 1 and f.chests.size() <= 3,"Chest floor/count rules")
			for chest in f.chests:
				tally("chest_rank",chest.rank)
				var bounds = Content.table("generation").chest_ranges[f.rank-1]
				check(chest.rank >= bounds[0] and chest.rank <= bounds[1],"Valid chest rank for monster rank")
				check(reached.has(int(chest.pos[1])*35+int(chest.pos[0])),"Chest reachable")
				check(not occupied.has(str(chest.pos)),"Chest has exclusive position")
				occupied[str(chest.pos)] = true
			for enemy in f.enemies:
				check(enemy.rank == f.rank,"Encounter matches floor rank")
				check(reached.has(int(enemy.pos[1])*35+int(enemy.pos[0])),"Enemy reachable")
				check(not occupied.has(str(enemy.pos)),"Enemy has exclusive position")
				occupied[str(enemy.pos)] = true
		if i % 100 == 0: print("Generated and checked %d / %d grottos" % [i,count])
	test_state(starter,original)
	test_combat()
	# Acquire quality distribution at progression endpoints and rounding corner.
	for base in [2,55,60,75,80,100,120,140,160,180,200,220,248,152]:
		for i in 100:
			var q = GrottoGenerator.final_quality(base,SeedRng.new(i*99991))
			check(q >= 2 and q <= 248,"Final quality clamping")
			if base == 152: check(q >= 137 and q <= 166,"Documented quality rounding quirk")
	check(GrottoGenerator.base_quality(99,10,99) == 248,"Max progression quality")
	check(GrottoGenerator.base_quality(20,0,10) == 30,"Hero and completed map influence quality")
	distributions.invalid = failures.size()
	var report = {"grottos":count,"checks":checks,"failures":failures,"duration_ms":Time.get_ticks_msec()-start,"distributions":distributions}
	var file = FileAccess.open("res://test-output/generation-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("RESULT: %d checks, %d failures, %d grottos, %d floors, %.2f seconds" % [checks,failures.size(),count,distributions.floors,(Time.get_ticks_msec()-start)/1000.0])
	quit(0 if failures.is_empty() else 1)

func test_state(starter: Dictionary, original: Array) -> void:
	var state = GameState.new()
	var map = QuestSystem.accept(state,"first_light")
	check(not map.is_empty() and state.maps.size() == 1,"Board quest reveals first permanent map")
	QuestSystem.accept(state,"first_light")
	check(state.maps.size() == 1,"Quest acceptance is idempotent")
	QuestSystem.accept(state,"deep_steps")
	QuestSystem.event(state,"depth",3)
	check(not QuestSystem.claim(state,"deep_steps").is_empty(),"Completed survey awards map")
	var gold = state.player.gold
	check(QuestSystem.claim(state,"deep_steps").is_empty() and state.player.gold == gold,"Rewards cannot be claimed twice")
	map.favourite = true
	map.visits = 3
	map.clears = 1
	map.notes = "A useful vault"
	map.treasure.append("B3 rank 2")
	check(SaveStore.write(state,"res://test-output/test-save.json"),"Save writes")
	check(SaveStore.write(state,"res://test-output/test-save.json"),"Save atomically replaces and creates backup")
	var loaded = GameState.new()
	check(SaveStore.read(loaded,"res://test-output/test-save.json"),"Versioned save loads")
	check(JSON.stringify(state.serialise()) == JSON.stringify(loaded.serialise()),"All persistent fields round-trip")
	check(loaded.maps.size() == 2 and loaded.maps[0].favourite and loaded.maps[0].visits == 3,"Atlas keeps maps, favourites and visits")
	check(loaded.maps[0].meta == starter,"Grotto metadata survives save/load")
	check(GrottoGenerator.generate(loaded.maps[0].meta) == original,"Loaded/revisited map has original structure")
	var invalid = state.serialise().duplicate(true)
	invalid.save_version = 999
	check(not loaded.restore(invalid),"Future save versions rejected")
	invalid = state.serialise().duplicate(true)
	invalid.player.inventory = []
	check(not loaded.restore(invalid),"Malformed inventory rejected before application")
	invalid = state.serialise().duplicate(true)
	invalid.maps[0].meta.depth = 99
	check(not loaded.restore(invalid),"Tampered map metadata rejected before generation")
	var damaged = FileAccess.open("res://test-output/test-save.json",FileAccess.WRITE)
	damaged.store_string("{broken")
	damaged.close()
	check(SaveStore.read(loaded,"res://test-output/test-save.json"),"Corrupt primary recovers backup")
	check(SaveStore.write(loaded,"res://test-output/test-save.json"),"Recovered game saves successfully")
	check(SaveStore.read(GameState.new(),"res://test-output/test-save.json.bak"),"Recovery does not overwrite valid backup with corrupt primary")
	check(state.trade("copper_sabre") and state.equip("copper_sabre"),"Buy and equip weapon")
	check(not state.trade("copper_sabre",true),"Equipped item cannot be sold")
	state.give("copper_sabre")
	check(state.trade("copper_sabre",true),"Can sell spare equipped weapon")
	state.player.hp = 20
	check(state.use_item("salve") and state.player.hp == 65,"Healing consumes item and restores HP")

func test_combat() -> void:
	var state = GameState.new()
	var fight = Combat.new(state,Content.monster("Cavern",1),42)
	state.player.mp = 0
	check(not fight.act("spark") and fight.turn == 0,"Unavailable ability cannot advance turn")
	check(fight.act("guard") and state.player.mp == 3,"Guard restores MP")
	state.rest()
	var turns = 0
	while fight.outcome == "" and turns < 30:
		fight.act("attack")
		turns += 1
	check(fight.outcome == "victory","Starter can defeat rank-one enemy")
	check(not fight.act("attack"),"Ended combat cannot advance")
	var boss = Combat.new(state,Content.boss(1),45)
	check(not boss.act("flee"),"Boss escape unavailable")
	state.player.hp = 1
	state.player.poison = 4
	state.rest()
	check(state.player.hp == state.stats().max_hp and state.player.poison == 0,"Inn resets HP MP and status")
