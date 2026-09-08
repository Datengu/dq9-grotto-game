class_name DungeonGeometry
extends RefCounted
static func floor_material(environment: String, base: Color) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """shader_type spatial;
uniform vec4 stone : source_color;
uniform bool masonry = false;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=world_pos.xz;
 float n=hash(floor(p*5.0));
 float shade=0.94+n*0.09;
 if(masonry){
   vec2 q=vec2(p.x*0.85+mod(floor(p.y*1.15),2.0)*0.5,p.y*1.15);
   vec2 f=fract(q); float seam=step(0.965,f.x)+step(0.97,f.y);
   shade=0.86+hash(floor(q))*0.23-min(seam,1.0)*0.12;
 } else {shade += sin(p.x*1.7+sin(p.y*2.1))*0.025;}
 ALBEDO=stone.rgb*shade; ROUGHNESS=0.95;
}"""
	var m = ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("stone",base)
	m.set_shader_parameter("masonry",environment == "Ruins")
	return m

static func build(root: Node3D, data: Dictionary, environment: String, size: float) -> Dictionary:
	var palettes = {"Ruins":["677875","63706b"],"Cavern":["80725a","7d6650"],"Ember":["75564c","72443b"],"Tidal":["608489","526e78"],"Frost":["9ab8bd","739da9"]}
	var palette: Array = palettes[environment]
	var floor_mat = floor_material(environment,Color(palette[0]))
	var wall_color = Color(palette[1])
	var width = int(data.width)
	var height = int(data.height)
	# Merge each horizontal run into a single floor slab / collider.
	for y in height:
		var x = 0
		while x < width:
			if data.tiles[y*width+x] == 0: x += 1; continue
			var begin = x
			while x < width and data.tiles[y*width+x] == 1: x += 1
			var slab = WorldGeometry.box(root,Vector3((begin+x-1)*size/2,-0.16,y*size),Vector3((x-begin)*size,0.32,size),Color(palette[0]),true)
			slab.material_override = floor_mat
	# Boundary faces, never a rectangular backing board.
	for y in height:
		for x in width:
			if data.tiles[y*width+x] == 0: continue
			for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
				var n = Vector2i(x,y)+d
				if n.x >= 0 and n.y >= 0 and n.x < width and n.y < height and data.tiles[n.y*width+n.x] == 1: continue
				var pos = Vector3((x+d.x*0.5)*size,1.4,(y+d.y*0.5)*size)
				var extents = Vector3(0.3,2.8,size+0.15) if d.x != 0 else Vector3(size+0.15,2.8,0.3)
				var wall = Node3D.new(); root.add_child(wall)
				wall.add_to_group("camera_occlusion_cluster")
				WorldGeometry.box(wall,pos,extents,wall_color.lightened(float((x*7+y*11)%5)*0.012),true)
				WorldGeometry.box(wall,pos+Vector3(0,1.45,0),Vector3(extents.x+0.16,0.16,extents.z+0.16),wall_color.lightened(0.12))
				if environment != "Ruins" and (x*3+y*7)%5 == 0:
					var rock = WorldGeometry.sphere(wall,pos+Vector3(d.x*0.13,0.05,d.y*0.13),0.8,wall_color.darkened(0.02),Vector3(0.75,1.9,0.75))
					rock.rotation.y = float((x+y)%6)
	var chests: Array[Node3D] = []
	for chest in data.chests:
		var container = Node3D.new()
		container.position = Vector3(chest.pos[0]*size,0,chest.pos[1]*size)
		root.add_child(container)
		WorldGeometry.box(container,Vector3(0,0.3,0),Vector3(0.94,0.55,0.65),Color("865d40"))
		var lid = WorldGeometry.box(container,Vector3(0,0.61,0),Vector3(1.0,0.15,0.71),Color("b68a54"))
		lid.name = "Lid"
		for x in [-0.32,0.32]: WorldGeometry.box(container,Vector3(x,0.36,-0.34),Vector3(0.07,0.6,0.025),Color("d8b96e"))
		WorldGeometry.box(container,Vector3(0,0.42,-0.36),Vector3(0.14,0.16,0.05),Color("e6cf8e"))
		chests.append(container)
	stairs(root,data.entrance,size,false)
	if not data.stairs.is_empty(): stairs(root,data.stairs,size,true)
	# Deliberate props on room edges, not obstructions in navigation corridors.
	var torch_count = 0
	for y in range(2,height-2,4):
		for x in range(2,width-2,5):
			if torch_count >= 22: break
			if data.tiles[y*width+x] == 1 and data.tiles[(y-1)*width+x] == 0:
				WorldGeometry.torch(root,Vector3(x*size,0,(y-0.27)*size),true)
				torch_count += 1
	return {"chests":chests}

static func stairs(root: Node3D, pos: Array, size: float, down: bool) -> void:
	var p = Vector3(pos[0]*size,0,pos[1]*size)
	WorldGeometry.box(root,p+Vector3(0,0.025,0),Vector3(1.35,0.05,1.5),Color("273a3c"))
	for i in 6:
		WorldGeometry.box(root,p+Vector3(0,0.04+i*0.065,0.6-i*0.2),Vector3(1.25,0.08,0.22),Color("c3b58d") if down else Color("94b9b7"))
	for side in [-1,1]: WorldGeometry.box(root,p+Vector3(side*0.76,0.35,0),Vector3(0.13,0.7,1.6),Color("647271"))
	WorldGeometry.sign_text(root,"DESCEND" if down else "ASCEND",p+Vector3(0,0.95,0),24)
