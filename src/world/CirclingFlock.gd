extends Node3D
class_name CirclingFlock

@export var bird_count: int = 5
@export var circle_radius: float = 12.0
@export var circle_speed: float = 24.0 # Deg/sec
@export var flight_height: float = 18.0

var _birds: Array[Node3D] = []
var _wings_left: Array[MeshInstance3D] = []
var _wings_right: Array[MeshInstance3D] = []

func _ready() -> void:
	position.y = flight_height
	var bird_mat = StandardMaterial3D.new()
	bird_mat.albedo_color = Color(0.12, 0.14, 0.18) # Dark crow/hawk silhouette
	bird_mat.roughness = 0.8
	
	for i in range(bird_count):
		var bird_root = Node3D.new()
		bird_root.name = "Bird_%d" % i
		var angle = float(i) * (TAU / float(bird_count)) + randf_range(-0.3, 0.3)
		var r = circle_radius + randf_range(-2.5, 2.5)
		bird_root.position = Vector3(cos(angle) * r, randf_range(-1.2, 1.2), sin(angle) * r)
		bird_root.rotation.y = -angle + PI * 0.5 # Face forward along tangent
		
		# Body
		var body = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(0.16, 0.12, 0.45)
		b_mesh.material = bird_mat
		body.mesh = b_mesh
		bird_root.add_child(body)
		
		# Left Wing
		var l_wing = MeshInstance3D.new()
		var w_mesh = PrismMesh.new()
		w_mesh.size = Vector3(0.55, 0.04, 0.28)
		w_mesh.material = bird_mat
		l_wing.mesh = w_mesh
		l_wing.position = Vector3(-0.32, 0.02, 0.0)
		bird_root.add_child(l_wing)
		_wings_left.append(l_wing)
		
		# Right Wing
		var r_wing = MeshInstance3D.new()
		r_wing.mesh = w_mesh
		r_wing.position = Vector3(0.32, 0.02, 0.0)
		bird_root.add_child(r_wing)
		_wings_right.append(r_wing)
		
		add_child(bird_root)
		_birds.append(bird_root)

func _process(delta: float) -> void:
	rotation_degrees.y += circle_speed * delta
	
	# Flapping wing animation
	var t = Time.get_ticks_msec() * 0.012
	for i in range(_wings_left.size()):
		var flap = sin(t + float(i) * 1.3) * 0.55
		_wings_left[i].rotation.z = flap
		_wings_right[i].rotation.z = -flap
