class_name FollowCamera
extends Camera3D
@export var height = 10.8
@export var distance = 12.5
@export var pitch = 42.0
@export var tracking_smoothing = 9.0
@export var look_ahead = 2.0
var target: Node3D
var anchor = Vector3.ZERO
var occlusion = CameraOcclusion.new()
var overrides: Dictionary = {}

func _ready() -> void:
	# This camera is a world-space sibling of actors. It follows their rendered
	# transform once per frame; automatic interpolation here would add a second lag.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	process_priority = 100

func configure(interior: bool = false) -> void:
	var settings = Content.table("exploration")["interior_camera" if interior else "camera"]
	height = settings.height
	distance = settings.distance
	pitch = settings.pitch
	fov = settings.field_of_view
	tracking_smoothing = settings.tracking_smoothing
	look_ahead = settings.look_ahead
	projection = Camera3D.PROJECTION_PERSPECTIVE
	near = 0.15
	far = 180
	current = true
	for key in overrides: set(key,overrides[key])

func reset_tracking() -> void:
	if target != null: anchor = target.global_position
	update_camera()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var rendered_target = target.get_global_transform_interpolated().origin
		anchor = anchor.lerp(rendered_target,1-exp(-tracking_smoothing*delta))
		update_camera()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(target): occlusion.update(self,target)

func update_camera() -> void:
	global_position = anchor + Vector3(0,height,distance-look_ahead)
	rotation_degrees = Vector3(-pitch,0,0)
