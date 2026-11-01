extends Node3D
class_name HarborSeal3D

@export var seal_name: String = "Coastal Harbor Seal"
@export var waddle_speed: float = 1.45
@export var waypoints: Array = []

var _body_mesh: MeshInstance3D = null
var _head_pivot: Node3D = null
var _left_flipper: Node3D = null
var _right_flipper: Node3D = null
var _tail_pivot: Node3D = null
var _anim_time: float = 0.0
var _wp_idx: int = 0
var _bask_timer: float = 0.0
var _bark_timer: float = 0.0
var _origin_ready: bool = false

func _ready() -> void:
	add_to_group("harbor_seal")
	add_to_group("interactable")
	_anim_time = randf_range(0.0, 25.0)
	_bark_timer = randf_range(4.0, 11.0)
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
	_body_mesh = MeshInstance3D.new()
	var b_mesh = CapsuleMesh.new()
	b_mesh.radius = 0.32
	b_mesh.height = 1.35
	b_mesh.material = coat_mat
	_body_mesh.mesh = b_mesh
	_body_mesh.position = Vector3(0.0, 0.32, 0.0)
	_body_mesh.rotation_degrees.x = 90.0
	add_child(_body_mesh)

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
	AudioManager.play_sfx_at_position("seal_bark", global_position, 28.0, 0.08, 0.0)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🦭 " + seal_name + " barks happily ('Arf! Arf!') and claps its flippers!")
	elif hud and hud.has_method("show_mission_notification"):
		hud.show_mission_notification("🦭 The Harbor Seal barks happily and claps its flippers!")

func _process(delta: float) -> void:
	if not _origin_ready:
		_origin_ready = true
		if waypoints.is_empty():
			waypoints = [
				global_position + Vector3(2.8, 0.0, 2.2),
				global_position + Vector3(-2.4, 0.0, 3.0),
				global_position
			]

	_anim_time += delta * 4.2
	_bark_timer -= delta
	if _bark_timer <= 0.0:
		_bark_timer = randf_range(6.5, 14.0)
		AudioManager.play_sfx_at_position("seal_bark", global_position, 22.0, 0.12, -5.0)

	var is_moving = true
	if _bask_timer > 0.0:
		_bask_timer -= delta
		is_moving = false
	elif not waypoints.is_empty():
		var target: Vector3 = waypoints[_wp_idx]
		var diff = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
		if diff.length() < 0.4:
			_wp_idx = (_wp_idx + 1) % waypoints.size()
			_bask_timer = randf_range(1.2, 2.6)
			is_moving = false
		else:
			var dir = diff.normalized()
			global_position += dir * waddle_speed * delta
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 4.5)

	var speed_mult = 1.8 if is_moving else 0.75
	if _body_mesh:
		_body_mesh.position.y = 0.32 + (abs(sin(_anim_time * speed_mult)) * 0.06 if is_moving else 0.0)
	if _head_pivot:
		_head_pivot.rotation_degrees.x = sin(_anim_time * speed_mult) * 12.0
		_head_pivot.rotation_degrees.y = cos(_anim_time * 0.7) * 14.0
	if _left_flipper:
		_left_flipper.rotation_degrees.z = -12.0 + sin(_anim_time * 1.8 * speed_mult) * 20.0
		_left_flipper.rotation_degrees.y = cos(_anim_time * 1.8 * speed_mult) * (22.0 if is_moving else 6.0)
	if _right_flipper:
		_right_flipper.rotation_degrees.z = 12.0 - sin(_anim_time * 1.8 * speed_mult) * 20.0
		_right_flipper.rotation_degrees.y = -cos(_anim_time * 1.8 * speed_mult) * (22.0 if is_moving else 6.0)
	if _tail_pivot:
		_tail_pivot.rotation_degrees.y = sin(_anim_time * 1.6 * speed_mult) * 18.0
