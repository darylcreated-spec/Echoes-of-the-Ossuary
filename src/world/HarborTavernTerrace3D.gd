class_name HarborTavernTerrace3D
extends Node3D

## HarborTavernTerrace3D
## Lively outdoor pier terrace outside The Rusty Anchor Tavern.
## Features wooden trestle tables, benches, ale mugs, fish smoking racks,
## and Old Salty Barnaby, the port's veteran shantyman.

var _shantyman_model: Node3D = null
var _anim_player: AnimationPlayer = null
var _singing: bool = false
var interact_prompt: String = "[E] Listen to Old Salty Barnaby's Shanty"

func _ready() -> void:
	add_to_group("harbor_structures")
	add_to_group("interactable")
	_build_terrace()

func _build_terrace() -> void:
	# 1. Wooden Boardwalk Decking
	var deck = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(9.0, 0.2, 7.0)
	deck.mesh = box
	deck.position.y = 0.1
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.26, 0.14)
	deck.material_override = wood_mat
	add_child(deck)

	# 2. Outdoor Trestle Tables and Benches
	for z_offset in [-1.8, 1.8]:
		_spawn_trestle_table(Vector3(-1.5, 0.2, z_offset))

	# 3. Fish Drying Rack
	_spawn_fish_drying_rack(Vector3(3.2, 0.2, -2.0))

	# 4. Old Salty Barnaby (Shantyman NPC)
	_spawn_shantyman(Vector3(1.5, 0.2, 1.2))

	# 5. Terrace Overhead Lantern
	var post = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.1
	p_cyl.bottom_radius = 0.12
	p_cyl.height = 3.2
	post.mesh = p_cyl
	post.position = Vector3(3.5, 1.6, 2.5)
	var post_mat = StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.25, 0.16, 0.1)
	post.material_override = post_mat
	add_child(post)

	var lamp = OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.78, 0.45) # warm tavern amber
	lamp.light_energy = 2.2
	lamp.omni_range = 8.5
	lamp.position = Vector3(3.5, 3.0, 2.5)
	add_child(lamp)

func _spawn_trestle_table(pos: Vector3) -> void:
	var table_root = Node3D.new()
	table_root.position = pos

	# Table surface
	var table = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(2.4, 0.1, 1.1)
	table.mesh = t_box
	table.position.y = 0.75
	var oak_mat = StandardMaterial3D.new()
	oak_mat.albedo_color = Color(0.45, 0.3, 0.18)
	table.material_override = oak_mat
	table_root.add_child(table)

	# Ale Steins on table
	for mug_x in [-0.6, 0.1, 0.7]:
		var mug = MeshInstance3D.new()
		var m_cyl = CylinderMesh.new()
		m_cyl.top_radius = 0.08
		m_cyl.bottom_radius = 0.08
		m_cyl.height = 0.2
		mug.mesh = m_cyl
		mug.position = Vector3(mug_x, 0.9, randf_range(-0.2, 0.2))
		var clay_mat = StandardMaterial3D.new()
		clay_mat.albedo_color = Color(0.65, 0.52, 0.38)
		mug.material_override = clay_mat
		table_root.add_child(mug)

	# Benches on both sides
	for side in [-0.8, 0.8]:
		var bench = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(2.2, 0.08, 0.4)
		bench.mesh = b_box
		bench.position = Vector3(0.0, 0.45, side)
		bench.material_override = oak_mat
		table_root.add_child(bench)

	add_child(table_root)

func _spawn_fish_drying_rack(pos: Vector3) -> void:
	var rack = Node3D.new()
	rack.position = pos

	# Two vertical stakes and crossbar
	var bar = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = 2.4
	bar.mesh = cyl
	bar.position = Vector3(0.0, 1.8, 0.0)
	bar.rotation_degrees.z = 90.0
	rack.add_child(bar)

	# Hanging fish shapes
	for f in range(5):
		var fish = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(0.18, 0.45, 0.06)
		fish.mesh = prism
		fish.position = Vector3(-0.9 + f * 0.45, 1.45, 0.0)
		fish.rotation_degrees.x = 180.0
		var fish_mat = StandardMaterial3D.new()
		fish_mat.albedo_color = Color(0.4, 0.55, 0.65)
		fish.material_override = fish_mat
		rack.add_child(fish)

	add_child(rack)

func _spawn_shantyman(pos: Vector3) -> void:
	var char_path = "res://assets/characters/adventurers/Barbarian.glb"
	if ResourceLoader.exists(char_path):
		var scene = load(char_path)
		if scene:
			_shantyman_model = scene.instantiate()
			_shantyman_model.scale = Vector3(0.85, 0.85, 0.85)
			_shantyman_model.position = pos
			_shantyman_model.rotation_degrees.y = -45.0
			add_child(_shantyman_model)

			_anim_player = _find_animation_player(_shantyman_model)
			if _anim_player:
				if _anim_player.has_animation("Cheer"):
					_anim_player.play("Cheer")
				elif _anim_player.has_animation("Idle"):
					_anim_player.play("Idle")

	if not _shantyman_model:
		var dummy = MeshInstance3D.new()
		var cap = CapsuleMesh.new()
		cap.radius = 0.35
		cap.height = 1.7
		dummy.mesh = cap
		dummy.position = pos + Vector3(0.0, 0.85, 0.0)
		add_child(dummy)

func interact(player: Node) -> void:
	play_sea_shanty(player)

func play_sea_shanty(player: Node = null) -> void:
	AudioManager.play_sfx_at_position("sea_shanty_whistle", global_position, 35.0, 0.04, 3.0)

	if _anim_player and _anim_player.has_animation("Cheer"):
		_anim_player.play("Cheer")

	# Spawn floating musical note runes
	_spawn_musical_notes()

	# Grant Sailor's Vigor speed buff to player if supported
	if player and "speed_modifier" in player:
		player.speed_modifier = 1.2
		var tw = get_tree().create_tween()
		tw.tween_interval(45.0)
		tw.tween_callback(func():
			if is_instance_valid(player):
				player.speed_modifier = 1.0
		)

	HUD.show_notification("Old Salty Barnaby whistles 'Leave Her, Johnny'! Sailor's Vigor (+20% Fleet & Sprint Speed for 45s)!")

func _spawn_musical_notes() -> void:
	for i in range(6):
		var note = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		note.mesh = sphere
		var note_mat = StandardMaterial3D.new()
		note_mat.albedo_color = Color(1.0, 0.88, 0.25)
		note_mat.emission_enabled = true
		note_mat.emission = Color(1.0, 0.8, 0.2)
		note_mat.emission_energy_multiplier = 3.0
		note.material_override = note_mat
		get_tree().current_scene.add_child(note)
		note.global_position = global_position + Vector3(1.5, 2.0, 1.2) + Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.3, 0.3))

		var tw = note.create_tween()
		var rise_pos = note.global_position + Vector3(randf_range(-0.8, 0.8), randf_range(1.5, 2.8), randf_range(-0.8, 0.8))
		tw.tween_property(note, "global_position", rise_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(note_mat, "albedo_color:a", 0.0, 1.5)
		tw.tween_callback(note.queue_free)

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null
