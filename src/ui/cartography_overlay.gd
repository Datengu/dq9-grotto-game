class_name CartographyOverlay
extends Control
var world: ExplorationWorld

func _draw() -> void:
	if world == null or world.mode != "dungeon": return
	var data = world.floor_data
	draw_style_box(style(),Rect2(Vector2.ZERO,size))
	draw_string(ThemeDB.fallback_font,Vector2(14,25),"FIELD MAP    ·    M to hide",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("dfc890"))
	var scale_value = minf((size.x-28)/float(data.width),(size.y-54)/float(data.height))
	var offset = Vector2((size.x-data.width*scale_value)/2,42+(size.y-54-data.height*scale_value)/2)
	for y in int(data.height):
		for x in int(data.width):
			var index = y*int(data.width)+x
			if world.discovered.has(str(index)) and data.tiles[index] == 1:
				draw_rect(Rect2(offset+Vector2(x,y)*scale_value,Vector2.ONE*(scale_value+0.2)),Color("a0ac95"))
	for pair in [[data.entrance,Color("86c7d1")],[data.stairs,Color("eec276")]]:
		if pair[0].is_empty(): continue
		var p = Vector2(pair[0][0],pair[0][1])
		if world.discovered.has(str(int(p.y)*int(data.width)+int(p.x))): draw_circle(offset+(p+Vector2.ONE*0.5)*scale_value,3.5,pair[1])
	for i in data.chests.size():
		var p = data.chests[i].pos
		if world.discovered.has(str(int(p[1])*int(data.width)+int(p[0]))) and not world.opened.has(i):
			draw_rect(Rect2(offset+(Vector2(p[0],p[1])+Vector2.ONE*0.5)*scale_value-Vector2.ONE*2,Vector2.ONE*4),Color("ead08d"))
	var leader = world.nav.cell(world.leader.global_position)
	draw_circle(offset+(Vector2(leader)+Vector2.ONE*0.5)*scale_value,4.5,Color("fff2ba"))

func style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.06,0.12,0.14,0.9)
	s.set_corner_radius_all(8)
	s.set_border_width_all(1)
	s.border_color = Color("688077")
	return s
