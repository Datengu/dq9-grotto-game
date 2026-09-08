class_name WorldGeometry
extends RefCounted
static var materials: Dictionary = {}

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key = color.to_html() + str(glow)
	if not materials.has(key):
		var m = StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.87
		if glow:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = 1.2
		materials[key] = m
	return materials[key]

static func mesh(parent: Node3D, resource: Mesh, pos: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = resource
	node.material_override = material(color)
	node.position = pos
	parent.add_child(node)
	if solid:
		var body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		node.add_child(body)
		var shape = CollisionShape3D.new()
		shape.shape = resource.create_convex_shape()
		body.add_child(shape)
	return node

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var resource = BoxMesh.new()
	resource.size = size
	var node = mesh(parent,resource,pos,color)
	if solid:
		var body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		node.add_child(body)
		var shape = CollisionShape3D.new()
		var cube = BoxShape3D.new()
		cube.size = size
		shape.shape = cube
		body.add_child(shape)
	return node

static func sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var resource = SphereMesh.new()
	resource.radius = radius
	resource.height = radius*2
	resource.radial_segments = 12
	resource.rings = 6
	var node = mesh(parent,resource,pos,color)
	node.scale = scale_value
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1, solid: bool = false) -> MeshInstance3D:
	var resource = CylinderMesh.new()
	resource.bottom_radius = radius
	resource.top_radius = radius if top < 0 else top
	resource.height = height
	resource.radial_segments = 12
	return mesh(parent,resource,pos,color,solid)

static func sign_text(parent: Node3D, text: String, pos: Vector3, font_size: int = 42) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = font_size
	label.pixel_size = 0.006
	label.outline_size = 8
	label.modulate = Color("f2e5c9")
	label.outline_modulate = Color("27383b")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label

static func roof(parent: Node3D, pos: Vector3, width: float, depth: float, height: float, color: Color) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a = Vector3(-width/2,0,-depth/2)
	var b = Vector3(width/2,0,-depth/2)
	var c = Vector3(width/2,0,depth/2)
	var d = Vector3(-width/2,0,depth/2)
	var e = Vector3(0,height,-depth/2)
	var f = Vector3(0,height,depth/2)
	for triangle in [[a,e,b],[d,c,f],[a,d,f],[a,f,e],[e,f,c],[e,c,b]]:
		for point in triangle: st.add_vertex(point)
	st.generate_normals()
	mesh(parent,st.commit(),pos,color)

static func torch(parent: Node3D, pos: Vector3, indoor: bool = false) -> void:
	cylinder(parent,pos+Vector3(0,0.65,0),0.085,1.3,Color("5f4b39"))
	cylinder(parent,pos+Vector3(0,1.32,0),0.2,0.18,Color("8d7350"),0.3)
	var fire = sphere(parent,pos+Vector3(0,1.56,0),0.18,Color("ffd88c"),Vector3(0.7,1.4,0.7))
	fire.material_override = material(Color("ffbc68"),true)
	var light = OmniLight3D.new()
	light.position = pos+Vector3(0,1.8,0)
	light.light_color = Color("ffcf8b")
	light.light_energy = 1.35 if indoor else 0.6
	light.omni_range = 7
	light.shadow_enabled = false
	parent.add_child(light)
