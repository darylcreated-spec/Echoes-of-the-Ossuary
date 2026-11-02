extends Node3D
class_name HarborAlarmBell3D

@export var is_ringing: bool = false
var _bell_pivot: Node3D = null
var _ring_tween: Tween = null
var _cooldown: float = 0.0

func _ready() -> void:
	name = "HarborAlarmBell3D"
	add_to_group("harbor_alarm_bell")
	add_to_group("interactable")
	_build_visuals()
	_setup_interaction()

func _build_visuals() -> void:
	var timber_mat = StandardMaterial3D.new()
	timber_mat.albedo_color = Color(0.28, 0.18, 0.10)
	timber_mat.roughness = 0.88

	var bronze_mat = StandardMaterial3D.new()
	bronze_mat.albedo_color = Color(0.72, 0.52, 0.22)
	bronze_mat.metallic = 0.85
	bronze_mat.roughness = 0.35

	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.20, 0.21, 0.23)
	iron_mat.metallic = 0.90
	iron_mat.roughness = 0.40

	# 1. Timber Posts (Twin vertical support pillars)
	for side_x in [-0.75, 0.75]:
		var post = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.12
		p_mesh.bottom_radius = 0.15
		p_mesh.height = 3.4
		post.mesh = p_mesh
		post.material_override = timber_mat
		post.position = Vector3(side_x, 1.7, 0.0)
		add_child(post)

	# 2. Horizontal Crossbar Beam
	var beam = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(1.9, 0.22, 0.24)
	beam.mesh = b_mesh
	beam.material_override = timber_mat
	beam.position = Vector3(0.0, 3.15, 0.0)
	add_child(beam)

	# 3. Bronze Bell on Pivot
	_bell_pivot = Node3D.new()
	_bell_pivot.position = Vector3(0.0, 2.95, 0.0)
	add_child(_bell_pivot)

	# Bell Body
	var bell_mesh = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.22
	cy.bottom_radius = 0.52
	cy.height = 0.85
	bell_mesh.mesh = cy
	bell_mesh.material_override = bronze_mat
	bell_mesh.position = Vector3(0.0, -0.42, 0.0)
	_bell_pivot.add_child(bell_mesh)

	# Bell Crown / Yoke
	var crown = MeshInstance3D.new()
	var cr_mesh = TorusMesh.new()
	cr_mesh.inner_radius = 0.08
	cr_mesh.outer_radius = 0.16
	crown.mesh = cr_mesh
	crown.material_override = iron_mat
	crown.position = Vector3(0.0, 0.02, 0.0)
	crown.rotation_degrees.x = 90.0
	_bell_pivot.add_child(crown)

	# Clapper / Striker
	var clapper = MeshInstance3D.new()
	var cl_mesh = SphereMesh.new()
	cl_mesh.radius = 0.10
	cl_mesh.height = 0.20
	clapper.mesh = cl_mesh
	clapper.material_override = iron_mat
	clapper.position = Vector3(0.0, -0.85, 0.0)
	_bell_pivot.add_child(clapper)

	# Hanging Pull Rope
	var rope = MeshInstance3D.new()
	var rp_mesh = CylinderMesh.new()
	rp_mesh.top_radius = 0.02
	rp_mesh.bottom_radius = 0.02
	rp_mesh.height = 1.6
	rope.mesh = rp_mesh
	rope.material_override = timber_mat
	rope.position = Vector3(0.35, 1.8, 0.0)
	add_child(rope)

	# 4. Timber Rooflet Weather Cover
	var roof = MeshInstance3D.new()
	var rf_mesh = BoxMesh.new()
	rf_mesh.size = Vector3(2.2, 0.12, 1.2)
	roof.mesh = rf_mesh
	roof.material_override = timber_mat
	roof.position = Vector3(0.0, 3.45, 0.0)
	add_child(roof)

	# 5. Warning Brass Lantern
	var lantern_node = AssetLoader.load_or_generate_model("res://assets/overworld/post_lantern.gltf", "prop", "post_lantern")
	if lantern_node:
		lantern_node.scale = Vector3.ONE * 1.3
		lantern_node.position = Vector3(-0.95, 2.2, 0.0)
		add_child(lantern_node)

	# 6. High-Visibility Overhead Label
	var lbl = Label3D.new()
	lbl.position = Vector3(0.0, 4.0, 0.0)
	AssetLoader.style_world_label3d(lbl, "🔔 Harbor Alarm Bell\n[E] Sound Alarm", 38, Color(1.0, 0.92, 0.65))
	add_child(lbl)

	# Base Static Collider
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.0, 3.5, 0.8)
	cs.shape = box
	cs.position = Vector3(0.0, 1.7, 0.0)
	sb.add_child(cs)
	add_child(sb)

func _setup_interaction() -> void:
	var area = Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 1 << 5
	area.collision_mask = 0
	var cs = CollisionShape3D.new()
	var sp = SphereShape3D.new()
	sp.radius = 2.8
	cs.shape = sp
	cs.position = Vector3(0.0, 1.2, 0.0)
	area.add_child(cs)
	add_child(area)

func get_prompt_text() -> String:
	return "[E] Sound Harbor Alarm / Repel Naval Invasion"

func interact(_player: Node = null) -> void:
	if _cooldown > 0.0:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("⏳ The harbor alarm echoes across the bay! Wait for the bell to settle.")
		return

	_cooldown = 12.0
	is_ringing = true
	AudioManager.play_sfx_at_position("harbor_bell", global_position, 48.0, 0.05, 4.0)
	AudioManager.play_sfx_at_position("naval_horn", global_position + Vector3(0, 4, 0), 60.0, 0.12, 2.0)
	CombatJuice.add_trauma(0.12)

	# Animate bell swing
	if _ring_tween and _ring_tween.is_valid():
		_ring_tween.kill()
	_ring_tween = create_tween()
	_ring_tween.tween_property(_bell_pivot, "rotation_degrees:z", 26.0, 0.18).set_trans(Tween.TRANS_SINE)
	_ring_tween.tween_property(_bell_pivot, "rotation_degrees:z", -24.0, 0.22).set_trans(Tween.TRANS_SINE)
	_ring_tween.tween_property(_bell_pivot, "rotation_degrees:z", 18.0, 0.20).set_trans(Tween.TRANS_SINE)
	_ring_tween.tween_property(_bell_pivot, "rotation_degrees:z", -12.0, 0.20).set_trans(Tween.TRANS_SINE)
	_ring_tween.tween_property(_bell_pivot, "rotation_degrees:z", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	_ring_tween.tween_callback(func(): is_ringing = false)

	# Broadcast invasion trigger to world
	trigger_naval_invasion()

func trigger_naval_invasion() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🚨 ALL HANDS ON DECK! An invading Corsair Fleet approaches Port Blackwater!")

	# Notify active ships, harbor towers, and spawn enemy ships if needed
	var enemy_ships = get_tree().get_nodes_in_group("enemy_naval_ship")
	var needs_spawn = true
	for es in enemy_ships:
		if is_instance_valid(es) and not es.is_queued_for_deletion():
			needs_spawn = false
			if es.has_method("alert_invasion"):
				es.alert_invasion()

	if needs_spawn:
		var spawner = get_tree().get_first_node_in_group("naval_invasion_spawner")
		if spawner and spawner.has_method("spawn_corsair_fleet"):
			spawner.spawn_corsair_fleet()
		else:
			# Direct fallback spawn into current scene
			var EnemyNavalShipScript = load("res://src/world/EnemyNavalShip3D.gd")
			if EnemyNavalShipScript:
				var raider = EnemyNavalShipScript.new()
				raider.ship_name = "Black Leviathan"
				raider.position = Vector3(-124.0, -0.22, 68.0)
				raider.rotation_degrees.y = -90.0 # Facing East toward port
				get_tree().current_scene.add_child(raider)

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
