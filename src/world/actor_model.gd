class_name ActorModel
extends Node3D
## Original low-poly placeholders with a locomotion hook shared by all actors.
var phase = 0.0
var limbs: Array[Node3D] = []
var wings: Array[Node3D] = []
var body: Node3D
var moving = 0.0
var shape = "human"

func build(color: Color, kind: String = "human") -> void:
	shape = kind
	body = Node3D.new()
	add_child(body)
	if kind == "human":
		WorldGeometry.cylinder(body,Vector3(0,0.85,0),0.32,0.6,color,0.24)
		WorldGeometry.box(body,Vector3(0,0.68,0),Vector3(0.52,0.1,0.36),Color("685341"))
		WorldGeometry.sphere(body,Vector3(0,1.35,0),0.29,Color("dfb48e"),Vector3(0.95,1.07,0.95))
		WorldGeometry.sphere(body,Vector3(0,1.52,0.04),0.3,Color("453d3a"),Vector3(1,0.48,0.95))
		WorldGeometry.box(body,Vector3(0,1.13,-0.02),Vector3(0.5,0.12,0.4),color.lightened(0.3))
		WorldGeometry.box(body,Vector3(0,0.92,0.25),Vector3(0.4,0.42,0.17),Color("9d7851"))
		for side in [-1,1]:
			WorldGeometry.sphere(body,Vector3(side*0.1,1.38,-0.263),0.026,Color("273a3b"))
			var leg = Node3D.new()
			leg.position = Vector3(side*0.15,0.57,0)
			body.add_child(leg)
			WorldGeometry.cylinder(leg,Vector3(0,-0.19,0),0.105,0.4,Color("3d5057"))
			WorldGeometry.box(leg,Vector3(0,-0.44,-0.045),Vector3(0.23,0.17,0.34),Color("493f36"))
			limbs.append(leg)
			var arm = Node3D.new()
			arm.position = Vector3(side*0.33,1.09,0)
			body.add_child(arm)
			WorldGeometry.cylinder(arm,Vector3(0,-0.2,0),0.10,0.42,color.darkened(0.15))
			WorldGeometry.sphere(arm,Vector3(0,-0.43,0),0.1,Color("dfb48e"))
			limbs.append(arm)
		# A small personal lantern distinguishes the leader without a copied design.
		WorldGeometry.box(body,Vector3(0.37,0.65,-0.08),Vector3(0.13,0.2,0.13),Color("efd58d"))
	else:
		match kind:
			"golem":
				WorldGeometry.box(body,Vector3(0,0.7,0),Vector3(0.85,0.85,0.6),color)
				WorldGeometry.box(body,Vector3(0,1.25,0),Vector3(0.65,0.5,0.6),color.lightened(0.15))
				for side in [-1,1]:
					WorldGeometry.box(body,Vector3(side*0.6,0.6,0),Vector3(0.25,0.8,0.35),color.darkened(0.12))
					WorldGeometry.box(body,Vector3(side*0.25,0.18,-0.05),Vector3(0.3,0.34,0.48),color.darkened(0.2))
			"wolf":
				WorldGeometry.sphere(body,Vector3(0,0.65,0),0.5,color,Vector3(0.65,0.8,1.25))
				WorldGeometry.sphere(body,Vector3(0,0.95,-0.42),0.3,color)
				WorldGeometry.sphere(body,Vector3(0,0.82,-0.68),0.19,color.darkened(0.15),Vector3(0.9,0.7,1.2))
				for side in [-1,1]:
					WorldGeometry.cylinder(body,Vector3(side*0.18,1.26,-0.43),0.13,0.32,color,0)
					for z in [-0.3,0.3]: WorldGeometry.cylinder(body,Vector3(side*0.26,0.25,z),0.08,0.48,color.darkened(0.2))
			"moth":
				WorldGeometry.sphere(body,Vector3(0,0.95,0),0.22,color.darkened(0.3),Vector3(0.7,1,1.4))
				for side in [-1,1]:
					var pivot = Node3D.new()
					pivot.position = Vector3(0,0.95,0)
					body.add_child(pivot)
					WorldGeometry.sphere(pivot,Vector3(side*0.42,0,0),0.45,color,Vector3(1,0.11,1.15))
					WorldGeometry.sphere(pivot,Vector3(side*0.47,0.045,-0.06),0.15,color.lightened(0.2),Vector3(1,0.2,1))
					wings.append(pivot)
			_:
				WorldGeometry.sphere(body,Vector3(0,0.6,0),0.6,color,Vector3(1,0.7,1))
				for side in [-1,1]:
					for z in [-0.3,0,0.3]:
						var leg = WorldGeometry.cylinder(body,Vector3(side*0.53,0.28,z),0.055,0.6,color.darkened(0.25))
						leg.rotation.z = side*0.8
		for side in [-1,1]:
			WorldGeometry.sphere(body,Vector3(side*0.16,1.24 if kind == "golem" else 0.79,-0.32 if kind == "golem" else -0.5),0.055,Color("f6df8a"))

func animate(delta: float, speed: float) -> void:
	phase += delta*(9.0 if shape == "human" else 6.0)
	moving = move_toward(moving,minf(1,speed/2.5),delta*6)
	if body == null: return
	body.position.y = absf(sin(phase))*0.045*moving
	for i in limbs.size():
		limbs[i].rotation.x = sin(phase + (PI if i in [0,3] else 0))*0.5*moving
	for i in wings.size(): wings[i].rotation.z = sin(phase*2)*0.45*(1 if i == 0 else -1)
