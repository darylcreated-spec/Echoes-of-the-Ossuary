extends Node

# Cache for loaded or procedurally generated packed assets
var _model_cache: Dictionary = {}
var _material_cache: Dictionary = {}

func _ready() -> void:
	_init_materials()

# --- MATERIAL FACTORY ---
func _init_materials() -> void:
	# Steel / Armor
	var mat_steel = StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.65, 0.68, 0.72)
	mat_steel.metallic = 0.75
	mat_steel.roughness = 0.35
	_material_cache["steel"] = mat_steel

	# Dark Iron
	var mat_iron = StandardMaterial3D.new()
	mat_iron.albedo_color = Color(0.25, 0.26, 0.28)
	mat_iron.metallic = 0.85
	mat_iron.roughness = 0.4
	_material_cache["dark_iron"] = mat_iron

	# Gold / Brass
	var mat_gold = StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.92, 0.75, 0.22)
	mat_gold.metallic = 0.8
	mat_gold.roughness = 0.25
	_material_cache["gold"] = mat_gold

	# Wood
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.42, 0.26, 0.15)
	mat_wood.roughness = 0.85
	_material_cache["wood"] = mat_wood

	# Leather
	var mat_leather = StandardMaterial3D.new()
	mat_leather.albedo_color = Color(0.32, 0.22, 0.14)
	mat_leather.roughness = 0.7
	_material_cache["leather"] = mat_leather

	# Bone
	var mat_bone = StandardMaterial3D.new()
	mat_bone.albedo_color = Color(0.88, 0.85, 0.76)
	mat_bone.roughness = 0.75
	_material_cache["bone"] = mat_bone

	# Stone
	var mat_stone = StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.38, 0.40, 0.42)
	mat_stone.roughness = 0.9
	_material_cache["stone"] = mat_stone

	# Stone Dark / Flagstone
	var mat_stone_dark = StandardMaterial3D.new()
	mat_stone_dark.albedo_color = Color(0.24, 0.25, 0.28)
	mat_stone_dark.roughness = 0.92
	_material_cache["stone_dark"] = mat_stone_dark

	# Soul Cyan (Glow)
	var mat_cyan = StandardMaterial3D.new()
	mat_cyan.albedo_color = Color(0.1, 0.9, 0.85)
	mat_cyan.emission_enabled = true
	mat_cyan.emission = Color(0.15, 0.95, 0.9)
	mat_cyan.emission_energy_multiplier = 2.5
	_material_cache["glow_cyan"] = mat_cyan

	# Fire Orange (Glow)
	var mat_fire = StandardMaterial3D.new()
	mat_fire.albedo_color = Color(1.0, 0.45, 0.05)
	mat_fire.emission_enabled = true
	mat_fire.emission = Color(1.0, 0.5, 0.1)
	mat_fire.emission_energy_multiplier = 3.0
	_material_cache["glow_fire"] = mat_fire

	# Royal Knight Blue Cloth
	var mat_blue = StandardMaterial3D.new()
	mat_blue.albedo_color = Color(0.18, 0.35, 0.65)
	mat_blue.roughness = 0.8
	_material_cache["cloth_blue"] = mat_blue

	# Rogue Hood Green / Dark
	var mat_green = StandardMaterial3D.new()
	mat_green.albedo_color = Color(0.16, 0.28, 0.19)
	mat_green.roughness = 0.85
	_material_cache["cloth_green"] = mat_green

	# Mage Purple
	var mat_purple = StandardMaterial3D.new()
	mat_purple.albedo_color = Color(0.42, 0.18, 0.62)
	mat_purple.roughness = 0.8
	_material_cache["cloth_purple"] = mat_purple

	# Barbarian Crimson
	var mat_crimson = StandardMaterial3D.new()
	mat_crimson.albedo_color = Color(0.62, 0.16, 0.16)
	mat_crimson.roughness = 0.8
	_material_cache["cloth_crimson"] = mat_crimson

# --- SAFE ASSET INSTANTIATOR ---
func load_or_generate_model(asset_path: String, fallback_type: String, fallback_subtype: String) -> Node3D:
	var candidates: Array[String] = [asset_path]
	if asset_path.ends_with(".glb"):
		candidates.append(asset_path.replace(".glb", ".gltf.glb"))
		candidates.append(asset_path.replace(".glb", ".gltf"))
	elif asset_path.ends_with(".gltf"):
		candidates.append(asset_path + ".glb")
		candidates.append(asset_path.replace(".gltf", ".gltf.glb"))
		candidates.append(asset_path.replace(".gltf", ".glb"))
	
	for candidate in candidates:
		if ResourceLoader.exists(candidate) or FileAccess.file_exists(candidate):
			var res = ResourceLoader.load(candidate)
			if res is PackedScene:
				var instance = res.instantiate()
				if instance is Node3D:
					if "fence_wood" in candidate:
						for c in instance.find_children("*", "MeshInstance3D"):
							if c is MeshInstance3D and c.mesh:
								var aabb = c.mesh.get_aabb()
								if aabb.position.x < -0.5:
									c.position.x += 1.0
					return instance

	# Procedural Fallback Generator
	match fallback_type:
		"character":
			return _create_procedural_character(fallback_subtype)
		"weapon":
			return _create_procedural_weapon(fallback_subtype)
		"dungeon":
			return _create_procedural_dungeon_tile(fallback_subtype)
		"prop":
			return _create_procedural_prop(fallback_subtype, asset_path)
		_:
			return _create_procedural_prop(fallback_subtype, asset_path)

# --- SKELETAL WEAPON SOCKET ATTACHMENT ---
func attach_weapon_socket(character_root: Node3D, weapon_node: Node3D, bone_name: String = "handslot.r") -> void:
	if not character_root or not weapon_node:
		return
		
	var skeleton: Skeleton3D = character_root.find_child("Skeleton3D", true, false)
	if skeleton:
		var bone_idx = skeleton.find_bone(bone_name)
		if bone_idx != -1:
			var socket_name = "Socket_" + bone_name.replace(".", "_")
			var attachment: BoneAttachment3D = skeleton.find_child(socket_name, false, false) as BoneAttachment3D
			if not attachment:
				attachment = BoneAttachment3D.new()
				attachment.name = socket_name
				attachment.bone_name = bone_name
				skeleton.add_child(attachment)
			
			attachment.add_child(weapon_node)
			weapon_node.position = Vector3.ZERO
			# Orient weapon along the hand forward grasp vector
			if bone_name.begins_with("handslot.r"):
				weapon_node.rotation_degrees = Vector3(0, 0, 0)
			else:
				weapon_node.rotation_degrees = Vector3(0, 0, 0)
			return

	# Fallback attachment for procedural / non-skeletal models
	if bone_name.begins_with("handslot.r"):
		var right_arm = character_root.find_child("RightArm", true, false)
		if right_arm:
			right_arm.add_child(weapon_node)
			weapon_node.position = Vector3(0, -0.3, 0.2)
			weapon_node.rotation_degrees = Vector3(-45, 0, 0)
		else:
			character_root.add_child(weapon_node)
			weapon_node.position = Vector3(0.4, 0.6, 0.3)
	else:
		var left_arm = character_root.find_child("LeftArm", true, false)
		if left_arm:
			left_arm.add_child(weapon_node)
			weapon_node.position = Vector3(0, -0.2, 0.2)
			weapon_node.rotation_degrees = Vector3(0, 75, 0)
		else:
			character_root.add_child(weapon_node)
			weapon_node.position = Vector3(-0.45, 0.7, 0.15)
			weapon_node.rotation_degrees = Vector3(0, 75, 0)

# --- PROCEDURAL CHARACTER GENERATOR ---
func _create_procedural_character(class_name_str: String) -> Node3D:
	var root = Node3D.new()
	root.name = class_name_str + "_Model"

	var is_skeleton: bool = class_name_str.begins_with("Skeleton") or class_name_str == "Boss_Warden"
	var body_mat = _material_cache["bone"] if is_skeleton else _material_cache["leather"]
	var cloth_mat = _material_cache["cloth_blue"]

	match class_name_str:
		"Knight": cloth_mat = _material_cache["cloth_blue"]
		"Rogue": cloth_mat = _material_cache["cloth_green"]
		"Mage": cloth_mat = _material_cache["cloth_purple"]
		"Barbarian": cloth_mat = _material_cache["cloth_crimson"]
		"Skeleton_Warrior": cloth_mat = _material_cache["dark_iron"]
		"Skeleton_Rogue": cloth_mat = _material_cache["stone_dark"]
		"Skeleton_Mage": cloth_mat = _material_cache["cloth_purple"]
		"Skeleton_Minion": cloth_mat = _material_cache["bone"]
		"Boss_Warden": cloth_mat = _material_cache["dark_iron"]

	# --- TORSO ---
	var torso_size = Vector3(0.55, 0.65, 0.35)
	if class_name_str == "Barbarian":
		torso_size = Vector3(0.75, 0.70, 0.45)
	elif class_name_str == "Boss_Warden":
		torso_size = Vector3(1.4, 1.6, 0.9)

	var torso = _make_box(torso_size, body_mat if is_skeleton else cloth_mat)
	torso.name = "Torso"
	torso.position.y = 0.9
	if class_name_str == "Boss_Warden":
		torso.position.y = 1.8
	root.add_child(torso)

	# Armor chestplate for Knight / Barbarian / Boss
	if class_name_str in ["Knight", "Skeleton_Warrior", "Boss_Warden"]:
		var plate = _make_box(torso_size * Vector3(1.08, 0.6, 1.15), _material_cache["steel"] if class_name_str == "Knight" else _material_cache["dark_iron"])
		plate.position = torso.position + Vector3(0, 0.1, 0)
		root.add_child(plate)

	# --- HEAD ---
	var head_size = Vector3(0.35, 0.35, 0.35)
	if class_name_str == "Boss_Warden":
		head_size = Vector3(0.7, 0.75, 0.7)

	var head_y = torso.position.y + torso_size.y * 0.5 + head_size.y * 0.5
	var head_mat = _material_cache["bone"] if is_skeleton else (
		_material_cache["steel"] if class_name_str == "Knight" else body_mat
	)
	var head = _make_box(head_size, head_mat)
	head.name = "Head"
	head.position = Vector3(0, head_y, 0)
	root.add_child(head)

	# Helmets, Hats, Horns, Eyes
	if is_skeleton:
		# Glowing eyes
		var eye_glow_mat = _material_cache["glow_fire"] if class_name_str == "Boss_Warden" else _material_cache["glow_cyan"]
		var eye_r = _make_sphere(0.04 if class_name_str != "Boss_Warden" else 0.09, eye_glow_mat)
		eye_r.position = head.position + Vector3(0.08, 0.05, 0.17)
		if class_name_str == "Boss_Warden":
			eye_r.position = head.position + Vector3(0.18, 0.1, 0.35)
		root.add_child(eye_r)

		var eye_l = _make_sphere(0.04 if class_name_str != "Boss_Warden" else 0.09, eye_glow_mat)
		eye_l.position = head.position + Vector3(-0.08, 0.05, 0.17)
		if class_name_str == "Boss_Warden":
			eye_l.position = head.position + Vector3(-0.18, 0.1, 0.35)
		root.add_child(eye_l)

	if class_name_str == "Knight":
		# Visor slit
		var visor = _make_box(Vector3(0.28, 0.06, 0.04), _material_cache["gold"])
		visor.position = head.position + Vector3(0, 0.02, 0.18)
		root.add_child(visor)
		# Plume
		var plume = _make_box(Vector3(0.06, 0.25, 0.3), _material_cache["cloth_crimson"])
		plume.position = head.position + Vector3(0, 0.26, -0.05)
		root.add_child(plume)
	elif class_name_str == "Mage" or class_name_str == "Skeleton_Mage":
		# Pointed Wizard / Lich Hat
		var hat = _make_cone(0.35, 0.6, _material_cache["cloth_purple"])
		hat.position = head.position + Vector3(0, 0.45, 0)
		root.add_child(hat)
	elif class_name_str == "Boss_Warden":
		# Huge Horns
		var horn_r = _make_cone(0.15, 0.8, _material_cache["bone"])
		horn_r.position = head.position + Vector3(0.4, 0.45, 0)
		horn_r.rotation = Vector3(0, 0, -0.5)
		root.add_child(horn_r)

		var horn_l = _make_cone(0.15, 0.8, _material_cache["bone"])
		horn_l.position = head.position + Vector3(-0.4, 0.45, 0)
		horn_l.rotation = Vector3(0, 0, 0.5)
		root.add_child(horn_l)

	# --- LIMBS (Arms & Legs) ---
	var arm_size = Vector3(0.16, 0.55, 0.16)
	var leg_size = Vector3(0.18, 0.6, 0.18)
	if class_name_str == "Boss_Warden":
		arm_size = Vector3(0.35, 1.2, 0.35)
		leg_size = Vector3(0.4, 1.3, 0.4)

	# Left Arm
	var arm_l = _make_box(arm_size, body_mat)
	arm_l.name = "LeftArm"
	arm_l.position = torso.position + Vector3(-torso_size.x * 0.55 - arm_size.x * 0.5, 0, 0)
	root.add_child(arm_l)

	# Right Arm (Weapon Hand)
	var arm_r = _make_box(arm_size, body_mat)
	arm_r.name = "RightArm"
	arm_r.position = torso.position + Vector3(torso_size.x * 0.55 + arm_size.x * 0.5, 0, 0)
	root.add_child(arm_r)

	# Pauldrons
	if class_name_str in ["Knight", "Barbarian", "Skeleton_Warrior", "Boss_Warden"]:
		var pauldron_mat = _material_cache["steel"] if class_name_str == "Knight" else _material_cache["dark_iron"]
		var pauldron_r = _make_box(Vector3(arm_size.x * 1.5, 0.15, arm_size.z * 1.5), pauldron_mat)
		pauldron_r.position = arm_r.position + Vector3(0, arm_size.y * 0.5, 0)
		root.add_child(pauldron_r)

		var pauldron_l = _make_box(Vector3(arm_size.x * 1.5, 0.15, arm_size.z * 1.5), pauldron_mat)
		pauldron_l.position = arm_l.position + Vector3(0, arm_size.y * 0.5, 0)
		root.add_child(pauldron_l)

	# Left Leg
	var leg_l = _make_box(leg_size, body_mat)
	leg_l.name = "LeftLeg"
	leg_l.position = Vector3(-torso_size.x * 0.25, leg_size.y * 0.5, 0)
	root.add_child(leg_l)

	# Right Leg
	var leg_r = _make_box(leg_size, body_mat)
	leg_r.name = "RightLeg"
	leg_r.position = Vector3(torso_size.x * 0.25, leg_size.y * 0.5, 0)
	root.add_child(leg_r)

	return root

# --- PROCEDURAL WEAPON GENERATOR ---
func _create_procedural_weapon(weapon_name: String) -> Node3D:
	var weapon = Node3D.new()
	weapon.name = weapon_name

	match weapon_name:
		"sword_1handed", "Skeleton_Blade":
			var blade_mat = _material_cache["steel"] if weapon_name == "sword_1handed" else _material_cache["dark_iron"]
			# Hilt
			var hilt = _make_cylinder(0.04, 0.25, _material_cache["leather"])
			weapon.add_child(hilt)
			# Crossguard
			var guard = _make_box(Vector3(0.25, 0.04, 0.06), _material_cache["gold"] if weapon_name == "sword_1handed" else _material_cache["bone"])
			guard.position.y = 0.14
			weapon.add_child(guard)
			# Blade
			var blade = _make_box(Vector3(0.09, 0.85, 0.02), blade_mat)
			blade.position.y = 0.58
			weapon.add_child(blade)
			# Glowing edge for skeleton
			if weapon_name == "Skeleton_Blade":
				var glow_strip = _make_box(Vector3(0.02, 0.8, 0.03), _material_cache["glow_cyan"])
				glow_strip.position.y = 0.58
				weapon.add_child(glow_strip)

		"shield_square":
			var shield = _make_box(Vector3(0.55, 0.75, 0.06), _material_cache["wood"])
			var rim = _make_box(Vector3(0.59, 0.79, 0.04), _material_cache["steel"])
			var boss = _make_sphere(0.1, _material_cache["gold"])
			boss.position.z = 0.05
			shield.add_child(rim)
			shield.add_child(boss)
			weapon.add_child(shield)

		"axe_2handed", "Skeleton_Axe":
			# Shaft
			var shaft = _make_cylinder(0.05, 1.2, _material_cache["wood"])
			weapon.add_child(shaft)
			# Double Axe Heads
			var axe_mat = _material_cache["steel"] if weapon_name == "axe_2handed" else _material_cache["dark_iron"]
			var head_1 = _make_box(Vector3(0.35, 0.25, 0.04), axe_mat)
			head_1.position = Vector3(0.2, 0.45, 0)
			weapon.add_child(head_1)
			var head_2 = _make_box(Vector3(0.35, 0.25, 0.04), axe_mat)
			head_2.position = Vector3(-0.2, 0.45, 0)
			weapon.add_child(head_2)

		"staff", "Skeleton_Staff":
			var staff_wood = _make_cylinder(0.04, 1.4, _material_cache["wood"])
			weapon.add_child(staff_wood)
			# Head Crystal
			var crystal = _make_sphere(0.12, _material_cache["glow_cyan"] if weapon_name == "staff" else _material_cache["glow_fire"])
			crystal.position.y = 0.75
			weapon.add_child(crystal)

		"dagger":
			var hilt = _make_cylinder(0.03, 0.15, _material_cache["leather"])
			weapon.add_child(hilt)
			var guard = _make_box(Vector3(0.12, 0.02, 0.03), _material_cache["gold"])
			guard.position.y = 0.08
			weapon.add_child(guard)
			var blade = _make_box(Vector3(0.05, 0.4, 0.015), _material_cache["steel"])
			blade.position.y = 0.28
			weapon.add_child(blade)

		_:
			var default_mesh = _make_box(Vector3(0.1, 0.7, 0.1), _material_cache["steel"])
			weapon.add_child(default_mesh)

	return weapon

# --- PROCEDURAL DUNGEON TILE GENERATOR ---
func _create_procedural_dungeon_tile(tile_name: String) -> Node3D:
	var tile = Node3D.new()
	tile.name = tile_name

	match tile_name:
		"floor_tile_large":
			# 4x4m modular floor plate with stone flags
			var base_floor = _make_box(Vector3(4.0, 0.3, 4.0), _material_cache["stone_dark"])
			base_floor.position.y = -0.15
			tile.add_child(base_floor)
			# Flagstone pattern grooves
			for x in [-1.0, 1.0]:
				for z in [-1.0, 1.0]:
					var slab = _make_box(Vector3(1.85, 0.04, 1.85), _material_cache["stone"])
					slab.position = Vector3(x, 0.02, z)
					tile.add_child(slab)

		"wall":
			# 4m long, 3.5m high, 0.6m thick stone wall with base & top cornice
			var wall_body = _make_box(Vector3(4.0, 3.5, 0.6), _material_cache["stone_dark"])
			wall_body.position.y = 1.75
			tile.add_child(wall_body)

			var base_trim = _make_box(Vector3(4.1, 0.4, 0.8), _material_cache["stone"])
			base_trim.position.y = 0.2
			tile.add_child(base_trim)

			var top_cornice = _make_box(Vector3(4.15, 0.3, 0.85), _material_cache["stone"])
			top_cornice.position.y = 3.4
			tile.add_child(top_cornice)

		"wall_doorway":
			# Wall with arched opening in center
			var left_pillar = _make_box(Vector3(1.1, 3.5, 0.6), _material_cache["stone_dark"])
			left_pillar.position = Vector3(-1.45, 1.75, 0)
			tile.add_child(left_pillar)

			var right_pillar = _make_box(Vector3(1.1, 3.5, 0.6), _material_cache["stone_dark"])
			right_pillar.position = Vector3(1.45, 1.75, 0)
			tile.add_child(right_pillar)

			var lintel = _make_box(Vector3(1.9, 0.8, 0.65), _material_cache["stone"])
			lintel.position = Vector3(0, 3.1, 0)
			tile.add_child(lintel)

		"pillar":
			# Fluted stone column
			var plinth = _make_box(Vector3(1.2, 0.5, 1.2), _material_cache["stone"])
			plinth.position.y = 0.25
			tile.add_child(plinth)

			var shaft = _make_cylinder(0.4, 3.0, _material_cache["stone_dark"])
			shaft.position.y = 1.8
			tile.add_child(shaft)

			var capital = _make_box(Vector3(1.1, 0.4, 1.1), _material_cache["stone"])
			capital.position.y = 3.4
			tile.add_child(capital)

		"torch_lit":
			# Iron sconce
			var bracket = _make_box(Vector3(0.1, 0.4, 0.3), _material_cache["dark_iron"])
			bracket.position = Vector3(0, 1.8, 0.15)
			tile.add_child(bracket)

			var torch_wood = _make_cylinder(0.04, 0.35, _material_cache["wood"])
			torch_wood.position = Vector3(0, 1.9, 0.28)
			tile.add_child(torch_wood)

			var flame = _make_sphere(0.12, _material_cache["glow_fire"])
			flame.position = Vector3(0, 2.1, 0.28)
			tile.add_child(flame)

			var light = OmniLight3D.new()
			light.name = "TorchLight"
			light.light_color = Color(1.0, 0.6, 0.2)
			light.light_energy = 1.8
			light.omni_range = 8.5
			light.omni_attenuation = 1.2
			light.position = flame.position
			light.shadow_enabled = true
			tile.add_child(light)

		"chest_gold":
			# Base chest
			var base = _make_box(Vector3(0.9, 0.5, 0.6), _material_cache["wood"])
			base.position.y = 0.25
			tile.add_child(base)

			var straps = _make_box(Vector3(0.92, 0.52, 0.15), _material_cache["gold"])
			straps.position.y = 0.25
			tile.add_child(straps)

			# Hinged Lid
			var lid_pivot = Node3D.new()
			lid_pivot.name = "LidPivot"
			lid_pivot.position = Vector3(0, 0.5, -0.3)
			tile.add_child(lid_pivot)

			var lid = _make_box(Vector3(0.92, 0.18, 0.62), _material_cache["wood"])
			lid.position = Vector3(0, 0.09, 0.3)
			lid_pivot.add_child(lid)

			var lid_gold = _make_box(Vector3(0.94, 0.2, 0.16), _material_cache["gold"])
			lid_gold.position = Vector3(0, 0.09, 0.3)
			lid_pivot.add_child(lid_gold)

		"barrel_small":
			var barrel = _make_cylinder(0.35, 0.8, _material_cache["wood"])
			barrel.position.y = 0.4
			tile.add_child(barrel)

			var band_1 = _make_cylinder(0.37, 0.08, _material_cache["dark_iron"])
			band_1.position.y = 0.6
			tile.add_child(band_1)

			var band_2 = _make_cylinder(0.37, 0.08, _material_cache["dark_iron"])
			band_2.position.y = 0.2
			tile.add_child(band_2)

		"floor_spikes":
			# Iron grate plate
			var plate = _make_box(Vector3(1.8, 0.08, 1.8), _material_cache["dark_iron"])
			plate.position.y = 0.04
			tile.add_child(plate)

			var spike_container = Node3D.new()
			spike_container.name = "Spikes"
			tile.add_child(spike_container)

			# 9 spikes in 3x3 layout
			for x in [-0.5, 0.0, 0.5]:
				for z in [-0.5, 0.0, 0.5]:
					var spike = _make_cone(0.08, 0.65, _material_cache["steel"])
					spike.position = Vector3(x, 0.32, z)
					spike_container.add_child(spike)

		_:
			var box = _make_box(Vector3(1, 1, 1), _material_cache["stone"])
			box.position.y = 0.5
			tile.add_child(box)

	return tile

# --- HELPER MESH CREATORS ---
func _make_box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	return mi

func _make_cylinder(radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 12
	mi.mesh = cyl
	mi.material_override = mat
	return mi

func _make_sphere(radius: float, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = 12
	sph.rings = 6
	mi.mesh = sph
	mi.material_override = mat
	return mi

func _make_cone(bottom_radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.0
	cyl.bottom_radius = bottom_radius
	cyl.height = height
	cyl.radial_segments = 12
	mi.mesh = cyl
	mi.material_override = mat
	return mi

func _create_procedural_prop(subtype: String, path: String) -> Node3D:
	var root = Node3D.new()
	var lower_p = (subtype + " " + path).to_lower()
	
	if "fireplace" in lower_p or "hearth" in lower_p:
		# Stone Fireplace with mantle and glowing hearth
		var base = _make_box(Vector3(1.6, 0.25, 0.9), _material_cache["stone_dark"])
		base.position.y = 0.125
		root.add_child(base)
		
		var left_col = _make_box(Vector3(0.3, 1.4, 0.8), _material_cache["stone"])
		left_col.position = Vector3(-0.65, 0.85, 0)
		root.add_child(left_col)
		
		var right_col = _make_box(Vector3(0.3, 1.4, 0.8), _material_cache["stone"])
		right_col.position = Vector3(0.65, 0.85, 0)
		root.add_child(right_col)
		
		var mantle = _make_box(Vector3(1.8, 0.3, 1.0), _material_cache["wood"])
		mantle.position = Vector3(0, 1.65, 0)
		root.add_child(mantle)
		
		var back_wall = _make_box(Vector3(1.2, 1.4, 0.2), _material_cache["dark_iron"])
		back_wall.position = Vector3(0, 0.85, -0.3)
		root.add_child(back_wall)
		
		# Glowing Fire Coals
		var fire_mat = StandardMaterial3D.new()
		fire_mat.albedo_color = Color(1.0, 0.35, 0.1)
		fire_mat.emission_enabled = true
		fire_mat.emission = Color(1.0, 0.45, 0.1)
		fire_mat.emission_energy_multiplier = 3.0
		var coals = _make_box(Vector3(0.7, 0.2, 0.4), fire_mat)
		coals.position = Vector3(0, 0.3, -0.05)
		root.add_child(coals)
		
		var light = OmniLight3D.new()
		light.light_color = Color(1.0, 0.55, 0.2)
		light.light_energy = 1.8
		light.omni_range = 6.0
		light.position = Vector3(0, 0.6, 0.2)
		root.add_child(light)
		return root

	elif "anvil" in lower_p:
		# Wooden stump base
		var stump = _make_cylinder(0.42, 0.65, _material_cache["wood"])
		stump.position.y = 0.325
		root.add_child(stump)
		
		# Dark Iron Anvil (waist and face)
		var anvil_waist = _make_cylinder(0.18, 0.25, _material_cache["dark_iron"])
		anvil_waist.position.y = 0.75
		root.add_child(anvil_waist)
		
		var anvil_face = _make_box(Vector3(0.75, 0.2, 0.3), _material_cache["dark_iron"])
		anvil_face.position = Vector3(-0.05, 0.95, 0)
		root.add_child(anvil_face)
		
		# Anvil Horn (conical tip)
		var horn = _make_cone(0.12, 0.35, _material_cache["dark_iron"])
		horn.position = Vector3(0.42, 0.95, 0)
		horn.rotation = Vector3(0, 0, -PI * 0.5)
		root.add_child(horn)
		return root

	elif "ingot" in lower_p:
		# Pyramid Stack of Refined Ingots
		for layer in range(3):
			var count = 3 - layer
			for i in range(count):
				var mat = _material_cache["gold"] if (layer + i) % 2 == 0 else _material_cache["steel"]
				var ingot = _make_box(Vector3(0.35, 0.12, 0.18), mat)
				ingot.position = Vector3((i - float(count - 1) * 0.5) * 0.38, 0.06 + layer * 0.12, 0)
				root.add_child(ingot)
		return root

	# Default styled prop (carved stone / wood box)
	var default_box = _make_box(Vector3(1, 1, 1), _material_cache["stone"])
	default_box.position.y = 0.5
	root.add_child(default_box)
	return root
