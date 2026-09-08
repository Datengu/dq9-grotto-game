class_name ExplorationWorld
extends Node3D
signal interaction(kind: String, payload: Variant)
signal moved
var mode = "hub"
var building: Dictionary = {}
var floor_data: Dictionary = {}
var meta: Dictionary = {}
var blocked = false
var floor_state: Dictionary = {}
var discovered: Dictionary = {}
var opened: Array = []
var defeated: Array = []
var boss_dead = false
var hint = ""
var hub = Content.table("hub")
var tile_size = 1.8
var leader: ExplorerActor
var followers: Array[ExplorerActor] = []
var actors: Dictionary = {}
var enemies: Dictionary = {}
var npcs: Array = []
var trail = FollowerTrail.new()
var nav = GridNavigation.new()
var camera: FollowCamera
var geometry: Node3D
var actor_root: Node3D
var environment: Environment
var targets: Array = []
var chest_models: Array = []
var boss_model: ExplorerActor
var return_light: Node3D
var map_version = 0
var runtime_tick = 0
var encounter_grace = 2.0
var debug_ai = false
var authority_enabled = true
var test_motion = false
var last_reveal = Vector2i(-9999,-9999)
var npc_clock = 0.0

func _ready() -> void:
	tile_size = float(Content.table("exploration").tile_size)
	var world_environment = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("b2c2ba")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("cad5d2")
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_light_color = Color("91aaa8")
	environment.fog_density = 0.004
	world_environment.environment = environment
	add_child(world_environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-28,0)
	sun.light_color = Color("fff0d2")
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 50
	add_child(sun)
	camera = FollowCamera.new()
	add_child(camera)
	show_hub()

func clear_world() -> void:
	if is_instance_valid(geometry): remove_child(geometry); geometry.queue_free()
	if is_instance_valid(actor_root): remove_child(actor_root); actor_root.queue_free()
	geometry = Node3D.new()
	actor_root = Node3D.new()
	add_child(geometry)
	add_child(actor_root)
	actors.clear(); followers.clear(); enemies.clear(); npcs.clear(); targets.clear(); chest_models.clear()
	boss_model = null
	return_light = null
	last_reveal = Vector2i(-9999,-9999)
	encounter_grace = 2.0
	map_version += 1

func spawn_party(pos: Vector3) -> void:
	leader = spawn_actor("player-1",pos,Color("7597a2"))
	leader.controlled = true
	leader.camera = camera
	var settings = Content.table("exploration").movement
	leader.speed = settings.speed
	leader.acceleration = settings.acceleration
	leader.braking = settings.braking
	leader.turn_speed = settings.turn_speed
	leader.moved.connect(func(_id,_pos): moved.emit())
	var config = Content.table("exploration").followers
	trail.spacing = config.spacing
	trail.sample_distance = config.sample_distance
	trail.reset(pos)
	# Seed a short safe trail inside the spawn room; all followers use collision.
	for i in range(1,32):
		var p = pos-Vector3(i*0.1,0,0)
		if nav.walkable(nav.cell(p)): trail.points.append(p)
	for i in int(config.count):
		var follower = spawn_actor("follower-%d" % i,trail.target(i),Color("c29265") if i == 0 else Color("899970"))
		follower.role = "follower"
		followers.append(follower)
	camera.target = leader
	camera.configure(mode == "interior")
	camera.reset_tracking()

func spawn_actor(id: String, pos: Vector3, color: Color, kind: String = "human") -> ExplorerActor:
	var actor = ExplorerActor.new()
	actor.name = id
	actor.setup(id,color,kind)
	actor_root.add_child(actor)
	actor.position = pos+Vector3(0,0.05,0)
	actors[id] = actor
	return actor

func add_target(kind: String, payload: Variant, pos: Vector3, text: String, radius: float = 1.8) -> void:
	targets.append({"kind":kind,"payload":payload,"pos":pos,"label":"E  ·  "+text,"radius":radius})

func grid_for_hub() -> Dictionary:
	var tiles: Array = []
	tiles.resize(29*23); tiles.fill(1)
	for y in 23:
		for x in 29:
			if x < 1 or y < 1 or x > 25 or y > 17: tiles[y*29+x] = 0
	for b in hub.buildings:
		for y in range(b.rect[1],b.rect[1]+b.rect[3]):
			for x in range(b.rect[0],b.rect[0]+b.rect[2]): tiles[y*29+x] = 0
	for y in [11,12]:
		for x in [12,13,14]: tiles[y*29+x] = 0
	tiles[6*29+13] = 0
	return {"width":29,"height":23,"tiles":tiles}

func show_hub(return_door: Array = []) -> void:
	mode = "hub"
	clear_world()
	meta = {}; floor_data = {}; floor_state = {}; discovered = {}; opened = []; defeated = []; boss_dead = false
	environment.background_color = Color("b9c8be")
	environment.ambient_light_energy = 0.3
	environment.fog_density = 0.003
	nav.setup(grid_for_hub(),tile_size)
	HubGeometry.build(geometry,hub,tile_size)
	var spawn = Vector3(13*tile_size,0,9.5*tile_size)
	if not return_door.is_empty(): spawn = Vector3(return_door[0]*tile_size,0,(return_door[1]+0.7)*tile_size)
	spawn_party(spawn)
	add_target("board",0,Vector3(hub.board[0]*tile_size,0,hub.board[1]*tile_size),"Read expedition bulletin",2.3)
	for b in hub.buildings:
		add_target("door",b,Vector3(b.door[0]*tile_size,0,b.door[1]*tile_size),"Enter "+b.name.to_lower(),2.1)
	for i in hub.npcs.size():
		var info = hub.npcs[i]
		var npc = spawn_actor("npc-%d" % i,Vector3(info.pos[0]*tile_size,0,info.pos[1]*tile_size),Color(info.color))
		npc.role = "npc"
		npc.speed = 1.1
		var title = WorldGeometry.sign_text(npc,info.name,Vector3(0,2.0,0),27)
		npcs.append({"actor":npc,"info":info,"step":0,"title":title})

func enter_building(info: Dictionary) -> void:
	mode = "interior"
	building = info
	clear_world()
	environment.background_color = Color("283737")
	environment.ambient_light_energy = 0.3
	environment.fog_density = 0
	# Interior uses a translated navigation origin by keeping actors in positive space.
	HubGeometry.interior(geometry,info)
	geometry.position = Vector3(10*tile_size,0,10*tile_size)
	var tiles: Array = []
	tiles.resize(21*21); tiles.fill(0)
	for y in range(6,15):
		for x in range(6,15): tiles[y*21+x] = 1
	for x in range(8,13): tiles[8*21+x] = 0
	nav.setup({"width":21,"height":21,"tiles":tiles},tile_size)
	spawn_party(geometry.position+Vector3(0,0,6.0))
	var keeper = spawn_actor("keeper",geometry.position+Vector3(0,0,-5.1),Color(info.color).lightened(0.15))
	keeper.role = "npc"
	WorldGeometry.sign_text(keeper,info.keeper,Vector3(0,2.0,0),30)
	add_target("service",info,geometry.position+Vector3(0,0,-1.8),"Speak to "+info.keeper,2.1)
	add_target("exit",0,geometry.position+Vector3(0,0,7.8),"Return to Bellwether",1.6)
	if info.id == "inn": add_target("book",0,geometry.position+Vector3(5.5,0,4.5),"Read your atlas",1.8)

func show_floor(data: Dictionary, metadata: Dictionary, progress: Dictionary, from_below: bool = false) -> void:
	mode = "dungeon"
	floor_data = data
	meta = metadata
	floor_state = progress
	opened = progress.opened
	defeated = progress.defeated
	discovered = progress.seen
	boss_dead = progress.boss_dead
	clear_world()
	environment.background_color = Color("101a20")
	environment.ambient_light_energy = 0.22
	environment.fog_light_color = Color("314345")
	environment.fog_density = 0.009
	nav.setup(data,tile_size)
	var built = DungeonGeometry.build(geometry,data,meta.environment,tile_size)
	chest_models = built.chests
	var spawn = data.stairs if from_below and not data.stairs.is_empty() else data.entrance
	spawn_party(Vector3(spawn[0]*tile_size,0,spawn[1]*tile_size))
	for i in data.enemies.size():
		if defeated.has(i): continue
		var entry = data.enemies[i]
		var info = Content.monster(meta.environment,entry.rank,entry.variant)
		var actor = spawn_actor("enemy-%d" % i,Vector3(entry.pos[0]*tile_size,0,entry.pos[1]*tile_size),Color(info.color),info.shape)
		actor.role = "enemy"
		var brain = EnemyBrain.new()
		brain.setup(actor.actor_id,actor,int(meta.seed)+int(data.index)*7919+i*101,int(entry.variant))
		enemies[i] = brain
	for i in data.chests.size():
		var p = data.chests[i].pos
		add_target("chest",i,Vector3(p[0]*tile_size,0,p[1]*tile_size),"Open treasure chest",1.7)
	add_target("up",0,Vector3(data.entrance[0]*tile_size,0,data.entrance[1]*tile_size),"Leave grotto" if data.index == 0 else "Ascend",1.3)
	if not data.stairs.is_empty(): add_target("down",0,Vector3(data.stairs[0]*tile_size,0,data.stairs[1]*tile_size),"Descend",1.3)
	if not data.boss.is_empty():
		var p = Vector3(data.boss[0]*tile_size,0,data.boss[1]*tile_size)
		var info = Content.boss(meta.boss_tier)
		boss_model = spawn_actor("boss",p,Color(info.color),info.shape)
		boss_model.role = "enemy"
		boss_model.model.scale = Vector3.ONE*1.65
		WorldGeometry.sign_text(boss_model,info.name,Vector3(0,3.4,0),31)
		add_target("boss",0,p,"Challenge the keeper",2.5)
		add_target("return",0,p,"Follow the light home",2.5)
		return_light = Node3D.new()
		geometry.add_child(return_light)
		return_light.position = p
		var glow = WorldGeometry.cylinder(return_light,Vector3(0,0.07,0),1.15,0.14,Color("b6dcca"))
		glow.material_override = WorldGeometry.material(Color("9bd8ce"),true)
		for i in 6:
			WorldGeometry.sphere(return_light,Vector3(cos(i*TAU/6)*0.9,0.6+i*0.18,sin(i*TAU/6)*0.9),0.09,Color("e3d494"))
		WorldGeometry.sign_text(return_light,"HOMEWARD LIGHT",Vector3(0,2.4,0),30)
	sync_entities()
	reveal()

func sync_entities() -> void:
	if mode != "dungeon": return
	for i in chest_models.size():
		if opened.has(i):
			var lid = chest_models[i].get_node("Lid")
			lid.rotation_degrees.x = -55
			lid.position = Vector3(0,0.8,0.15)
	for i in enemies.keys():
		if defeated.has(i):
			var brain: EnemyBrain = enemies[i]
			actors.erase(brain.id)
			brain.actor.queue_free()
			enemies.erase(i)
	if is_instance_valid(boss_model):
		boss_model.visible = not boss_dead
	if is_instance_valid(return_light): return_light.visible = boss_dead

func _physics_process(delta: float) -> void:
	if not is_instance_valid(leader): return
	runtime_tick += 1
	for actor in actors.values(): actor.paused = blocked
	if blocked: return
	encounter_grace = maxf(0,encounter_grace-delta)
	trail.record(leader.global_position)
	for i in followers.size():
		var target = trail.target(i)
		var offset = target-followers[i].global_position
		offset.y = 0
		followers[i].speed = leader.speed*minf(1.3,0.8+offset.length()*0.16)
		followers[i].desired = offset.normalized()*minf(1,offset.length()/0.5) if offset.length() > 0.13 else Vector3.ZERO
	if mode == "dungeon":
		if authority_enabled:
			for i in enemies.keys():
				var brain: EnemyBrain = enemies[i]
				var contacted = brain.update(delta,actors,nav)
				if contacted != "" and encounter_grace <= 0:
					blocked = true
					interaction.emit("enemy",i)
					break
		if not boss_dead and is_instance_valid(boss_model) and leader.global_position.distance_to(boss_model.global_position) < 1.45 and encounter_grace <= 0:
			blocked = true
			interaction.emit("boss",0)
		reveal()
	elif mode == "hub":
		for npc in npcs:
			var route = npc.info.route
			var goal = Vector3(route[npc.step][0]*tile_size,0,route[npc.step][1]*tile_size)
			var offset = goal-npc.actor.global_position; offset.y = 0
			if offset.length() < 0.2: npc.step = (npc.step+1)%route.size()
			npc.actor.desired = offset.normalized()*minf(1,offset.length())
	hint = nearest().get("label","")

func reveal() -> void:
	var cell = nav.cell(leader.global_position)
	if cell == last_reveal: return
	last_reveal = cell
	for y in range(maxi(0,cell.y-6),mini(floor_data.height,cell.y+7)):
		for x in range(maxi(0,cell.x-6),mini(floor_data.width,cell.x+7)):
			if Vector2(x,y).distance_to(Vector2(cell)) <= 6.2:
				discovered[str(y*int(floor_data.width)+x)] = true

func nearest() -> Dictionary:
	if not is_instance_valid(leader): return {}
	var selected: Dictionary = {}
	var best = INF
	for target in targets:
		if mode == "dungeon":
			if target.kind == "chest" and opened.has(target.payload): continue
			if target.kind == "boss" and boss_dead or target.kind == "return" and not boss_dead: continue
		var distance = Vector2(leader.global_position.x,leader.global_position.z).distance_to(Vector2(target.pos.x,target.pos.z))
		if distance < target.radius and distance < best:
			selected = target; best = distance
	for npc in npcs:
		var distance = leader.global_position.distance_to(npc.actor.global_position)
		if distance < 2.0 and distance < best:
			selected = {"kind":"npc","payload":npc.info,"label":"E  ·  Speak to "+npc.info.name}
			best = distance
	return selected

func interact() -> void:
	if blocked: return
	var target = nearest()
	if not target.is_empty(): interaction.emit(target.kind,target.payload)

func disengage(index: int) -> void:
	encounter_grace = 3.0
	if enemies.has(index): enemies[index].disengage()

func snapshot() -> Dictionary:
	var actor_states: Array = []
	var enemy_states: Array = []
	for actor in actors.values(): actor_states.append({"id":actor.actor_id,"role":actor.role,"position":[actor.position.x,actor.position.y,actor.position.z]})
	for brain in enemies.values(): enemy_states.append(brain.snapshot())
	return {"tick":runtime_tick,"map_id":meta.get("id","hub"),"floor":floor_data.get("index",0),"actors":actor_states,"enemies":enemy_states,"opened":opened.duplicate(),"defeated":defeated.duplicate(),"boss_dead":boss_dead}
