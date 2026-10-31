extends Node3D
class_name CirclingFlock

@export var bird_count: int = 5
@export var circle_radius: float = 16.0
@export var circle_speed: float = 20.0 # Deg/sec
@export var flight_height: float = 32.0 # True sky altitude high above castle spires

var _birds: Array[Node3D] = []
var _wings_left: Array[Node3D] = []
var _wings_right: Array[Node3D] = []
var _wing_tips_left: Array[Node3D] = []
var _wing_tips_right: Array[Node3D] = []

func _ready() -> void:
	position.y = flight_height
	
	# Feathers Material (Sleek dark raven/falcon sheen)
	var feather_mat = StandardMaterial3D.new()
	feather_mat.albedo_color = Color(0.12, 0.13, 0.16)
	feather_mat.roughness = 0.65
	
	# Beak Material (Golden amber)
	var beak_mat = StandardMaterial3D.new()
	beak_mat.albedo_color = Color(0.82, 0.62, 0.22)
	beak_mat.roughness = 0.5
	
	for i in range(bird_count):
		var bird_root = Node3D.new()
		bird_root.name = "Bird_%d" % i
		var angle = float(i) * (TAU / float(bird_count)) + randf_range(-0.35, 0.35)
		var r = circle_radius + randf_range(-3.0, 3.0)
		bird_root.position = Vector3(cos(angle) * r, randf_range(-1.5, 1.5), sin(angle) * r)
		bird_root.rotation.y = -angle + PI * 0.5
		
		# 1. Aerodynamic Bird Torso / Body (Tapered sleek capsule)
		var body = MeshInstance3D.new()
		var b_mesh = CapsuleMesh.new()
		b_mesh.radius = 0.11
		b_mesh.height = 0.48
		b_mesh.material = feather_mat
		body.mesh = b_mesh
		body.rotation_degrees.x = 90.0 # Align along forward Z
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bird_root.add_child(body)
		
		# 2. Bird Head
		var head = MeshInstance3D.new()
		var h_mesh = SphereMesh.new()
		h_mesh.radius = 0.08
		h_mesh.height = 0.15
		h_mesh.material = feather_mat
		head.mesh = h_mesh
		head.position = Vector3(0.0, 0.05, -0.26)
		head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bird_root.add_child(head)
		
		# 3. Pointed Beak
		var beak = MeshInstance3D.new()
		var bk_mesh = PrismMesh.new()
		bk_mesh.size = Vector3(0.06, 0.05, 0.14)
		bk_mesh.material = beak_mat
		beak.mesh = bk_mesh
		beak.position = Vector3(0.0, 0.03, -0.38)
		beak.rotation_degrees.x = -90.0
		beak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bird_root.add_child(beak)
		
		# 4. Fanned Tail Feathers
		var tail = MeshInstance3D.new()
		var t_mesh = PrismMesh.new()
		t_mesh.size = Vector3(0.28, 0.03, 0.38)
		t_mesh.material = feather_mat
		tail.mesh = t_mesh
		tail.position = Vector3(0.0, 0.02, 0.32)
		tail.rotation_degrees.x = 90.0
		tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bird_root.add_child(tail)
		
		# 5. Articulated Left Wing (Pivot at shoulder X = -0.10)
		var l_wing_pivot = Node3D.new()
		l_wing_pivot.position = Vector3(-0.10, 0.04, -0.05)
		
		var l_inner = MeshInstance3D.new()
		var w_inner_mesh = BoxMesh.new()
		w_inner_mesh.size = Vector3(0.38, 0.03, 0.24)
		w_inner_mesh.material = feather_mat
		l_inner.mesh = w_inner_mesh
		l_inner.position = Vector3(-0.19, 0.0, 0.0)
		l_inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		l_wing_pivot.add_child(l_inner)
		
		# Left Outer Wing Tip (Feathered sweep)
		var l_tip_pivot = Node3D.new()
		l_tip_pivot.position = Vector3(-0.38, 0.0, 0.0)
		var l_outer = MeshInstance3D.new()
		var w_outer_mesh = PrismMesh.new()
		w_outer_mesh.size = Vector3(0.34, 0.02, 0.20)
		w_outer_mesh.material = feather_mat
		l_outer.mesh = w_outer_mesh
		l_outer.position = Vector3(-0.17, 0.0, 0.0)
		l_outer.rotation_degrees.z = -90.0
		l_outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		l_tip_pivot.add_child(l_outer)
		l_wing_pivot.add_child(l_tip_pivot)
		
		bird_root.add_child(l_wing_pivot)
		_wings_left.append(l_wing_pivot)
		_wing_tips_left.append(l_tip_pivot)
		
		# 6. Articulated Right Wing (Pivot at shoulder X = +0.10)
		var r_wing_pivot = Node3D.new()
		r_wing_pivot.position = Vector3(0.10, 0.04, -0.05)
		
		var r_inner = MeshInstance3D.new()
		r_inner.mesh = w_inner_mesh
		r_inner.position = Vector3(0.19, 0.0, 0.0)
		r_inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		r_wing_pivot.add_child(r_inner)
		
		var r_tip_pivot = Node3D.new()
		r_tip_pivot.position = Vector3(0.38, 0.0, 0.0)
		var r_outer = MeshInstance3D.new()
		r_outer.mesh = w_outer_mesh
		r_outer.position = Vector3(0.17, 0.0, 0.0)
		r_outer.rotation_degrees.z = 90.0
		r_outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		r_tip_pivot.add_child(r_outer)
		r_wing_pivot.add_child(r_tip_pivot)
		
		bird_root.add_child(r_wing_pivot)
		_wings_right.append(r_wing_pivot)
		_wing_tips_right.append(r_tip_pivot)
		
		add_child(bird_root)
		_birds.append(bird_root)

func _process(delta: float) -> void:
	rotation_degrees.y += circle_speed * delta
	
	# Fluid wing flapping and soaring glide dynamics
	var t = Time.get_ticks_msec() * 0.009
	for i in range(_wings_left.size()):
		var flap_cycle = sin(t + float(i) * 1.4)
		var shoulder_angle = flap_cycle * 0.42
		var tip_angle = flap_cycle * 0.28
		
		_wings_left[i].rotation.z = shoulder_angle
		_wing_tips_left[i].rotation.z = tip_angle
		
		_wings_right[i].rotation.z = -shoulder_angle
		_wing_tips_right[i].rotation.z = -tip_angle
		
		# Subtle body roll bank while circling
		if i < _birds.size():
			_birds[i].rotation.z = -0.18 + cos(t + float(i)) * 0.08

