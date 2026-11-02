class_name ShipwrightDrydock3D
extends Node3D

## ShipwrightDrydock3D
## Shipwright Master Owen & Apprentice Pip's harbor drydock.
## Features an inclined timber slipway, oak keel framing, animated apprentice hammering,
## and an interactive Shipyard Upgrades Workbench.

@export var hammer_interval: float = 2.4

var _hammer_timer: float = 0.0
var _apprentice_model: Node3D = null
var _anim_player: AnimationPlayer = null
var _workbench_node: Node3D = null

var interact_prompt: String = "[E] Shipyard Upgrades & Hull Repairs"

# Ship upgrades tracked per playthrough
static var ship_ironclad: bool = false
static var ship_flaming_shot: bool = false
static var ship_ram_prow: bool = false

func _ready() -> void:
	add_to_group("harbor_structures")
	add_to_group("interactable")
	_build_drydock_structure()

func _build_drydock_structure() -> void:
	# 1. Timber Slipway (inclined wooden ramp descending into the tide)
	var slipway = MeshInstance3D.new()
	var ramp = BoxMesh.new()
	ramp.size = Vector3(8.0, 0.6, 14.0)
	slipway.mesh = ramp
	slipway.position = Vector3(0.0, 0.1, 0.0)
	slipway.rotation_degrees.x = 6.0 # tilted toward the water
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.42, 0.28, 0.16)
	wood_mat.roughness = 0.85
	slipway.material_override = wood_mat
	add_child(slipway)

	# Slipway collision
	var static_body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(8.0, 0.6, 14.0)
	col.shape = box_shape
	col.position = Vector3(0.0, 0.1, 0.0)
	col.rotation_degrees.x = 6.0
	static_body.add_child(col)
	add_child(static_body)

	# 2. Keel support blocks & scaffolding timbers
	for z_pos in [-4.0, -1.0, 2.0, 5.0]:
		var block = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(3.6, 0.5, 0.6)
		block.mesh = b_mesh
		block.position = Vector3(0.0, 0.5, z_pos)
		var oak_mat = StandardMaterial3D.new()
		oak_mat.albedo_color = Color(0.3, 0.18, 0.1)
		block.material_override = oak_mat
		add_child(block)

	# 3. Ship Hull under repair (small boat or ribs on cradle)
	var hull_path = "res://assets/ships/boat-fishing-small.glb"
	if ResourceLoader.exists(hull_path):
		var h_scene = load(hull_path)
		if h_scene:
			var h_inst = h_scene.instantiate()
			h_inst.scale = Vector3(1.6, 1.6, 1.6)
			h_inst.position = Vector3(0.0, 1.1, 0.5)
			h_inst.rotation_degrees.y = 90.0
			add_child(h_inst)
	else:
		var hull_box = MeshInstance3D.new()
		var h_box = BoxMesh.new()
		h_box.size = Vector3(2.5, 1.2, 7.0)
		hull_box.mesh = h_box
		hull_box.position = Vector3(0.0, 1.2, 0.5)
		add_child(hull_box)

	# 4. Animated Apprentice Pip hammering oak planks
	_spawn_apprentice_pip()

	# 5. Master Owen's Workbench
	_spawn_shipwright_workbench()

func _spawn_apprentice_pip() -> void:
	var char_path = "res://assets/characters/adventurers/Rogue.glb"
	if ResourceLoader.exists(char_path):
		var c_scene = load(char_path)
		if c_scene:
			_apprentice_model = c_scene.instantiate()
			_apprentice_model.position = Vector3(1.8, 0.4, 0.8)
			_apprentice_model.rotation_degrees.y = -85.0
			add_child(_apprentice_model)

			# Find AnimationPlayer
			_anim_player = _find_animation_player(_apprentice_model)
			if _anim_player:
				if _anim_player.has_animation("Interact"):
					_anim_player.play("Interact")
				elif _anim_player.has_animation("PickUp"):
					_anim_player.play("PickUp")

	# If no character model, procedural apprentice dummy
	if not _apprentice_model:
		var dummy = MeshInstance3D.new()
		var cap = CapsuleMesh.new()
		cap.radius = 0.3
		cap.height = 1.6
		dummy.mesh = cap
		dummy.position = Vector3(1.8, 1.0, 0.8)
		add_child(dummy)

func _spawn_shipwright_workbench() -> void:
	_workbench_node = Node3D.new()
	_workbench_node.position = Vector3(-2.8, 0.3, -3.5)
	
	# Table mesh
	var table = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(1.8, 0.8, 1.2)
	table.mesh = t_box
	table.position.y = 0.4
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.48, 0.32, 0.18)
	table.material_override = t_mat
	_workbench_node.add_child(table)

	# Nautical blueprint roll on table
	var blueprint = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.08
	b_cyl.bottom_radius = 0.08
	b_cyl.height = 0.7
	blueprint.mesh = b_cyl
	blueprint.position = Vector3(0.0, 0.85, 0.0)
	blueprint.rotation_degrees.z = 90.0
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.2, 0.5, 0.85)
	blueprint.material_override = b_mat
	_workbench_node.add_child(blueprint)

	# Table lantern
	var lantern = OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.85, 0.55)
	lantern.light_energy = 1.2
	lantern.omni_range = 5.0
	lantern.position.y = 1.2
	_workbench_node.add_child(lantern)

	add_child(_workbench_node)

func _process(delta: float) -> void:
	_hammer_timer += delta
	if _hammer_timer >= hammer_interval:
		_hammer_timer = 0.0
		_trigger_hammer_strike()

func _trigger_hammer_strike() -> void:
	AudioManager.play_sfx_at_position("wood_hammering", global_position + Vector3(1.0, 0.8, 0.5), 28.0, 0.12, -2.0)
	
	# Wood chips / sawdust particle burst
	_spawn_wood_chips()

func _spawn_wood_chips() -> void:
	for i in range(5):
		var chip = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.04, 0.04, 0.04)
		chip.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.65, 0.45)
		chip.material_override = mat
		get_tree().current_scene.add_child(chip)
		chip.global_position = global_position + Vector3(1.2 + randf_range(-0.1, 0.1), 0.9, 0.6 + randf_range(-0.1, 0.1))

		var tw = chip.create_tween()
		var velocity = Vector3(randf_range(-0.6, 0.6), randf_range(0.8, 1.8), randf_range(-0.6, 0.6))
		tw.tween_property(chip, "global_position", chip.global_position + velocity, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(chip, "global_position:y", 0.1, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(chip.queue_free)

func interact(player: Node) -> void:
	open_shipyard_menu(player)

func open_shipyard_menu(player: Node = null) -> void:
	var gold = 100
	if GameManager.has_method("get_gold"):
		gold = GameManager.get_gold()

	# Check what upgrades are pending
	if not ship_ironclad and gold >= 40:
		ship_ironclad = true
		if GameManager.has_method("spend_gold"):
			GameManager.spend_gold(40)
		_apply_upgrade_to_ships("ironclad")
		HUD.show_notification("Purchased Ironclad Hull Plating! (+200 Ship HP) [-40 Gold]")
		AudioManager.play_sfx("anvil_strike")
		return
	elif not ship_flaming_shot and gold >= 50:
		ship_flaming_shot = true
		if GameManager.has_method("spend_gold"):
			GameManager.spend_gold(50)
		_apply_upgrade_to_ships("flaming_shot")
		HUD.show_notification("Purchased Flaming Pitch Munitions! (+15 Cannon Fire DOT) [-50 Gold]")
		AudioManager.play_sfx("anvil_strike")
		return
	elif not ship_ram_prow and gold >= 60:
		ship_ram_prow = true
		if GameManager.has_method("spend_gold"):
			GameManager.spend_gold(60)
		_apply_upgrade_to_ships("ram_prow")
		HUD.show_notification("Fitted Bronze Naval Ram Prow! (+100 Ram Impact Damage) [-60 Gold]")
		AudioManager.play_sfx("anvil_strike")
		return
	else:
		# Repair any damaged ships
		var repaired_any = false
		for ship in get_tree().get_nodes_in_group("player_ships"):
			if ship.has_method("repair_hull"):
				ship.repair_hull(250)
				repaired_any = true
		if repaired_any:
			HUD.show_notification("Master Owen patched your fleet hulls back to full seaworthiness!")
			AudioManager.play_sfx("anvil_strike")
		else:
			HUD.show_notification("Master Owen: 'All ships in the harbor are primed and sea-ready, Captain!'")

func _apply_upgrade_to_ships(upgrade_type: String) -> void:
	for ship in get_tree().get_nodes_in_group("player_ships"):
		if ship.has_method("apply_shipyard_upgrade"):
			ship.apply_shipyard_upgrade(upgrade_type)

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null
