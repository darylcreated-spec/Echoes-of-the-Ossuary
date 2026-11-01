extends Node3D
class_name HarborSeal3D

@export var seal_name: String = "Coastal Harbor Seal"

var _head_pivot: Node3D = null
var _left_flipper: Node3D = null
var _right_flipper: Node3D = null
var _tail_pivot: Node3D = null
var _anim_time: float = 0.0

func _ready() -> void:
	add_to_group("harbor_seal")
	add_to_group("interactable")
	_anim_time = randf_range(0.0, 25.0)
	_build_seal_mesh()
	_build_interaction()

func _build_seal_mesh() -> void:
	var coat_mat = StandardMaterial3D.new()
	coat_mat.albedo_color = Color(0.32, 0.35, 0.38) # Sleek wet slate-grey seal coat
	coat_mat.roughness = 0.35 # Glossy wet fur sheen

	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.10, 0.11, 0.13)
	dark_mat.roughness = 0.25

	# 1. Plump Torso (Tapered horizontal capsule)
	var body = MeshInstance3D.new()
	var b_mesh = CapsuleMesh.new()
	b_mesh.radius = 0.32
	b_mesh.height = 1.35
	b_mesh.material = coat_mat
	body.mesh = b_mesh
	body.position = Vector3(0.0, 0.32, 0.0)
	body.rotation_degrees.x = 90.0
	add_child(body)

	# 2. Articulated Neck & Head Pivot (Raised alertly looking out to sea)
	_head_pivot = Node3D.new()
	_head_pivot.position = Vector3(0.0, 0.46, -0.52)
	add_child(_head_pivot)

	var head = MeshInstance3D.new()
	var h_mesh = SphereMesh.new()
	h_mesh.radius = 0.23
	h_mesh.height = 0.44
	h_mesh.material = coat_mat
	head.mesh = h_mesh
	head.position = Vector3(0.0, 0.16, -0.08)
	_head_pivot.add_child(head)

	# Snout & Nose
	var snout = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.13
	s_mesh.height = 0.26
	s_mesh.material = coat_mat
	snout.mesh = s_mesh
	snout.position = Vector3(0.0, 0.14, -0.26)
	_head_pivot.add_child(snout)

	var nose = MeshInstance3D.new()
	var n_mesh = SphereMesh.new()
	n_mesh.radius = 0.045
	n_mesh.height = 0.08
	n_mesh.material = dark_mat
	nose.mesh = n_mesh
	nose.position = Vector3(0.0, 0.17, -0.37)
	_head_pivot.add_child(nose)

	# Eyes
	for eye_x in [-0.11, 0.11]:
		var eye = MeshInstance3D.new()
		var e_mesh = SphereMesh.new()
		e_mesh.radius = 0.04
		e_mesh.height = 0.08
		e_mesh.material = dark_mat
		eye.mesh = e_mesh
		eye.position = Vector3(eye_x, 0.22, -0.22)
		_head_pivot.add_child(eye)

	# 3. Articulated Front Flippers
	_left_flipper = Node3D.new()
	_left_flipper.position = Vector3(-0.28, 0.22, -0.25)
	var lf_mesh_inst = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = Vector3(0.42, 0.07, 0.24)
	f_mesh.material = coat_mat
	lf_mesh_inst.mesh = f_mesh
	lf_mesh_inst.position = Vector3(-0.18, 0.0, 0.0)
	_left_flipper.add_child(lf_mesh_inst)
	add_child(_left_flipper)

	_right_flipper = Node3D.new()
	_right_flipper.position = Vector3(0.28, 0.22, -0.25)
	var rf_mesh_inst = MeshInstance3D.new()
	rf_mesh_inst.mesh = f_mesh
	rf_mesh_inst.position = Vector3(0.18, 0.0, 0.0)
	_right_flipper.add_child(rf_mesh_inst)
	add_child(_right_flipper)

	# 4. Rear Tail Flukes
	_tail_pivot = Node3D.new()
	_tail_pivot.position = Vector3(0.0, 0.20, 0.62)
	var tail_inst = MeshInstance3D.new()
	var t_mesh = PrismMesh.new()
	t_mesh.size = Vector3(0.48, 0.08, 0.38)
	t_mesh.material = coat_mat
	tail_inst.mesh = t_mesh
	tail_inst.position = Vector3(0.0, 0.0, 0.16)
	tail_inst.rotation_degrees.x = 90.0
	_tail_pivot.add_child(tail_inst)
	add_child(_tail_pivot)

func _build_interaction() -> void:
	var area = Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1 << 5
	area.collision_mask = 0
	var col = CollisionShape3D.new()
	var sp = SphereShape3D.new()
	sp.radius = 2.4
	col.shape = sp
	col.position = Vector3(0.0, 0.5, 0.0)
	area.add_child(col)
	add_child(area)

func get_prompt_text() -> String:
	return "[E] Pet " + seal_name

func interact(_player: Node = null) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_mission_notification"):
		hud.show_mission_notification("🦭 The Harbor Seal barks happily and claps its flippers!")

func _process(delta: float) -> void:
	_anim_time += delta * 2.6
	if _head_pivot:
		_head_pivot.rotation_degrees.x = sin(_anim_time) * 10.0
		_head_pivot.rotation_degrees.y = cos(_anim_time * 0.7) * 14.0
	if _left_flipper:
		_left_flipper.rotation_degrees.z = -12.0 + sin(_anim_time * 1.8) * 14.0
	if _right_flipper:
		_right_flipper.rotation_degrees.z = 12.0 - sin(_anim_time * 1.8) * 14.0
	if _tail_pivot:
		_tail_pivot.rotation_degrees.y = sin(_anim_time * 1.5) * 12.0
