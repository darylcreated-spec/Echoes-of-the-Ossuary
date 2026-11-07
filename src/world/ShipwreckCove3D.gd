class_name ShipwreckCove3D
extends Node3D

## ShipwreckCove3D
## Treacherous reef cove in the southwest shallows with jagged rocks,
## the rotting split timbers of the caravel "Siren's Fortune",
## sea breakers, and an interactive Sunken Captain's Lockbox.

var _chest_opened: bool = false
var _chest_node: Node3D = null
var _creak_timer: float = 0.0

var interact_prompt: String = "[E] Inspect Sunken Captain's Lockbox"

func _ready() -> void:
	add_to_group("harbor_structures")
	add_to_group("interactable")
	_build_cove_environment()

func _build_cove_environment() -> void:
	# 1. Jagged Reef Rocks
	var rock_a_path = "res://assets/ships/rocks-a.glb"
	var rock_b_path = "res://assets/ships/rocks-b.glb"
	var rock_offsets = [
		Vector3(-4.0, -0.5, -3.0),
		Vector3(5.0, -0.3, -2.0),
		Vector3(2.0, -0.6, 6.0),
		Vector3(-6.0, -0.4, 4.0),
		Vector3(0.0, -0.7, -7.0)
	]
	
	for i in range(rock_offsets.size()):
		var path = rock_a_path if i % 2 == 0 else rock_b_path
		if ResourceLoader.exists(path):
			var r_scene = load(path)
			if r_scene:
				var r_inst = r_scene.instantiate()
				r_inst.position = rock_offsets[i]
				r_inst.scale = Vector3.ONE * randf_range(1.6, 2.4)
				r_inst.rotation.y = randf_range(0.0, TAU)
				add_child(r_inst)

	# 2. Split Timbers Wreck Hull
	var wreck_path = "res://assets/ships/ship-wreck.glb"
	var w_inst = AssetLoader.load_or_generate_model(wreck_path, "prop", "shipwreck")
	if w_inst:
		w_inst.scale = Vector3(1.8, 1.8, 1.8)
		w_inst.rotation_degrees = Vector3(14.0, 42.0, -18.0)
		w_inst.position = Vector3(0.0, 0.2, 0.0)
		add_child(w_inst)
	else:
		# Fallback procedural broken hull
		var hull_box = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(4.0, 2.0, 10.0)
		hull_box.mesh = box
		hull_box.rotation_degrees = Vector3(12.0, 35.0, -15.0)
		var wood_mat = StandardMaterial3D.new()
		wood_mat.albedo_color = Color(0.25, 0.18, 0.12)
		hull_box.material_override = wood_mat
		add_child(hull_box)

	# Collision body for the reef & hull so the player can walk on it
	var static_body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(8.0, 3.0, 12.0)
	col.shape = col_box
	col.position.y = 0.5
	static_body.add_child(col)
	add_child(static_body)

	# 3. Sea Breakers & Foam Splash
	_setup_breaker_foam()

	# 4. Sunken Captain's Lockbox
	_spawn_lockbox()

func _setup_breaker_foam() -> void:
	# Foam ring at water level
	var foam = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 4.0
	torus.outer_radius = 7.5
	foam.mesh = torus
	foam.position = Vector3(0.0, 0.05, 0.0)
	var foam_mat = StandardMaterial3D.new()
	foam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.35)
	foam_mat.roughness = 0.1
	foam.material_override = foam_mat
	add_child(foam)

func _spawn_lockbox() -> void:
	_chest_node = Node3D.new()
	_chest_node.name = "SunkenLockbox"
	_chest_node.position = Vector3(1.2, 0.9, -1.5)
	_chest_node.rotation_degrees = Vector3(8.0, -25.0, 5.0)
	
	var chest_path = "res://assets/ships/chest.glb"
	if ResourceLoader.exists(chest_path):
		var c_scene = load(chest_path)
		if c_scene:
			var c_inst = c_scene.instantiate()
			c_inst.scale = Vector3(1.4, 1.4, 1.4)
			_chest_node.add_child(c_inst)
	else:
		var c_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.9, 0.6, 0.7)
		c_mesh.mesh = box
		var brass_mat = StandardMaterial3D.new()
		brass_mat.albedo_color = Color(0.5, 0.35, 0.15)
		c_mesh.material_override = brass_mat
		_chest_node.add_child(c_mesh)

	# Lockbox aura light
	var aura = OmniLight3D.new()
	aura.name = "LockboxAura"
	aura.light_color = Color(0.4, 0.8, 1.0)
	aura.light_energy = 1.8
	aura.omni_range = 4.0
	aura.position.y = 0.5
	_chest_node.add_child(aura)

	var lbl = Label3D.new()
	lbl.position = Vector3(0.0, 2.2, 0.0)
	AssetLoader.style_world_label3d(lbl, "🗝️ Sunken Captain's Lockbox\n[E] Inspect Treasure", 52, Color(0.55, 0.94, 1.0))
	_chest_node.add_child(lbl)

	add_child(_chest_node)

func _process(delta: float) -> void:
	_creak_timer += delta
	if _creak_timer >= 12.0:
		_creak_timer = 0.0
		AudioManager.play_sfx_at_position("creaking_rigging", global_position, 35.0, 0.1, -4.0)

func interact(player: Node) -> void:
	if _chest_opened:
		HUD.show_notification("The Sunken Captain's Lockbox has already been salvaged.")
		return
	
	open_lockbox(player)

func open_lockbox(player: Node = null) -> void:
	if _chest_opened:
		return
	_chest_opened = true
	interact_prompt = ""

	AudioManager.play_sfx_at_position("chest_open", global_position, 40.0)
	
	if GameManager.has_method("add_echoes"):
		GameManager.add_echoes(50)
	if GameManager.has_method("add_gold"):
		GameManager.add_gold(30)
	
	# Grant Shipyard Upgrade Blueprint: Ironcladding / Ram Prow
	if player and "unlocked_ship_blueprints" in player:
		player.unlocked_ship_blueprints.append("ancient_ram_prow")

	HUD.show_notification("Salvaged Sunken Captain's Lockbox! (+50 Soul Echoes, +30 Gold, Ancient Ram Prow Blueprint)")
	
	# Visual reward splash & sparkle
	_spawn_salvage_particles()

	# Dim aura
	var aura = _chest_node.get_node_or_null("LockboxAura") as OmniLight3D
	if aura:
		aura.light_energy = 0.2

func _spawn_salvage_particles() -> void:
	for i in range(16):
		var gold_coin = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.12
		cyl.height = 0.04
		gold_coin.mesh = cyl
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.84, 0.0)
		mat.metallic = 0.9
		gold_coin.material_override = mat
		get_tree().current_scene.add_child(gold_coin)
		gold_coin.global_position = _chest_node.global_position + Vector3(0.0, 0.4, 0.0)
		
		var tw = gold_coin.create_tween()
		var spread = Vector3(randf_range(-1.2, 1.2), randf_range(1.2, 2.8), randf_range(-1.2, 1.2))
		var end_pos = gold_coin.global_position + spread
		tw.tween_property(gold_coin, "global_position", end_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(gold_coin, "global_position:y", 0.1, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(gold_coin.queue_free)
