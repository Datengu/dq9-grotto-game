class_name HubGeometry
extends RefCounted
static func build(root: Node3D, hub: Dictionary, size: float) -> void:
	var grass = Color("698365")
	WorldGeometry.box(root,Vector3(13*size,-0.25,9*size),Vector3(65,0.5,53),grass,true)
	# Broad paths join the original services without exposing tile boundaries.
	WorldGeometry.box(root,Vector3(13*size,0.008,9*size),Vector3(11,0.025,35),Color("b4a98b"))
	for z in [7,15]: WorldGeometry.box(root,Vector3(13*size,0.015,z*size),Vector3(34,0.03,4.2),Color("b4a98b"))
	WorldGeometry.cylinder(root,Vector3(13*size,0.045,11.5*size),4.0,0.09,Color("bdb699"))
	WorldGeometry.cylinder(root,Vector3(13*size,0.38,11.5*size),1.9,0.76,Color("7e918e"),1.75,true)
	WorldGeometry.cylinder(root,Vector3(13*size,0.79,11.5*size),1.58,0.06,Color("69a3af"))
	WorldGeometry.cylinder(root,Vector3(13*size,1.0,11.5*size),0.34,0.75,Color("b0bab0"))
	WorldGeometry.sphere(root,Vector3(13*size,1.5,11.5*size),0.3,Color("8ab7c3"))
	for b in hub.buildings:
		var house = Node3D.new(); root.add_child(house)
		house.add_to_group("camera_occlusion_cluster")
		var r = b.rect
		var center = Vector3((r[0]+r[2]*0.5-0.5)*size,0,(r[1]+r[3]*0.5-0.5)*size)
		var w = r[2]*size*0.88
		var d = r[3]*size*0.87
		WorldGeometry.box(house,center+Vector3(0,0.2,0),Vector3(w+0.5,0.4,d+0.5),Color("8a8e7b"),true)
		WorldGeometry.box(house,center+Vector3(0,2.15,0),Vector3(w,4.1,d),Color("d2c1a0"),true)
		for x in [-w*0.47,w*0.47]: WorldGeometry.box(house,center+Vector3(x,2.15,0),Vector3(0.16,4.15,d+0.04),Color("73634b"))
		WorldGeometry.box(house,center+Vector3(0,3.1,d*0.5+0.03),Vector3(w,0.13,0.12),Color("79684f"))
		WorldGeometry.roof(house,center+Vector3(0,4.15,0),w+0.75,d+0.8,2.0,Color(b.color))
		WorldGeometry.box(house,center+Vector3(w*0.3,4.9,-d*0.22),Vector3(0.7,2.3,0.8),Color("979078"))
		var door = Vector3(b.door[0]*size,0,b.door[1]*size-size*0.67)
		WorldGeometry.box(house,door+Vector3(0,1.3,0),Vector3(1.5,2.6,0.2),Color("594f40"))
		WorldGeometry.box(house,door+Vector3(0,2.72,0),Vector3(1.9,0.18,0.3),Color("8e7753"))
		WorldGeometry.sphere(house,door+Vector3(0.45,1.18,0.16),0.08,Color("e3c778"))
		WorldGeometry.box(house,door+Vector3(0,0.07,0.45),Vector3(2.2,0.14,1.1),Color("b0a78c"))
		for side in [-1,1]:
			var win = center+Vector3(side*w*0.31,2.05,d*0.5+0.04)
			WorldGeometry.box(house,win,Vector3(1.15,1.35,0.08),Color("766c53"))
			WorldGeometry.box(house,win+Vector3(0,0,0.05),Vector3(0.94,1.14,0.04),Color("f2d696"))
			WorldGeometry.box(house,win+Vector3(0,0,0.09),Vector3(0.07,1.2,0.04),Color("8d7c5c"))
			WorldGeometry.box(house,win+Vector3(0,-0.65,0.1),Vector3(1.3,0.2,0.35),Color("899c6c"))
		WorldGeometry.sign_text(house,b.name,door+Vector3(0,3.45,0.45),34)
	var board = Vector3(hub.board[0]*size,0,hub.board[1]*size)
	for side in [-1,1]: WorldGeometry.box(root,board+Vector3(side*0.8,1.0,0),Vector3(0.13,2.0,0.18),Color("72543e"))
	WorldGeometry.box(root,board+Vector3(0,1.7,0),Vector3(2.0,1.2,0.23),Color("8c6846"),true)
	WorldGeometry.box(root,board+Vector3(0,1.7,0.13),Vector3(1.76,0.96,0.03),Color("414f45"))
	for i in 3:
		var paper = WorldGeometry.box(root,board+Vector3(-0.54+i*0.52,1.68,0.17),Vector3(0.37,0.63,0.03),Color("edd6a4"))
		paper.rotation.z = (i-1)*0.09
	WorldGeometry.roof(root,board+Vector3(0,2.34,0),2.3,0.75,0.28,Color("596d6b"))
	WorldGeometry.sign_text(root,"EXPEDITION BULLETIN",board+Vector3(0,2.95,0),33)
	for p in [[9,7],[17,7],[9,15],[17,15]]:
		WorldGeometry.torch(root,Vector3(p[0]*size,0,p[1]*size))
	for p in [[1,8],[25,8],[1,16],[25,16],[8,0],[18,0],[8,17],[18,17],[0,1],[26,1],[0,12],[26,12]]:
		tree(root,Vector3(p[0]*size,0,p[1]*size),float((p[0]+p[1])%3)*0.15)
	for p in [[10,13],[16,13]]:
		var pos = Vector3(p[0]*size,0,p[1]*size)
		WorldGeometry.box(root,pos+Vector3(0,0.65,0),Vector3(1.8,0.15,0.55),Color("8a7051"),true)
		WorldGeometry.box(root,pos+Vector3(0,1.05,0.2),Vector3(1.8,0.5,0.12),Color("8a7051"))
	# Outer hedges give the settlement a physical edge.
	for x in [-1,27]: WorldGeometry.box(root,Vector3(x*size,0.6,9*size),Vector3(0.7,1.2,38),Color("4b6850"),true)
	for z in [-2,19]: WorldGeometry.box(root,Vector3(13*size,0.6,z*size),Vector3(51,1.2,0.7),Color("4b6850"),true)

static func tree(root: Node3D, pos: Vector3, variation: float) -> void:
	WorldGeometry.cylinder(root,pos+Vector3(0,1.1,0),0.2,2.2,Color("786147"),0.13,true)
	WorldGeometry.sphere(root,pos+Vector3(0,2.75,0),1.28+variation,Color("54765c"),Vector3(1,1.35,1))
	WorldGeometry.sphere(root,pos+Vector3(0.45,3.0,-0.2),0.9,Color("799061"))

static func interior(root: Node3D, info: Dictionary) -> void:
	var mat = DungeonGeometry.floor_material("Ruins",Color("977c59"))
	var floor = WorldGeometry.box(root,Vector3(0,-0.15,0),Vector3(17,0.3,17),Color.WHITE,true)
	floor.material_override = mat
	for x in [-8.5,8.5]: WorldGeometry.box(root,Vector3(x,1.55,0),Vector3(0.35,3.1,17.3),Color("b6a888"),true)
	WorldGeometry.box(root,Vector3(0,1.55,-8.5),Vector3(17.3,3.1,0.35),Color("b6a888"),true)
	for x in [-5.2,5.2]: WorldGeometry.box(root,Vector3(x,0.65,8.5),Vector3(6.3,1.3,0.35),Color("b6a888"),true)
	# Invisible collision behind the exit threshold prevents leaving the floor
	# even if the transition callback is delayed or unavailable.
	var backstop = WorldGeometry.box(root,Vector3(0,1.5,8.4),Vector3(4.3,3,0.2),Color.TRANSPARENT,true)
	backstop.visible = false
	WorldGeometry.box(root,Vector3(0,0.012,2.0),Vector3(3.0,0.03,11),Color(info.color).darkened(0.15))
	WorldGeometry.box(root,Vector3(0,0.62,-3.1),Vector3(7,1.24,1.15),Color("836246"),true)
	WorldGeometry.box(root,Vector3(0,1.3,-3.1),Vector3(7.3,0.15,1.35),Color("b79965"))
	for x in [-6.3,6.3]:
		WorldGeometry.box(root,Vector3(x,1.6,-7.9),Vector3(2.1,3.2,0.65),Color("82674f"),true)
		for y in [0.7,1.5,2.3]:
			WorldGeometry.box(root,Vector3(x,y,-7.5),Vector3(1.95,0.1,0.4),Color("bb9c6a"))
			for i in 4: WorldGeometry.box(root,Vector3(x-0.6+i*0.38,y+0.28,-7.6),Vector3(0.24,0.44,0.35),Color(info.color).lightened(i*0.07))
		WorldGeometry.torch(root,Vector3(x,0,0),true)
	if info.id == "inn":
		WorldGeometry.box(root,Vector3(-5.2,0.4,2.8),Vector3(2.4,0.8,3.8),Color("785f49"),true)
		WorldGeometry.box(root,Vector3(-5.2,0.87,3.0),Vector3(2.15,0.2,3.3),Color("718e97"))
		WorldGeometry.box(root,Vector3(-5.2,1.0,1.75),Vector3(1.8,0.2,0.65),Color("e6d6ad"))
		WorldGeometry.box(root,Vector3(5.5,0.65,3.5),Vector3(2.3,1.3,1.1),Color("927450"),true)
		WorldGeometry.box(root,Vector3(5.5,1.35,3.5),Vector3(0.65,0.09,0.85),Color("e9d4a7"))
		WorldGeometry.sign_text(root,"YOUR ATLAS",Vector3(5.5,2.1,3.5),28)
	if info.id == "shrine":
		WorldGeometry.cylinder(root,Vector3(0,0.7,-6.5),0.9,1.4,Color("9c9b8e"),0.6)
		var crystal = WorldGeometry.sphere(root,Vector3(0,2.0,-6.5),0.45,Color("c2e2d3"),Vector3(0.7,1.8,0.7))
		crystal.material_override = WorldGeometry.material(Color("b3d9d1"),true)
	WorldGeometry.sign_text(root,"BELLWETHER",Vector3(0,1.6,8.2),26)
