class_name FollowerTrail
extends RefCounted
var points: Array[Vector3] = []
var spacing = 1.35
var sample_distance = 0.12

func reset(pos: Vector3) -> void:
	points = [pos]

func record(pos: Vector3) -> void:
	if points.is_empty() or points[0].distance_to(pos) >= sample_distance:
		points.push_front(pos)
		if points.size() > 500: points.resize(500)

func target(index: int) -> Vector3:
	var remaining = (index+1)*spacing
	for i in range(1,points.size()):
		var segment = points[i-1].distance_to(points[i])
		if segment >= remaining:
			return points[i-1].lerp(points[i],remaining/maxf(0.001,segment))
		remaining -= segment
	return points[-1]
