class_name CreaturePortrait
extends Node2D
var info: Dictionary = {}

func _draw() -> void:
	var color = Color(info.get("color","aabbbb"))
	draw_circle(Vector2.ZERO,44,color.darkened(0.78))
	draw_arc(Vector2.ZERO,46,0,TAU,48,color.darkened(0.3),1)
	match info.get("shape","golem"):
		"golem":
			draw_rect(Rect2(-20,-23,40,45),color)
			draw_rect(Rect2(-31,-10,10,32),color.darkened(0.2))
			draw_rect(Rect2(21,-10,10,32),color.darkened(0.2))
			draw_line(Vector2(-20,7),Vector2(20,7),color.darkened(0.4),3)
			draw_line(Vector2(0,-23),Vector2(4,-12),color.darkened(0.4),2)
		"moth":
			for side in [-1,1]:
				draw_colored_polygon(PackedVector2Array([Vector2(0,-4),Vector2(side*33,-30),Vector2(side*37,5),Vector2(side*21,28),Vector2(0,12)]),color)
				draw_circle(Vector2(side*22,-2),9,color.darkened(0.3))
			draw_line(Vector2(0,-22),Vector2(0,25),color.lightened(0.2),7)
		"wolf":
			draw_colored_polygon(PackedVector2Array([Vector2(-27,17),Vector2(-27,-30),Vector2(-8,-16),Vector2(8,-16),Vector2(27,-30),Vector2(27,17),Vector2(0,32)]),color)
			draw_colored_polygon(PackedVector2Array([Vector2(-10,9),Vector2(10,9),Vector2(0,22)]),color.darkened(0.5))
		_:
			for side in [-1,1]:
				for i in 3:
					draw_line(Vector2(side*15,-15+i*14),Vector2(side*34,-23+i*22),color,4)
			draw_circle(Vector2.ZERO,26,color)
			draw_line(Vector2(0,-24),Vector2(0,25),color.darkened(0.3),3)
	for side in [-1,1]:
		draw_circle(Vector2(side*9,-8),4,Color("15292c"))
		draw_circle(Vector2(side*9-1,-9),1.2,Color("f9e6a2"))
