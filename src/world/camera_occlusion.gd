class_name CameraOcclusion
extends RefCounted
## Fade only scenery directly blocking the leader; surrounding walls retain depth.
var faded: Dictionary = {}

func update(camera: Camera3D, target: Node3D) -> void:
	var active: Dictionary = {}
	var excluded: Array[RID] = []
	var space = camera.get_world_3d().direct_space_state
	for i in 6:
		var query = PhysicsRayQueryParameters3D.create(camera.global_position,target.global_position+Vector3(0,1.1,0),1,excluded)
		var hit = space.intersect_ray(query)
		if hit.is_empty(): break
		excluded.append(hit.collider.get_rid())
		var parent: Node = hit.collider.get_parent()
		while parent != null and not parent.is_in_group("camera_occlusion_cluster"): parent = parent.get_parent()
		if parent != null: collect(parent,active)
	for node in faded.keys():
		if not is_instance_valid(node): faded.erase(node); continue
		if not active.has(node): node.material_override = faded[node]; faded.erase(node)
	for node in active:
		if faded.has(node) or not node.material_override is StandardMaterial3D: continue
		faded[node] = node.material_override
		var soft: StandardMaterial3D = node.material_override.duplicate()
		soft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		soft.albedo_color.a = 0.18
		node.material_override = soft

func collect(node: Node, active: Dictionary) -> void:
	if node is MeshInstance3D: active[node] = true
	for child in node.get_children(): collect(child,active)
