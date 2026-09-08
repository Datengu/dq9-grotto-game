class_name ExplorerActor
extends CharacterBody3D
signal moved(actor_id: String, position: Vector3)
var actor_id = "player-1"
var role = "player"
var controlled = false
var paused = false
var desired = Vector3.ZERO
var speed = 4.4
var acceleration = 20.0
var braking = 26.0
var turn_speed = 13.0
var model: ActorModel
var command_override = false
var camera: Camera3D

func setup(id: String, color: Color, kind: String = "human") -> void:
	actor_id = id
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.4
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.55
	collider.shape = capsule
	collider.position.y = 0.79
	add_child(collider)
	model = ActorModel.new()
	add_child(model)
	model.build(color,kind)

func _physics_process(delta: float) -> void:
	if paused:
		velocity = Vector3.ZERO
		model.animate(delta,0)
		return
	if controlled and not command_override:
		var x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		var z = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		var right = Vector3.RIGHT
		var back = Vector3.BACK
		if camera != null:
			right = camera.global_basis.x; right.y = 0; right = right.normalized()
			back = camera.global_basis.z; back.y = 0; back = back.normalized()
		desired = (right*x + back*z).limit_length(1)
	var target = desired.limit_length(1)*speed
	var rate = acceleration if desired.length_squared() > 0.001 else braking
	velocity.x = move_toward(velocity.x,target.x,rate*delta)
	velocity.z = move_toward(velocity.z,target.z,rate*delta)
	velocity.y = -1.0 if is_on_floor() else velocity.y - 22*delta
	var before = global_position
	move_and_slide()
	var horizontal = Vector3(velocity.x,0,velocity.z)
	if horizontal.length() > 0.12:
		model.rotation.y = lerp_angle(model.rotation.y,atan2(-horizontal.x,-horizontal.z),1-exp(-turn_speed*delta))
	model.animate(delta,horizontal.length())
	if before.distance_to(global_position) > 0.001: moved.emit(actor_id,global_position)
