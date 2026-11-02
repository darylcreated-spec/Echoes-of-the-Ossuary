extends Node3D
class_name HarborLadder3D

@export var target_deck_position: Vector3 = Vector3.ZERO
@export var ladder_height: float = 1.25
@export var has_lantern: bool = true

var _interact_area: Area3D = null

func _ready() -> void:
	name = "HarborLadder3D"
	add_to_group("harbor_ladder")
	add_to_group("interactable")
	_build_visuals()
	_setup_interaction_area()

func _build_visuals() -> void:
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.28, 0.18, 0.10) # Dark water-soaked oak timber
	wood_mat.roughness = 0.92

	# 1. Twin Vertical Side Rails (Dipping from Y = -0.55m in water to Y = +0.55m above pier)
	for side_x in [-0.28, 0.28]:
		var rail = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.04
		cyl.bottom_radius = 0.04
		cyl.height = ladder_height
		rail.mesh = cyl
		rail.material_override = wood_mat
		rail.position = Vector3(side_x, -0.05, 0.0)
		add_child(rail)

	# 2. Horizontal Ladder Rungs (5 sturdy wooden steps)
	var rung_step = 0.22
	for i in range(5):
		var rung_y = -0.48 + float(i) * rung_step
		var rung = MeshInstance3D.new()
		var r_mesh = CylinderMesh.new()
		r_mesh.top_radius = 0.03
		r_mesh.bottom_radius = 0.03
		r_mesh.height = 0.54
		rung.mesh = r_mesh
		rung.material_override = wood_mat
		rung.rotation_degrees.z = 90.0
		rung.position = Vector3(0.0, rung_y, 0.0)
		add_child(rung)

	# 3. Top Handrail Arches (Iron mooring handles for hauling oneself up)
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.22, 0.23, 0.25)
	iron_mat.metallic = 0.85
	iron_mat.roughness = 0.4
	
	for side_x in [-0.28, 0.28]:
		var handle = MeshInstance3D.new()
		var tor = TorusMesh.new()
		tor.inner_radius = 0.06
		tor.outer_radius = 0.10
		handle.mesh = tor
		handle.material_override = iron_mat
		handle.rotation_degrees.x = 90.0
		handle.position = Vector3(side_x, 0.58, 0.0)
		add_child(handle)

	# 4. Optional Top Brass Warning Lantern
	if has_lantern:
		var lantern = AssetLoader.load_or_generate_model("res://assets/overworld/post_lantern.gltf", "prop", "post_lantern")
		if lantern:
			lantern.position = Vector3(0.48, 0.24, 0.15)
			lantern.scale = Vector3.ONE * 1.3
			add_child(lantern)

	# 5. Low Walkable Step-Ramp at Base (Assists physics walking/vaulting into ladder)
	var sb = StaticBody3D.new()
	sb.name = "LadderStepCollider"
	sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.7, 0.45, 0.55)
	cs.shape = box
	cs.position = Vector3(0.0, -0.15, 0.12)
	cs.rotation_degrees.x = -22.0
	sb.add_child(cs)
	add_child(sb)

func _setup_interaction_area() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "LadderInteractArea"
	_interact_area.collision_layer = 1 << 5 # Layer 6: Interactable
	_interact_area.collision_mask = 0
	
	var cs = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.4
	cs.shape = sphere
	cs.position = Vector3(0.0, -0.1, 0.0)
	_interact_area.add_child(cs)
	add_child(_interact_area)

func get_prompt_text() -> String:
	return "[E] Climb Up to Pier"

func interact(player: Node3D) -> void:
	if not player or not is_instance_valid(player):
		return

	# Audio & Splash Feedback
	AudioManager.play_sfx("footstep_wood", 0.12, 1.0)
	CombatJuice.spawn_hit_spark(player.global_position + Vector3(0, 0.1, 0), Color(0.65, 0.85, 1.0))
	
	# Determine safe climb landing target
	var dest = target_deck_position
	if dest == Vector3.ZERO:
		var forward = -global_transform.basis.z
		dest = global_position + forward * 1.2 + Vector3(0, 0.45, 0)
	
	player.global_position = dest
	if "velocity" in player:
		player.velocity = Vector3.ZERO
		
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("⚓ Climbed safely onto the harbor pier!")
