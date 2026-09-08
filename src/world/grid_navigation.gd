class_name GridNavigation
extends RefCounted
## Runtime navigation adapter, independent from map identity and authority.
var data: Dictionary
var astar = AStarGrid2D.new()
var tile_size = 1.8

func setup(floor_data: Dictionary, size: float) -> void:
	data = floor_data
	tile_size = size
	astar.region = Rect2i(0,0,data.width,data.height)
	astar.cell_size = Vector2.ONE*tile_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in int(data.height):
		for x in int(data.width): astar.set_point_solid(Vector2i(x,y),data.tiles[y*int(data.width)+x] != 1)

func cell(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x/tile_size),roundi(pos.z/tile_size))

func world(p: Vector2i) -> Vector3:
	return Vector3(p.x*tile_size,0,p.y*tile_size)

func walkable(p: Vector2i) -> bool:
	return astar.is_in_boundsv(p) and not astar.is_point_solid(p)

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var a = cell(from)
	var b = cell(to)
	var result = PackedVector3Array()
	if not walkable(a) or not walkable(b): return result
	for p in astar.get_id_path(a,b): result.append(world(p))
	return result

func visible_between(a: Vector3, b: Vector3) -> bool:
	var steps = maxi(1,ceili(a.distance_to(b)/(tile_size*0.3)))
	for i in range(steps+1):
		if not walkable(cell(a.lerp(b,float(i)/steps))): return false
	return true
