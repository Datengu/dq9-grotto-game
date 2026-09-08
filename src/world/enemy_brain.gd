class_name EnemyBrain
extends RefCounted
var id = ""
var actor: ExplorerActor
var home = Vector3.ZERO
var mode = "idle"
var timer = 1.0
var chase_time = 0.0
var unseen_time = 0.0
var repath = 0.0
var grace = 2.0
var target_id = ""
var route = PackedVector3Array()
var rng: SeedRng
var config: Dictionary
var personality = "aggressive"

func setup(enemy_id: String, body: ExplorerActor, seed_value: int, variant: int) -> void:
	id = enemy_id
	actor = body
	home = body.global_position
	rng = SeedRng.new(seed_value)
	config = Content.table("exploration").enemy
	personality = ["slow","aggressive","fast"][variant%3]
	timer = 0.3 + rng.between(0,15)*0.1

func update(delta: float, actors: Dictionary, nav: GridNavigation) -> String:
	if nav is SurfaceNavigation and not nav.ready(): return ""
	grace = maxf(0,grace-delta)
	timer -= delta
	repath -= delta
	var nearest: ExplorerActor
	var distance = INF
	for candidate in actors.values():
		if candidate.role != "player": continue
		var d = actor.global_position.distance_to(candidate.global_position)
		if d < distance: distance = d; nearest = candidate
	if nearest == null: return ""
	var visible = distance < config.detection_radius and nav.visible_between(actor.global_position,nearest.global_position)
	if mode in ["idle","wander"] and visible and grace <= 0:
		mode = "chase"
		target_id = nearest.actor_id
		chase_time = 0
		unseen_time = 0
		repath = 0
	if mode == "chase":
		chase_time += delta
		var target: ExplorerActor = actors.get(target_id,nearest)
		distance = actor.global_position.distance_to(target.global_position)
		unseen_time = 0 if nav.visible_between(actor.global_position,target.global_position) else unseen_time+delta
		if distance <= config.contact_radius and grace <= 0:
			actor.desired = Vector3.ZERO
			return target.actor_id
		if distance > config.lose_radius or actor.global_position.distance_to(home) > config.leash_radius or chase_time > config.pursuit_seconds or unseen_time > 2.5:
			mode = "return"
			route = nav.path(actor.global_position,home)
			grace = 3
		elif repath <= 0:
			route = nav.path(actor.global_position,target.global_position)
			repath = 0.45
		actor.speed = config.chase_speed * (0.8 if personality == "slow" else 1.07 if personality == "fast" else 1.0)
	elif mode == "idle":
		actor.desired = Vector3.ZERO
		if timer <= 0:
			for i in 12:
				var destination = nav.random_near(home,1.5,7.0,rng) if nav is SurfaceNavigation else nav.world(nav.cell(home)+Vector2i(rng.between(-4,4),rng.between(-4,4)))
				if nav.walkable(nav.cell(destination)):
					route = nav.path(actor.global_position,destination)
					if route.size() > 1: mode = "wander"; break
			timer = config.idle_seconds
	else:
		actor.speed = config.wander_speed * (0.8 if personality == "slow" else 1)
	if mode != "idle":
		# The funnel path contains only physical corners and an arbitrary endpoint.
		# Repathing must not send an actor back to the start of its current segment.
		while not route.is_empty() and flat_distance(actor.global_position,route[0]) < 0.18: route.remove_at(0)
		if route.is_empty():
			actor.desired = Vector3.ZERO
			if mode != "chase": mode = "idle"; timer = config.idle_seconds + rng.between(0,10)*0.12
		else:
			var direction = route[0]-actor.global_position
			direction.y = 0
			actor.desired = direction.normalized()*minf(1.0,direction.length()/0.45) if route.size() == 1 else direction.normalized()
	return ""

func disengage() -> void:
	mode = "idle"
	grace = 4
	timer = 3
	route.clear()
	actor.desired = Vector3.ZERO

func snapshot() -> Dictionary:
	return {"id":id,"position":[actor.position.x,actor.position.y,actor.position.z],"mode":mode,"target_actor":target_id,"rng":rng.state,"grace":grace}

func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))
