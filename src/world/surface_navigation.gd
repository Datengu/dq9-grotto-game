class_name SurfaceNavigation
extends GridNavigation
## Recast-baked, radius-eroded 3D surface. The grid defines the floor boundary,
## not the waypoints or endpoints followed by a physical actor.
var map_rid: RID
var region_rid: RID
var navigation_mesh: NavigationMesh
var bake_ms = 0

func build_surface() -> void:
	var start = Time.get_ticks_msec()
	var source = NavigationMeshSourceGeometryData3D.new()
	for y in int(data.height):
		var x = 0
		while x < int(data.width):
			if data.tiles[y*int(data.width)+x] != 1: x += 1; continue
			var begin = x
			while x < int(data.width) and data.tiles[y*int(data.width)+x] == 1: x += 1
			var a = Vector3((begin-0.5)*tile_size,0,(y-0.5)*tile_size)
			var b = Vector3((x-0.5)*tile_size,0,(y-0.5)*tile_size)
			var c = Vector3((x-0.5)*tile_size,0,(y+0.5)*tile_size)
			var d = Vector3((begin-0.5)*tile_size,0,(y+0.5)*tile_size)
			source.add_faces(PackedVector3Array([a,b,c,a,c,d]),Transform3D.IDENTITY)
	navigation_mesh = NavigationMesh.new()
	navigation_mesh.agent_radius = 0.75
	navigation_mesh.agent_height = 1.75
	navigation_mesh.agent_max_climb = 0.25
	navigation_mesh.edge_max_error = 0.1
	navigation_mesh.region_min_size = 0
	navigation_mesh.region_merge_size = 0
	NavigationServer3D.bake_from_source_geometry_data(navigation_mesh,source)
	map_rid = NavigationServer3D.map_create()
	NavigationServer3D.map_set_use_async_iterations(map_rid,false)
	NavigationServer3D.map_set_active(map_rid,true)
	region_rid = NavigationServer3D.region_create()
	NavigationServer3D.region_set_use_async_iterations(region_rid,false)
	NavigationServer3D.region_set_navigation_mesh(region_rid,navigation_mesh)
	NavigationServer3D.region_set_map(region_rid,map_rid)
	bake_ms = Time.get_ticks_msec()-start

func ready() -> bool:
	return map_rid.is_valid() and NavigationServer3D.map_get_iteration_id(map_rid) > 0 and NavigationServer3D.region_get_iteration_id(region_rid) > 0 and NavigationServer3D.map_get_closest_point_owner(map_rid,world(Vector2i(data.entrance[0],data.entrance[1]))).is_valid()

func closest(pos: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(map_rid,pos) if ready() else pos

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if not ready(): return PackedVector3Array()
	return NavigationServer3D.map_get_path(map_rid,from,to,true)

func random_near(origin: Vector3, minimum: float, maximum: float, rng: SeedRng) -> Vector3:
	var angle = rng.between(0,100000)/100000.0*TAU
	var distance = lerpf(minimum,maximum,rng.between(0,100000)/100000.0)
	return closest(origin+Vector3(cos(angle),0,sin(angle))*distance)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if region_rid.is_valid(): NavigationServer3D.free_rid(region_rid)
		if map_rid.is_valid(): NavigationServer3D.free_rid(map_rid)
