class_name EncounterPopulation
extends RefCounted
## Produces runtime spawn/despawn decisions; never modifies generated floor data.
var config: Dictionary
var pool: Array = []
var rng: SeedRng
var timer = 0.0
var spawned = 0
var despawned = 0
var rejected_visible = 0
var excluded_positions: Array[Vector3] = []
var next_observer = 0

func setup(meta: Dictionary, floor_data: Dictionary, seed_value: int, tile_size: float = 1.8) -> void:
	config = Content.table("encounters").duplicate(true)
	rng = SeedRng.new(seed_value)
	pool = Content.encounter_pool(meta,floor_data)
	for p in [floor_data.entrance,floor_data.stairs]:
		if p.size() == 2: excluded_positions.append(Vector3(p[0]*tile_size,0,p[1]*tile_size))
	for chest in floor_data.chests: excluded_positions.append(Vector3(chest.pos[0]*tile_size,0,chest.pos[1]*tile_size))

func distance_to_players(pos: Vector3, players: Array) -> float:
	var best = INF
	for player in players: best = minf(best,Vector2(pos.x-player.position.x,pos.z-player.position.z).length())
	return best

func desired_count(players: Array, nav: SurfaceNavigation) -> int:
	var cells: Dictionary = {}
	var extent = ceili(config.activity_radius/nav.tile_size)
	for player in players:
		var origin = nav.cell(player.position)
		for y in range(origin.y-extent,origin.y+extent+1):
			for x in range(origin.x-extent,origin.x+extent+1):
				var p = Vector2i(x,y)
				if nav.walkable(p) and nav.world(p).distance_to(player.position) <= config.activity_radius: cells[p] = true
	return clampi(ceili(cells.size()*nav.tile_size*nav.tile_size*config.density_per_square_metre),0,int(config.active_cap))

func visibly_exposed(pos: Vector3, players: Array, camera: Camera3D, nav: SurfaceNavigation) -> bool:
	if camera == null or not config.avoid_visible_spawns: return false
	if not camera.is_position_in_frustum(pos+Vector3(0,0.8,0)): return false
	for player in players:
		if nav.visible_between(player.position,pos): return true
	return false

func update(delta: float, players: Array, residents: Dictionary, camera: Camera3D, nav: SurfaceNavigation) -> Dictionary:
	var result = {"spawn":[],"despawn":[]}
	if players.is_empty() or not nav.ready() or pool.is_empty(): return result
	for id in residents:
		if distance_to_players(residents[id].actor.position,players) > config.despawn_radius:
			result.despawn.append(id)
			despawned += 1
	timer -= delta
	if timer > 0: return result
	timer = config.spawn_interval
	if residents.size()-result.despawn.size() >= desired_count(players,nav): return result
	var observer = players[next_observer%players.size()]
	next_observer += 1
	for attempt in int(config.candidate_attempts):
		var pos = nav.random_near(observer.position,config.minimum_spawn_distance,config.maximum_spawn_distance,rng)
		var distance = distance_to_players(pos,players)
		if distance < config.minimum_spawn_distance or distance > config.maximum_spawn_distance: continue
		var route = nav.path(observer.position,pos)
		if route.is_empty() or Vector2(route[-1].x-pos.x,route[-1].z-pos.z).length() > 0.2: continue
		var crowded = false
		for resident in residents.values():
			if resident.actor.position.distance_to(pos) < config.minimum_enemy_spacing: crowded = true; break
		for excluded in excluded_positions:
			if pos.distance_to(excluded) < 2.0: crowded = true; break
		if crowded: continue
		if visibly_exposed(pos,players,camera,nav): rejected_visible += 1; continue
		result.spawn.append({"position":pos,"encounter":rng.pick(pool).duplicate(true)})
		spawned += 1
		break
	return result

func after_battle() -> void:
	timer = maxf(timer,config.post_battle_refill_delay)
