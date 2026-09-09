extends "res://tests/playthrough_3d.gd"
var maintain = false
var observed_spawns = 0
var cap_violations = 0
var spawn_violations = 0

func population_tick():
	if not maintain or game.world.mode != "dungeon": return
	var before = game.world.enemies.keys()
	game.world.update_population(1.0/Engine.physics_ticks_per_second)
	var pop = game.world.population
	if game.world.enemies.size() > pop.config.active_cap: cap_violations += 1
	for id in game.world.enemies:
		if before.has(id): continue
		observed_spawns += 1
		var pos = game.world.enemies[id].actor.position
		var distance = flat_distance(pos,game.world.leader.position)
		if distance < pop.config.minimum_spawn_distance-0.01 or distance > pop.config.maximum_spawn_distance+0.01: spawn_violations += 1
		if pop.visibly_exposed(pos,[game.world.leader],game.world.camera,game.world.nav): spawn_violations += 1
		if not pop.pool.has(game.world.encounters[id]): spawn_violations += 1

func run():
	game = load("res://src/main.tscn").instantiate(); root.add_child(game)
	var entry = game.state.add_map(GrottoGenerator.create(123456,150,150),"Population validation")
	game.begin_expedition(entry)
	game.world.authority_enabled = false
	game.world.population.rng = SeedRng.new(7741)
	var structure = JSON.stringify(game.floors)
	check(game.world.enemies.is_empty(),"No permanent whole-floor pre-spawn")
	maintain = true
	physics_frame.connect(population_tick)
	for i in 1000: await physics_frame
	check(game.world.enemies.size() > 0,"A local eligible population appears")
	var initial_ids = game.world.enemies.keys()
	var initial = game.world.leader.position
	var farthest = initial
	for y in int(game.world.floor_data.height):
		for x in int(game.world.floor_data.width):
			if game.world.nav.walkable(Vector2i(x,y)):
				var pos = game.world.nav.world(Vector2i(x,y))
				if flat_distance(pos,initial) > flat_distance(farthest,initial): farthest = pos
	await walk_to(game.world.nav.closest(farthest),0.4)
	for i in 500: await physics_frame
	check(flat_distance(game.world.leader.position,initial) > 26,"Player physically traverses beyond initial activity area")
	check(game.world.population.despawned > 0,"Distant runtime enemies despawn during travel")
	check(game.world.population.spawned > initial_ids.size(),"Population replenishes around the moving player")
	check(observed_spawns > 4 and cap_violations == 0,"Active cap holds throughout local replenishment")
	check(spawn_violations == 0,"Spawns obey radii, species/rank eligibility and camera exclusion")
	for brain in game.world.enemies.values(): check(flat_distance(brain.actor.position,game.world.leader.position) <= 26.1,"No residents remain out of activity scope")
	check(JSON.stringify(game.floors) == structure,"Runtime population never mutates permanent floor data")
	maintain = false
	game.return_home()
	game.begin_expedition(entry)
	check(JSON.stringify(game.floors) == structure and game.world.enemies.is_empty(),"Revisit retains structure and starts a fresh runtime population")
	# Eligibility is metadata driven, including unusual floor restrictions.
	for environment in Content.table("generation").environments:
		for rank in [1,6,12]:
			var metadata = {"environment":environment}
			var data = {"rank":rank,"boss":[],"unusual":""}
			var pool = Content.encounter_pool(metadata,data)
			check(pool.size() == 3 and pool.all(func(e): return e.rank == rank),"Environment/rank pool: "+environment+str(rank))
			data.unusual = "Lumen colony"
			check(Content.encounter_pool(metadata,data) == [{"rank":rank,"variant":2,"rare":true}],"Unusual population eligibility preserved")
			data.boss = [4,4]
			check(Content.encounter_pool(metadata,data).is_empty(),"No roaming population in keeper chamber")
	var file = FileAccess.open(TestOutput.path("population-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"spawns_observed":observed_spawns,"cap_violations":cap_violations,"spawn_violations":spawn_violations},"\t"))
	print("POPULATION: ",observed_spawns," observed spawns, ",failures.size()," failures")
	game.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
