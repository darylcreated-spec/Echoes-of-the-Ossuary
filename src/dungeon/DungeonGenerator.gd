extends Node3D
class_name DungeonGenerator

const RoomControllerScript = preload("res://src/dungeon/RoomController.gd")
const SpikeTrapScript = preload("res://src/dungeon/SpikeTrap.gd")
const TownNPCScript = preload("res://src/actors/TownNPC.gd")
const QuestMaterialNodeScript = preload("res://src/world/QuestMaterialNode.gd")
const AnimalAIScript = preload("res://src/actors/AnimalAI.gd")

# KayKit Dungeon strict 2.0m tile footprint
const TILE_SIZE: float = 2.0

# 2D Grid Cell Constants
const CELL_VOID: int = 0
const CELL_FLOOR: int = 1
const CELL_WALL: int = 2
const CELL_PILLAR: int = 3
const CELL_TORCH_WALL: int = 4
const CELL_SPIKE_TRAP: int = 5
const CELL_ENEMY_SPAWN: int = 6
const CELL_EXIT_DOOR: int = 7

func build_floor_room(floor_num: int) -> Node3D:
	for child in get_children():
		remove_child(child)
		child.queue_free()
		
	var room_ctrl = RoomControllerScript.new()
	room_ctrl.name = "RoomController"
	
	if floor_num == 0:
		room_ctrl.is_hub_room = true
		add_child(room_ctrl)
		_build_overworld_sanctuary(room_ctrl)
		return room_ctrl
	elif floor_num >= 5:
		room_ctrl.is_boss_room = true
		add_child(room_ctrl)
		var matrix = _generate_boss_matrix()
		_instantiate_matrix(room_ctrl, matrix)
	else:
		room_ctrl.is_hub_room = false
		add_child(room_ctrl)
		var matrix = _generate_chamber_matrix(floor_num)
		_instantiate_matrix(room_ctrl, matrix)
		
	return room_ctrl

func _generate_hub_matrix() -> Array:
	# 11x11 Grid Matrix (22m x 22m)
	var w = 11
	var h = 11
	var grid: Array = []
	for z in range(h):
		var row: Array = []
		for x in range(w):
			if x == 0 or x == w - 1 or z == 0 or z == h - 1:
				if (x == 5 and z == 0) or (z == 5 and (x == 0 or x == w - 1)):
					row.append(CELL_TORCH_WALL)
				else:
					row.append(CELL_WALL)
			elif (x == 2 or x == w - 3) and (z == 2 or z == h - 3):
				row.append(CELL_PILLAR)
			else:
				row.append(CELL_FLOOR)
		grid.append(row)
	return grid

func _generate_chamber_matrix(_floor_num: int) -> Array:
	# 11x11 Grid Matrix for Combat Chambers
	var w = 11
	var h = 11
	var grid: Array = []
	for z in range(h):
		var row: Array = []
		for x in range(w):
			if x == 0 or x == w - 1 or z == 0 or z == h - 1:
				if (x == 5 and (z == 0 or z == h - 1)) or (z == 5 and (x == 0 or x == w - 1)):
					row.append(CELL_TORCH_WALL)
				else:
					row.append(CELL_WALL)
			elif (x == 2 or x == w - 3) and (z == 2 or z == h - 3):
				row.append(CELL_PILLAR)
			elif (x == 3 or x == w - 4) and (z == 3 or z == h - 4):
				row.append(CELL_SPIKE_TRAP)
			elif (x == 5 and (z == 2 or z == h - 3)) or (z == 5 and (x == 2 or x == w - 3)):
				row.append(CELL_ENEMY_SPAWN)
			else:
				row.append(CELL_FLOOR)
		grid.append(row)
	return grid

func _generate_boss_matrix() -> Array:
	# 15x15 Grand Boss Arena
	var w = 15
	var h = 15
	var grid: Array = []
	for z in range(h):
		var row: Array = []
		for x in range(w):
			if x == 0 or x == w - 1 or z == 0 or z == h - 1:
				if (x % 4 == 0) or (z % 4 == 0):
					row.append(CELL_TORCH_WALL)
				else:
					row.append(CELL_WALL)
			elif (x == 3 or x == w - 4) and (z == 3 or z == h - 4):
				row.append(CELL_PILLAR)
			elif (x == 5 or x == w - 6) and (z == 5 or z == h - 6):
				row.append(CELL_PILLAR)
			else:
				row.append(CELL_FLOOR)
		grid.append(row)
	return grid

func _instantiate_matrix(parent: Node3D, grid: Array) -> void:
	var rows = grid.size()
	var cols = grid[0].size()
	var offset_x = float(cols - 1) * TILE_SIZE * 0.5
	var offset_z = float(rows - 1) * TILE_SIZE * 0.5
	
	# Floor static collision body with safety perimeter padding
	var floor_body = StaticBody3D.new()
	floor_body.collision_layer = 1
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(float(cols) * TILE_SIZE + 6.0, 1.2, float(rows) * TILE_SIZE + 6.0)
	col_shape.shape = box
	col_shape.position.y = -0.6
	floor_body.add_child(col_shape)
	parent.add_child(floor_body)
	
	# Collect enemy spawn points for the room controller
	var spawns: Array[Vector3] = []
	
	for z in range(rows):
		for x in range(cols):
			var cell = grid[z][x]
			var pos = Vector3(x * TILE_SIZE - offset_x, 0, z * TILE_SIZE - offset_z)
			
			if cell == CELL_VOID:
				continue
				
			# Base Floor under all active cells
			var floor_tile = AssetLoader.load_or_generate_model("res://assets/dungeon/floor_tile_large.glb", "dungeon", "floor_tile_large")
			floor_tile.scale = Vector3(0.5, 1.0, 0.5) # Scale 4m base model to 2m
			floor_tile.position = pos
			parent.add_child(floor_tile)
			
			match cell:
				CELL_WALL, CELL_TORCH_WALL:
					var wall = AssetLoader.load_or_generate_model("res://assets/dungeon/wall.glb", "dungeon", "wall")
					wall.scale = Vector3(0.5, 1.0, 1.0)
					wall.position = pos
					parent.add_child(wall)
					
					# Wall physics
					var w_body = StaticBody3D.new()
					w_body.collision_layer = 1
					var w_col = CollisionShape3D.new()
					var w_box = BoxShape3D.new()
					w_box.size = Vector3(TILE_SIZE, 4.0, 0.8)
					w_col.shape = w_box
					w_col.position.y = 2.0
					w_body.add_child(w_col)
					wall.add_child(w_body)
					
					if cell == CELL_TORCH_WALL:
						_attach_torch_sconce(parent, pos)

				CELL_PILLAR:
					var pillar = AssetLoader.load_or_generate_model("res://assets/dungeon/pillar.glb", "dungeon", "pillar")
					pillar.position = pos
					parent.add_child(pillar)
					
					var p_body = StaticBody3D.new()
					p_body.collision_layer = 1
					var p_col = CollisionShape3D.new()
					var p_cyl = CylinderShape3D.new()
					p_cyl.radius = 0.5
					p_cyl.height = 3.5
					p_col.shape = p_cyl
					p_col.position.y = 1.75
					p_body.add_child(p_col)
					pillar.add_child(p_body)

				CELL_SPIKE_TRAP:
					var trap = SpikeTrapScript.new()
					trap.position = pos
					parent.add_child(trap)

				CELL_ENEMY_SPAWN:
					spawns.append(pos)
					
	if spawns.size() > 0:
		parent.enemy_spawn_points = spawns
		
	# Unbreakable perimeter barrier walls
	_build_perimeter_barrier(parent, cols, rows)

func _build_perimeter_barrier(parent: Node3D, cols: int, rows: int) -> void:
	var barrier_body = StaticBody3D.new()
	barrier_body.name = "PerimeterBarriers"
	barrier_body.collision_layer = 1 # Environment
	parent.add_child(barrier_body)
	
	var total_w = float(cols) * TILE_SIZE
	var total_d = float(rows) * TILE_SIZE
	var half_w = total_w * 0.5
	var half_d = total_d * 0.5
	var wall_height = 8.0
	var wall_thick = 2.0
	
	# North Barrier
	var n_col = CollisionShape3D.new()
	var n_box = BoxShape3D.new()
	n_box.size = Vector3(total_w + 8.0, wall_height, wall_thick)
	n_col.shape = n_box
	n_col.position = Vector3(0, wall_height * 0.5, -half_d - wall_thick * 0.5 + TILE_SIZE * 0.5)
	barrier_body.add_child(n_col)
	
	# South Barrier
	var s_col = CollisionShape3D.new()
	var s_box = BoxShape3D.new()
	s_box.size = Vector3(total_w + 8.0, wall_height, wall_thick)
	s_col.shape = s_box
	s_col.position = Vector3(0, wall_height * 0.5, half_d + wall_thick * 0.5 - TILE_SIZE * 0.5)
	barrier_body.add_child(s_col)
	
	# West Barrier
	var w_col = CollisionShape3D.new()
	var w_box = BoxShape3D.new()
	w_box.size = Vector3(wall_thick, wall_height, total_d + 8.0)
	w_col.shape = w_box
	w_col.position = Vector3(-half_w - wall_thick * 0.5 + TILE_SIZE * 0.5, wall_height * 0.5, 0)
	barrier_body.add_child(w_col)
	
	# East Barrier
	var e_col = CollisionShape3D.new()
	var e_box = BoxShape3D.new()
	e_box.size = Vector3(wall_thick, wall_height, total_d + 8.0)
	e_col.shape = e_box
	e_col.position = Vector3(half_w + wall_thick * 0.5 - TILE_SIZE * 0.5, wall_height * 0.5, 0)
	barrier_body.add_child(e_col)

func _attach_torch_sconce(parent: Node3D, pos: Vector3) -> void:
	var torch = AssetLoader.load_or_generate_model("res://assets/dungeon/torch_lit.glb", "dungeon", "torch_lit")
	torch.position = pos
	parent.add_child(torch)
	
	# Sinusoidal noise torch light
	var light = torch.find_child("TorchLight", true, false)
	if not light:
		light = OmniLight3D.new()
		light.name = "TorchLight"
		light.position = Vector3(0, 2.0, 0.3)
		torch.add_child(light)
		
	light.light_color = Color(1.0, 0.55, 0.23) # Warm #ff8c3b
	light.omni_range = 9.0
	light.shadow_enabled = true
	
	# Add flicker script
	var flicker = Node.new()
	flicker.set_script(_create_torch_flicker_script())
	light.add_child(flicker)

func _create_torch_flicker_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """extends Node
var _time: float = 0.0
@onready var parent_light: OmniLight3D = get_parent() as OmniLight3D
func _ready():
	_time = randf_range(0.0, 100.0)
func _process(delta: float):
	if parent_light:
		_time += delta
		var noise = sin(_time * 12.0) * 0.18 + sin(_time * 23.5) * 0.1 + sin(_time * 41.2) * 0.06
		parent_light.light_energy = 1.8 + noise
"""
	s.reload()
	return s

# --- SURFACE OVERWORLD SANCTUARY HUB & OPEN WORLD REALM ---
func _build_overworld_sanctuary(parent: Node3D) -> void:
	var ground_size = 110.0
	var half_s = ground_size * 0.5
	
	# 1. Floor Static Collision & Safety Void Safeguard (Full 124m x 124m realm)
	var floor_body = StaticBody3D.new()
	floor_body.collision_layer = 1
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(ground_size + 14.0, 1.2, ground_size + 14.0)
	col_shape.shape = box
	col_shape.position.y = -0.6
	floor_body.add_child(col_shape)
	parent.add_child(floor_body)
	
	# Visual Overworld Continuous Grass Landscape (Full seamless meadow base)
	var ground_mesh_inst = MeshInstance3D.new()
	ground_mesh_inst.name = "OverworldGroundVisual"
	var p_mesh = PlaneMesh.new()
	p_mesh.size = Vector2(ground_size + 14.0, ground_size + 14.0)
	ground_mesh_inst.mesh = p_mesh
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.24, 0.44, 0.18) # Lush stylized medieval grass
	g_mat.roughness = 0.88
	ground_mesh_inst.material_override = g_mat
	ground_mesh_inst.position.y = 0.0
	parent.add_child(ground_mesh_inst)
	
	# Outer world perimeter boundary collision barriers (North, South, East, West at +-55m)
	var wall_h = 16.0
	var thick = 3.0
	_add_static_box(parent, Vector3(0, wall_h * 0.5, -half_s - thick * 0.5), Vector3(ground_size + thick * 2, wall_h, thick))
	_add_static_box(parent, Vector3(0, wall_h * 0.5, half_s + thick * 0.5), Vector3(ground_size + thick * 2, wall_h, thick))
	_add_static_box(parent, Vector3(half_s + thick * 0.5, wall_h * 0.5, 0), Vector3(thick, wall_h, ground_size))
	_add_static_box(parent, Vector3(-half_s - thick * 0.5, wall_h * 0.5, 0), Vector3(thick, wall_h, ground_size))

	# Encircling Natural Perimeter Mountain Ridges & Trees (prevents open voids)
	for perim_idx in range(-5, 6):
		var offset_p = float(perim_idx) * 10.0
		# North Ridge
		_place_prop(parent, "res://assets/overworld/mountain_A.gltf", Vector3(offset_p, 0.0, -half_s), Vector3.ONE * 8.0)
		# South Ridge (citadel backdrop)
		if abs(offset_p) > 16.0:
			_place_prop(parent, "res://assets/overworld/mountain_B_grass_trees.gltf", Vector3(offset_p, 0.0, half_s), Vector3.ONE * 8.0)
		# East Ridge (mountain crags)
		_place_prop(parent, "res://assets/overworld/mountain_A.gltf", Vector3(half_s, 0.0, offset_p), Vector3.ONE * 8.0)
		# West Ridge (forest peaks)
		_place_prop(parent, "res://assets/overworld/mountain_B_grass_trees.gltf", Vector3(-half_s, 0.0, offset_p), Vector3.ONE * 8.0)

	# 2. Central Cobblestone Plaza (Courtyard floor for hero pedestals)
	for px in range(-5, 6):
		for pz in range(-4, 6):
			var stone = AssetLoader.load_or_generate_model("res://assets/dungeon/floor_tile_large.glb", "dungeon", "floor_tile_large")
			stone.scale = Vector3(0.5, 1.0, 0.5)
			stone.position = Vector3(px * 2.0, 0.02, pz * 2.0)
			parent.add_child(stone)

	# 3. North: The Ancient Crypt (Grand stone mausoleum entrance to catacombs)
	var crypt = AssetLoader.load_or_generate_model("res://assets/overworld/crypt.gltf", "dungeon", "crypt")
	crypt.scale = Vector3(2.8, 2.8, 2.8)
	crypt.position = Vector3(0, 0, -14.0)
	parent.add_child(crypt)
	_add_static_box(parent, Vector3(0, 3.2, -14.5), Vector3(8.5, 6.5, 7.5))
	
	# Dead cemetery trees and gravestones
	_place_prop(parent, "res://assets/overworld/tree_dead_large.gltf", Vector3(-6.5, 0, -12.5), Vector3.ONE * 2.2)
	_place_prop(parent, "res://assets/overworld/tree_dead_large.gltf", Vector3(6.5, 0, -12.5), Vector3.ONE * 2.2, 75.0)
	_place_prop(parent, "res://assets/overworld/grave_A.gltf", Vector3(-4.5, 0, -10.5), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/gravestone.gltf", Vector3(4.5, 0, -10.5), Vector3.ONE * 1.8, -25.0)
	_place_prop(parent, "res://assets/overworld/grave_A_destroyed.gltf", Vector3(-6.2, 0, -9.8), Vector3.ONE * 1.6)

	# 4. West: The Blacksmith's Forge (Proportionate 7.1m tall shop)
	var smith = AssetLoader.load_or_generate_model("res://assets/overworld/building_blacksmith_blue.gltf", "dungeon", "blacksmith")
	smith.scale = Vector3.ONE * 7.2
	smith.position = Vector3(-15.0, 0, 0.0)
	smith.rotation_degrees.y = 90.0
	parent.add_child(smith)
	_add_static_box(parent, Vector3(-15.0, 3.5, 0.0), Vector3(9.2, 7.0, 9.0))
	AmbientFX.create_chimney_smoke(parent, Vector3(-15.0, 7.2, -1.2))

	# Circling Crows Flock above North Crypt
	var flock_crypt = CirclingFlock.new()
	flock_crypt.position = Vector3(0.0, 16.0, -14.0)
	flock_crypt.bird_count = 6
	flock_crypt.circle_radius = 9.0
	parent.add_child(flock_crypt)

	# Master Torval - Town Blacksmith NPC (Stout Dwarf proportions ~1.44m tall)
	var torval = TownNPCScript.new()
	torval.npc_id = "blacksmith"
	torval.npc_name = "Master Torval"
	torval.npc_title = "Forge Master"
	torval.icon = "⚒️"
	torval.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	torval.model_scale = Vector3(0.38, 0.38, 0.38)
	torval.model_rotation_y = 90.0
	torval.dialogue_text = "Hail, warrior! The forge fires blaze with eternal embers. Deliver unto me the Soul Echoes reaped from the Ossuary depths, and I shall temper your weapons, bolster your armor, and sharpen your dash reflexes!"
	torval.position = Vector3(-9.5, 0, 0.0)
	parent.add_child(torval)

	# Blacksmith forge props
	_place_prop(parent, "res://assets/furniture/fireplace.gltf", Vector3(-11.5, 0, -2.8), Vector3.ONE * 2.0, 90.0)
	_place_prop(parent, "res://assets/furniture/table_medium.gltf", Vector3(-9.5, 0, -2.5), Vector3.ONE * 1.5, 0.0)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-8.5, 0, -2.5), Vector3.ONE * 1.5)

	# 5. East: The Ruined Cathedral (Towering 15.7m cathedral)
	var church = AssetLoader.load_or_generate_model("res://assets/overworld/building_church_blue.gltf", "dungeon", "church")
	church.scale = Vector3.ONE * 9.5
	church.position = Vector3(16.0, 0, 0.0)
	church.rotation_degrees.y = -90.0
	parent.add_child(church)
	_add_static_box(parent, Vector3(16.0, 6.0, 0.0), Vector3(9.8, 12.0, 11.0))
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(8.5, 0, 3.0), Vector3.ONE * 2.0, -45.0)

	# Eldress Alyssa - High Priestess NPC (Proportionate ~1.78m human height)
	var alyssa = TownNPCScript.new()
	alyssa.npc_id = "priestess"
	alyssa.npc_name = "Eldress Alyssa"
	alyssa.npc_title = "Sanctuary Priestess"
	alyssa.icon = "✨"
	alyssa.model_path = "res://assets/characters/adventurers/Mage.glb"
	alyssa.model_scale = Vector3(0.53, 0.53, 0.53)
	alyssa.model_rotation_y = -90.0
	alyssa.dialogue_text = "May the Sacred Light guide your steps, champion. The dead stir restlessly in the Catacombs below. Inquire upon our Sanctuary Bounties—purge the wicked hordes to claim divine favour and rich reward!"
	alyssa.position = Vector3(9.5, 0, 0.0)
	parent.add_child(alyssa)

	# Cathedral props
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(8.5, 0, -3.0), Vector3.ONE * 2.0, -45.0)
	_place_prop(parent, "res://assets/furniture/cabinet_small_decorated.gltf", Vector3(11.5, 0, -3.2), Vector3.ONE * 1.8, -90.0)

	# 6. South: Fortified Arch Gateway (6.6m tall gateway)
	var gate = AssetLoader.load_or_generate_model("res://assets/overworld/arch_gate.gltf", "dungeon", "arch_gate")
	gate.scale = Vector3.ONE * 1.6
	gate.position = Vector3(0, 0, 14.0)
	parent.add_child(gate)
	_add_static_box(parent, Vector3(-3.4, 3.0, 14.0), Vector3(2.0, 6.0, 2.0))
	_add_static_box(parent, Vector3(3.4, 3.0, 14.0), Vector3(2.0, 6.0, 2.0))

	# Captain Vane - Gate Sentinel NPC (Proportionate ~1.89m knight)
	var vane = TownNPCScript.new()
	vane.npc_id = "guard"
	vane.npc_name = "Captain Vane"
	vane.npc_title = "Gate Sentinel"
	vane.icon = "🛡️"
	vane.model_path = "res://assets/characters/adventurers/Knight.glb"
	vane.model_scale = Vector3(0.55, 0.55, 0.55)
	vane.model_rotation_y = 180.0
	vane.dialogue_text = "Halt, warrior! You stand before the threshold of the Ossuary Catacombs. Beneath the north crypt lies the descent sigil. Step upon the glowing seal to plunge into the underworld. Beware the Bone Titan's wrath on the final floor!"
	vane.position = Vector3(0, 0, 11.5)
	parent.add_child(vane)

	# Fortified Town Walls flanking the South Arch Gateway
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-7.5, 0, 14.0), Vector3(3.5, 4.0, 2.5))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(7.5, 0, 14.0), Vector3(3.5, 4.0, 2.5))
	_add_static_box(parent, Vector3(-8.0, 3.0, 14.0), Vector3(7.0, 6.0, 2.5))
	_add_static_box(parent, Vector3(8.0, 3.0, 14.0), Vector3(7.0, 6.0, 2.5))

	# Courtyard Perimeter Trees (Scaled 2.8x - 3.4x -> 9m - 12m tall trees)
	var border_trees = [
		Vector3(-12.0, 0, -12.0), Vector3(-8.5, 0, -12.5), Vector3(8.5, 0, -12.5), Vector3(12.0, 0, -12.0),
		Vector3(-14.5, 0, -7.0), Vector3(-14.5, 0, 7.0), Vector3(14.5, 0, -7.0), Vector3(14.5, 0, 7.0)
	]
	var tree_paths = [
		"res://assets/overworld/tree_pine_orange_large.gltf",
		"res://assets/overworld/tree_single_A.gltf",
		"res://assets/overworld/trees_A_large.gltf",
		"res://assets/overworld/tree_pine_yellow_large.gltf"
	]
	for i in range(border_trees.size()):
		var t_pos = border_trees[i]
		var model_p = tree_paths[i % tree_paths.size()]
		_place_prop(parent, model_p, t_pos, Vector3.ONE * 3.0, float((i * 47) % 360))
		_add_static_cyl(parent, t_pos, 1.0, 7.0)

	# Decorative Courtyard Props
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-2.8, 0, 12.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-2.1, 0, 12.5), Vector3.ONE * 1.1)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(2.8, 0, 12.0), Vector3.ONE * 1.3)

	# 7. EXPANDED OPEN WORLD MEDIEVAL REALM
	_build_road_network(parent)
	_build_town_quarter(parent)
	_build_river_and_bridges(parent)
	_build_farmlands_hamlet(parent)
	_build_castle_citadel(parent)
	_build_blackwood_forest(parent)
	_build_iron_mountains(parent)
	_build_forgotten_ruins(parent)

func _build_road_network(parent: Node3D) -> void:
	# Main Highway: Sanctuary South Gate (Z=14) -> Stone Bridge (Z=24) -> Castle Keep (Z=44)
	for z_step in range(14, 45, 2):
		if z_step >= 20 and z_step <= 27:
			continue # Handled by the Stone Bridge
		for rx in range(-1, 2):
			_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(float(rx) * 1.9, 0.02, float(z_step)), Vector3(1.1, 1.0, 1.1))
		
	# East Village Road: leaves Main Highway north of the river at Z = 16.5
	for step in range(1, 14):
		var x_pos = float(step) * 1.9
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(x_pos, 0.02, 16.5), Vector3(1.1, 1.0, 1.1))
		
	# West Town Market Road: leads to Tavern (X = -10) and Market (X = -18)
	for step in range(1, 11):
		var x_pos = -float(step) * 1.9
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(x_pos, 0.02, 16.5), Vector3(1.1, 1.0, 1.1))

	# South-East Pasture & Windmill Path: leaves Stone Bridge at Z = 28.0 towards Pasture Gate (X = 23, Z = 37)
	for step in range(1, 11):
		var p_x = float(step) * 2.1
		var p_z = 28.0 + float(step) * 0.9
		_place_prop(parent, "res://assets/overworld/path_A.gltf", Vector3(p_x, 0.02, p_z), Vector3(1.1, 1.0, 1.1))

	# Mountain Trail: North-East from Cathedral into High Crags
	var mtn_path = [
		Vector3(14.0, 0.02, -4.0), Vector3(18.0, 0.02, -8.0), Vector3(22.0, 0.02, -12.0),
		Vector3(26.0, 0.02, -16.0), Vector3(30.0, 0.02, -20.0), Vector3(34.0, 0.02, -22.0)
	]
	for p in mtn_path:
		_place_prop(parent, "res://assets/overworld/floor_dirt.gltf", p, Vector3(2.0, 1.0, 2.0))

	# Ancient Path: North-West from Blacksmith into Forgotten Ruins
	var ruins_path = [
		Vector3(-14.0, 0.02, -3.0), Vector3(-18.0, 0.02, -5.0), Vector3(-22.0, 0.02, -6.0),
		Vector3(-26.0, 0.02, -6.0), Vector3(-30.0, 0.02, -5.0), Vector3(-34.0, 0.02, -4.0)
	]
	for p in ruins_path:
		_place_prop(parent, "res://assets/overworld/floor_dirt.gltf", p, Vector3(2.0, 1.0, 2.0))

func _build_town_quarter(parent: Node3D) -> void:
	# 1. The Boar's Tusk Tavern (West of South Highway: X = -10.0, Z = 17.5)
	var tavern = _place_prop(parent, "res://assets/overworld/building_tavern_blue.gltf", Vector3(-10.0, 0.0, 17.5), Vector3.ONE * 6.5, 45.0)
	_add_static_box(parent, Vector3(-10.0, 4.5, 17.5), Vector3(7.5, 9.0, 8.5))
	AmbientFX.create_chimney_smoke(parent, Vector3(-10.0, 8.5, 16.5))
	
	# Tavern Patio: Outdoor tables, stools, and ale barrels
	_place_prop(parent, "res://assets/furniture/table_medium.gltf", Vector3(-6.5, 0.0, 17.5), Vector3.ONE * 1.6, 90.0)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-6.5, 0.0, 16.4), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-6.5, 0.0, 18.6), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-8.2, 0.0, 19.5), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-7.5, 0.0, 19.8), Vector3.ONE * 1.1)

	# NPC: Barnaby the Barkeep
	var barkeep = TownNPCScript.new()
	barkeep.npc_id = "barkeep"
	barkeep.npc_name = "Barnaby"
	barkeep.npc_title = "Tavern Keeper"
	barkeep.icon = "🍺"
	barkeep.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	barkeep.model_scale = Vector3(0.52, 0.52, 0.52)
	barkeep.model_rotation_y = 120.0
	barkeep.dialogue_text = "Rest your weary bones, adventurer! A tankard of spiced cider cures all curses. Mind the talk of shadows in the Blackwood Forest... folks say the trees have eyes!"
	barkeep.position = Vector3(-6.2, 0.0, 17.5)
	parent.add_child(barkeep)

	# 2. Sanctuary Marketplace (West flank: X = -18.0, Z = 16.5)
	var market = _place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(-18.0, 0.0, 16.5), Vector3.ONE * 4.5, -30.0)
	_add_static_box(parent, Vector3(-18.0, 2.5, 16.5), Vector3(7.5, 5.0, 6.0))
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(-14.8, 0.0, 15.5), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/crate_open.gltf", Vector3(-15.2, 0.0, 17.2), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(-14.2, 0.0, 16.8), Vector3.ONE * 1.5)

	# NPC: Merchant Corin
	var merchant = TownNPCScript.new()
	merchant.npc_id = "merchant"
	merchant.npc_name = "Corin"
	merchant.npc_title = "Traveling Merchant"
	merchant.icon = "💰"
	merchant.model_path = "res://assets/characters/adventurers/Rogue.glb"
	merchant.model_scale = Vector3(0.53, 0.53, 0.53)
	merchant.model_rotation_y = 60.0
	merchant.dialogue_text = "Finest goods from across the realm! Weapons tempered in dwarven fire and draughts brewed by eastern alchemists. Bring me ancient relics from the catacombs and I will pay a handsome fortune!"
	merchant.position = Vector3(-14.5, 0.0, 16.0)
	parent.add_child(merchant)

	# 3. Guard Archery Training Yard (East of South Highway: X = 12.0, Z = 17.0)
	var range_bldg = _place_prop(parent, "res://assets/overworld/building_archeryrange_blue.gltf", Vector3(12.0, 0.0, 17.0), Vector3.ONE * 4.5, -45.0)
	_add_static_box(parent, Vector3(12.0, 3.5, 17.0), Vector3(7.0, 7.5, 7.0))
	_place_prop(parent, "res://assets/overworld/target.gltf", Vector3(6.5, 0.0, 16.0), Vector3.ONE * 3.5, 90.0)
	_place_prop(parent, "res://assets/overworld/target.gltf", Vector3(6.5, 0.0, 18.2), Vector3.ONE * 3.5, 90.0)
	_place_prop(parent, "res://assets/overworld/bucket_arrows.gltf", Vector3(8.5, 0.0, 16.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(8.5, 0.0, 18.5), Vector3.ONE * 1.8, 90.0)

	# 4. Street Lantern Posts along Thoroughfares
	_place_lantern_post(parent, Vector3(-5.0, 0.0, 15.0), 45.0)
	_place_lantern_post(parent, Vector3(5.0, 0.0, 15.0), -45.0)
	_place_lantern_post(parent, Vector3(-2.8, 0.0, 20.5))
	_place_lantern_post(parent, Vector3(2.8, 0.0, 20.5))
	_place_lantern_post(parent, Vector3(-2.8, 0.0, 27.5), 180.0)
	_place_lantern_post(parent, Vector3(2.8, 0.0, 27.5), 180.0)
	_place_lantern_post(parent, Vector3(-3.5, 0.0, 37.5))
	_place_lantern_post(parent, Vector3(3.5, 0.0, 37.5))

func _place_lantern_post(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var post = _place_prop(parent, "res://assets/overworld/post_lantern.gltf", pos, Vector3.ONE * 1.1, rot_y)
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.45) # Warm medieval lantern
	light.light_energy = 1.6
	light.omni_range = 8.0
	light.position = Vector3(0.0, 3.2, 0.0)
	post.add_child(light)
	return post

func _build_river_and_bridges(parent: Node3D) -> void:
	# 1. Sunken Riverbed Silt/Pebble Basin (Y = -0.45m)
	var bed_mesh_inst = MeshInstance3D.new()
	bed_mesh_inst.name = "RiverbedVisual"
	var b_mesh = PlaneMesh.new()
	b_mesh.size = Vector2(110.0, 8.8)
	bed_mesh_inst.mesh = b_mesh
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.12, 0.16, 0.13) # Dark wet river silt and smooth stones
	b_mat.roughness = 0.95
	bed_mesh_inst.material_override = b_mat
	bed_mesh_inst.position = Vector3(0.0, -0.45, 24.0)
	parent.add_child(bed_mesh_inst)

	# 2. Continuous River Water Surface (Y = -0.12m, recessed below ground level)
	var river_mesh_inst = MeshInstance3D.new()
	river_mesh_inst.name = "RiverWaterSurface"
	var r_mesh = PlaneMesh.new()
	r_mesh.size = Vector2(110.0, 8.0)
	river_mesh_inst.mesh = r_mesh
	var w_mat = ShaderMaterial.new()
	w_mat.shader = load("res://shaders/river_flow.gdshader")
	river_mesh_inst.material_override = w_mat
	river_mesh_inst.position = Vector3(0.0, -0.12, 24.0)
	parent.add_child(river_mesh_inst)

	# 3. Natural Stone Riverbanks: lining North Bank (Z=19.8) and South Bank (Z=28.2)
	for rx in range(-24, 25, 2):
		var x_f = float(rx) * 2.2
		# Skip where bridges cross (X ~ 0 and X ~ -18)
		if abs(x_f) > 3.2 and abs(x_f - (-18.0)) > 3.2:
			var r_model = "res://assets/overworld/rock_single_A.gltf" if (rx % 4 == 0) else "res://assets/overworld/rock_single_B.gltf"
			_place_prop(parent, r_model, Vector3(x_f, 0.0, 19.8), Vector3(2.0, 1.4, 2.0), float((rx * 37) % 360))
			_place_prop(parent, r_model, Vector3(x_f + 0.8, 0.0, 28.2), Vector3(2.0, 1.4, 2.0), float((rx * 53) % 360))

	# Water lilies and river reeds in the water
	_place_prop(parent, "res://assets/overworld/waterlily_A.gltf", Vector3(-8.0, -0.10, 23.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/waterlily_B.gltf", Vector3(6.0, -0.10, 24.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/waterplant_A.gltf", Vector3(-5.0, -0.12, 21.2), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/waterplant_B.gltf", Vector3(14.0, -0.12, 26.8), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/waterplant_C.gltf", Vector3(-24.0, -0.12, 22.5), Vector3.ONE * 1.8)

	# Main Highway Stone Arch Bridge (Spans the full 8m river width)
	_place_prop(parent, "res://assets/overworld/building_bridge_A.gltf", Vector3(0.0, 0.0, 24.0), Vector3(4.0, 3.2, 7.5))
	_add_static_box(parent, Vector3(0.0, 0.4, 24.0), Vector3(4.5, 0.8, 8.5))
	_add_static_box(parent, Vector3(-2.4, 1.2, 24.0), Vector3(0.5, 1.6, 8.5))
	_add_static_box(parent, Vector3(2.4, 1.2, 24.0), Vector3(0.5, 1.6, 8.5))

	# Western Wooden Footbridge
	_place_prop(parent, "res://assets/overworld/building_bridge_B.gltf", Vector3(-18.0, 0.0, 24.0), Vector3(3.6, 2.8, 7.0))
	_add_static_box(parent, Vector3(-18.0, 0.35, 24.0), Vector3(4.0, 0.7, 8.0))
	_add_static_box(parent, Vector3(-20.2, 1.0, 24.0), Vector3(0.4, 1.4, 8.0))
	_add_static_box(parent, Vector3(-15.8, 1.0, 24.0), Vector3(0.4, 1.4, 8.0))

	# Riverside Watermill (10.4m tall with rotating water wheel)
	var watermill = _place_prop(parent, "res://assets/overworld/building_watermill_blue.gltf", Vector3(12.0, 0.0, 19.0), Vector3.ONE * 6.0, -90.0)
	_add_static_box(parent, Vector3(12.0, 3.5, 19.0), Vector3(6.5, 7.0, 7.0))
	var wm_rot = RotatingProp.new()
	wm_rot.target_node_name = "building_watermill_wheel_blue"
	wm_rot.rotation_axis = Vector3(0, 0, 1)
	wm_rot.rpm = 12.0
	watermill.add_child(wm_rot)

func _build_farmlands_hamlet(parent: Node3D) -> void:
	# Grand Windmill (Towering 14.3m high landmark with rotating blades)
	var windmill = _place_prop(parent, "res://assets/overworld/building_windmill_blue.gltf", Vector3(34.0, 0.0, 38.0), Vector3.ONE * 12.0)
	_add_static_cyl(parent, Vector3(34.0, 0.0, 38.0), 4.0, 13.0)
	var fan_rot = RotatingProp.new()
	fan_rot.target_node_name = "building_windmill_top_fan_blue"
	fan_rot.rotation_axis = Vector3(0, 0, 1)
	fan_rot.rpm = 7.5
	windmill.add_child(fan_rot)
	
	# Rolling Hill behind windmill
	_place_prop(parent, "res://assets/overworld/hill_single_A.gltf", Vector3(42.0, 0.0, 42.0), Vector3.ONE * 9.0)
	
	# Thatched Cottages (North of river: Z in [13, 16], X in [22, 38])
	_place_prop(parent, "res://assets/overworld/building_home_A_blue.gltf", Vector3(22.0, 0.0, 14.0), Vector3.ONE * 7.5, 45.0)
	_add_static_box(parent, Vector3(22.0, 3.5, 14.0), Vector3(6.2, 6.5, 6.5))
	AmbientFX.create_chimney_smoke(parent, Vector3(22.0, 7.2, 14.0))
	
	_place_prop(parent, "res://assets/overworld/building_home_B_blue.gltf", Vector3(38.0, 0.0, 15.0), Vector3.ONE * 7.0, -30.0)
	_add_static_box(parent, Vector3(38.0, 4.0, 15.0), Vector3(6.5, 7.5, 7.8))
	AmbientFX.create_chimney_smoke(parent, Vector3(38.0, 8.8, 15.0))
	
	# Village Stone Well (3.5m tall well)
	_place_prop(parent, "res://assets/overworld/building_well_blue.gltf", Vector3(28.0, 0.0, 17.5), Vector3.ONE * 2.8)
	_add_static_cyl(parent, Vector3(28.0, 0.0, 17.5), 1.4, 3.2)
	
	# NPC: Farmer Giles
	var giles = TownNPCScript.new()
	giles.npc_id = "farmer"
	giles.npc_name = "Farmer Giles"
	giles.npc_title = "Hamlet Elder"
	giles.icon = "🌾"
	giles.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	giles.model_scale = Vector3(0.56, 0.56, 0.56)
	giles.model_rotation_y = -45.0
	giles.dialogue_text = "Good day, traveler! Welcome to our modest hamlet. The wheat is ripe, but hungry beasts stalk our pastures. Deliver raw meat or fine hides from the wild beasts, and we shall reward you richly in coin!"
	giles.position = Vector3(25.0, 0.0, 17.0)
	parent.add_child(giles)

	# Tilled Pumpkin Patch (North of river: X in [31, 35], Z in [10, 13])
	for px in range(31, 36):
		for pz in range(10, 13):
			_place_prop(parent, "res://assets/overworld/pumpkin_orange.gltf", Vector3(float(px) + 0.3, 0.0, float(pz) + 0.3), Vector3.ONE * 0.4)

	# Farm Tools & Storage Props
	_place_prop(parent, "res://assets/overworld/wheelbarrow.gltf", Vector3(23.0, 0.0, 18.5), Vector3.ONE * 1.6, 35.0)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(21.5, 0.0, 16.0), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(20.5, 0.0, 15.5), Vector3.ONE * 1.3)

	# =========================================================================
	# COMPLETELY DRY, FULLY ENCLOSED ANIMAL PASTURE (South of river at Z in [31, 43], X in [23, 41])
	# =========================================================================
	var p_x1 = 23.0
	var p_x2 = 41.0
	var p_z1 = 31.0
	var p_z2 = 43.0
	var f_step = 2.5
	
	# North fence line (Z = 31.0, dry land 3m south of river)
	var x_cursor = p_x1
	while x_cursor <= p_x2:
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(x_cursor, 0.0, p_z1), Vector3.ONE * 2.2)
		x_cursor += f_step
		
	# South fence line (Z = 43.0)
	x_cursor = p_x1
	while x_cursor <= p_x2:
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(x_cursor, 0.0, p_z2), Vector3.ONE * 2.2)
		x_cursor += f_step
		
	# East fence line (X = 41.0)
	var z_cursor = p_z1
	while z_cursor <= p_z2:
		_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(p_x2, 0.0, z_cursor), Vector3.ONE * 2.2, 90.0)
		z_cursor += f_step
		
	# West fence line (X = 23.0 with entrance gate at Z = 37.0)
	z_cursor = p_z1
	while z_cursor <= p_z2:
		if abs(z_cursor - 37.0) < 1.3:
			_place_prop(parent, "res://assets/overworld/fence_wood_straight_gate.gltf", Vector3(p_x1, 0.0, z_cursor), Vector3.ONE * 2.2, 90.0)
		else:
			_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(p_x1, 0.0, z_cursor), Vector3.ONE * 2.2, 90.0)
		z_cursor += f_step

	# Pasture Perimeter Collision (Keeps livestock inside the corral)
	_add_static_box(parent, Vector3((p_x1 + p_x2) * 0.5, 0.8, p_z1), Vector3(p_x2 - p_x1 + 1.0, 1.6, 0.4))
	_add_static_box(parent, Vector3((p_x1 + p_x2) * 0.5, 0.8, p_z2), Vector3(p_x2 - p_x1 + 1.0, 1.6, 0.4))
	_add_static_box(parent, Vector3(p_x2, 0.8, (p_z1 + p_z2) * 0.5), Vector3(0.4, 1.6, p_z2 - p_z1 + 1.0))
	_add_static_box(parent, Vector3(p_x1, 0.8, (p_z1 + p_z2) * 0.5), Vector3(0.4, 1.6, p_z2 - p_z1 + 1.0))

	# Pasture Livestock Dressing (Water troughs, feed buckets)
	_place_prop(parent, "res://assets/overworld/bucket_water.gltf", Vector3(25.5, 0.0, 33.0), Vector3.ONE * 2.5)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(24.5, 0.0, 32.5), Vector3.ONE * 1.6)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(24.0, 0.0, 33.5), Vector3.ONE * 1.4)

	# Grazing Animals inside the dry fenced pasture
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(28.0, 0.0, 35.0), 45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(36.0, 0.0, 39.0), -60.0)
	_spawn_animal(parent, AnimalAI.AnimalType.BULL, Vector3(32.0, 0.0, 36.0), 120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.HORSE, Vector3(27.0, 0.0, 40.0), 15.0)
	_spawn_animal(parent, AnimalAI.AnimalType.HORSE, Vector3(38.0, 0.0, 34.0), -85.0)

func _build_castle_citadel(parent: Node3D) -> void:
	# Royal Castle Keep (Imposing 25.8m tall imperial fortress)
	_place_prop(parent, "res://assets/overworld/building_castle_blue.gltf", Vector3(0.0, 0.0, 44.0), Vector3.ONE * 6.5)
	_add_static_box(parent, Vector3(0.0, 8.0, 44.0), Vector3(13.0, 16.0, 14.5))

	# Left & Right Citadel Watchtowers (15.4m tall catapult towers)
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(-12.0, 0.0, 38.0), Vector3.ONE * 9.5)
	_add_static_box(parent, Vector3(-12.0, 7.0, 38.0), Vector3(4.5, 14.0, 4.5))
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(12.0, 0.0, 38.0), Vector3.ONE * 9.5)
	_add_static_box(parent, Vector3(12.0, 7.0, 38.0), Vector3(4.5, 14.0, 4.5))

	# Stone curtain walls connecting keep to towers (7.5m tall battlements)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-6.0, 0.0, 38.0), Vector3(4.0, 4.5, 3.0))
	_add_static_box(parent, Vector3(-6.0, 3.5, 38.0), Vector3(6.5, 7.5, 2.5))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(6.0, 0.0, 38.0), Vector3(4.0, 4.5, 3.0))
	_add_static_box(parent, Vector3(6.0, 3.5, 38.0), Vector3(6.5, 7.5, 2.5))

	# Garrison Barracks (9.0m tall)
	_place_prop(parent, "res://assets/overworld/building_barracks_blue.gltf", Vector3(18.0, 0.0, 34.0), Vector3.ONE * 5.5, -45.0)
	_add_static_box(parent, Vector3(18.0, 4.5, 34.0), Vector3(8.0, 7.0, 8.5))

	# Military Market Outpost
	_place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(-18.0, 0.0, 34.0), Vector3.ONE * 3.6, 45.0)

	# NPC: Commander Drake (Proportionate ~1.92m knight commander)
	var drake = TownNPCScript.new()
	drake.npc_id = "commander"
	drake.npc_name = "Commander Drake"
	drake.npc_title = "Citadel Commander"
	drake.icon = "🛡️"
	drake.model_path = "res://assets/characters/adventurers/Knight.glb"
	drake.model_scale = Vector3(0.58, 0.58, 0.58)
	drake.model_rotation_y = 180.0
	drake.dialogue_text = "Stand firm, warrior! The Imperial Citadel stands vigil against the abyss. Our scouts report arcane crystals gleaming in the north-eastern crags, and sacred relics lost in the western ruins. Check your royal bounties and bring glory to the realm!"
	drake.position = Vector3(0.0, 0.0, 34.0)
	parent.add_child(drake)

	# Castle Props
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(-3.0, 0.0, 36.0), Vector3.ONE * 2.0, 25.0)
	_place_prop(parent, "res://assets/overworld/flag_blue.gltf", Vector3(-12.0, 15.0, 38.0), Vector3.ONE * 3.0)
	_place_prop(parent, "res://assets/overworld/flag_blue.gltf", Vector3(12.0, 15.0, 38.0), Vector3.ONE * 3.0)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(3.0, 0.0, 36.0), Vector3.ONE * 1.5)
	AmbientFX.create_chimney_smoke(parent, Vector3(18.0, 8.8, 34.0))

	# Circling Hawks Flock above Castle Keep
	var flock_castle = CirclingFlock.new()
	flock_castle.position = Vector3(0.0, 28.0, 42.0)
	flock_castle.bird_count = 5
	flock_castle.circle_radius = 14.0
	parent.add_child(flock_castle)

func _build_blackwood_forest(parent: Node3D) -> void:
	# Lumbermill (9.5m tall building)
	_place_prop(parent, "res://assets/overworld/building_lumbermill_blue.gltf", Vector3(-24.0, 0.0, 32.0), Vector3.ONE * 6.0, 90.0)
	_add_static_box(parent, Vector3(-24.0, 4.5, 32.0), Vector3(8.0, 7.0, 8.0))

	# Glowing Forest Fireflies
	AmbientFX.create_forest_fireflies(parent, Vector3(-28.0, 1.8, 22.0), 9.0)
	AmbientFX.create_forest_fireflies(parent, Vector3(-34.0, 1.8, 32.0), 9.0)

	# Dense Forest Trees (Scaled 3.0x - 3.6x -> 10m to 14m tall realistic pines and birches)
	var forest_locs = [
		Vector3(-18.0, 0.0, 8.0), Vector3(-22.0, 0.0, 10.0), Vector3(-26.0, 0.0, 7.0),
		Vector3(-22.0, 0.0, 15.0), Vector3(-28.0, 0.0, 16.0), Vector3(-32.0, 0.0, 14.0),
		Vector3(-25.0, 0.0, 28.0), Vector3(-30.0, 0.0, 26.0), Vector3(-36.0, 0.0, 25.0),
		Vector3(-22.0, 0.0, 38.0), Vector3(-28.0, 0.0, 40.0), Vector3(-34.0, 0.0, 38.0),
		Vector3(-38.0, 0.0, 12.0), Vector3(-42.0, 0.0, 20.0), Vector3(-42.0, 0.0, 28.0),
		Vector3(-44.0, 0.0, 36.0), Vector3(-36.0, 0.0, 42.0), Vector3(-24.0, 0.0, 42.0)
	]
	var f_trees = [
		"res://assets/overworld/tree_pine_orange_large.gltf",
		"res://assets/overworld/trees_A_large.gltf",
		"res://assets/overworld/trees_B_large.gltf",
		"res://assets/overworld/tree_pine_yellow_large.gltf"
	]
	for i in range(forest_locs.size()):
		var lp = forest_locs[i]
		var tm = f_trees[i % f_trees.size()]
		_place_prop(parent, tm, lp, Vector3.ONE * 3.2, float((i * 53) % 360))
		_add_static_cyl(parent, lp, 1.0, 8.0)

	# Boulders
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(-27.0, 0.0, 18.0), Vector3.ONE * 2.5)
	_place_prop(parent, "res://assets/overworld/rock_single_D.gltf", Vector3(-35.0, 0.0, 20.0), Vector3.ONE * 2.8)

	# Forest Wildlife (Proper animal scales: Stags 32x, Deer 28x, Wolves 17x, Foxes 9x)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-26.0, 0.0, 14.0), 30.0)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-34.0, 0.0, 26.0), -45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-22.0, 0.0, 18.0), 110.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-30.0, 0.0, 12.0), -120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.FOX, Vector3(-28.0, 0.0, 32.0), 75.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-38.0, 0.0, 18.0), 160.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-36.0, 0.0, 30.0), -30.0)

	# Special Quest Timber Nodes
	_spawn_material_node(parent, "heartwood_timber", "Heartwood Timber", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-24.0, 0.0, 12.0), Color(0.8, 0.5, 0.2), 20, 15, Vector3(2.5, 2.5, 2.5))
	_spawn_material_node(parent, "ironwood_logs", "Ironwood Logs", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-32.0, 0.0, 26.0), Color(0.7, 0.4, 0.2), 25, 20, Vector3(2.5, 2.5, 2.5))

func _build_iron_mountains(parent: Node3D) -> void:
	# Giant Mountain Peaks (15m - 25m tall mountain crags)
	var mtns = [
		{"pos": Vector3(28.0, 0.0, -36.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 9.0},
		{"pos": Vector3(38.0, 0.0, -32.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 9.5},
		{"pos": Vector3(44.0, 0.0, -22.0), "path": "res://assets/overworld/mountain_C.gltf", "scale": 9.0},
		{"pos": Vector3(40.0, 0.0, -12.0), "path": "res://assets/overworld/mountain_A_grass.gltf", "scale": 8.5},
		{"pos": Vector3(22.0, 0.0, -38.0), "path": "res://assets/overworld/hills_A.gltf", "scale": 7.0},
		{"pos": Vector3(20.0, 0.0, -24.0), "path": "res://assets/overworld/hills_B_trees.gltf", "scale": 7.0}
	]
	for m in mtns:
		_place_prop(parent, m["path"], m["pos"], Vector3.ONE * m["scale"])
		_add_static_box(parent, m["pos"] + Vector3(0, 6.0, 0), Vector3(m["scale"] * 2.0, 12.0, m["scale"] * 2.0))

	# Mountain Mine Entrance (6.2m tall mine)
	_place_prop(parent, "res://assets/overworld/building_mine_blue.gltf", Vector3(34.0, 0.0, -22.0), Vector3.ONE * 5.5, -90.0)
	_add_static_box(parent, Vector3(34.0, 3.5, -22.0), Vector3(7.5, 6.0, 7.5))

	# Mountain Wolf Guard (Fierce predator)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(30.0, 0.0, -24.0), 45.0)

	# Special Quest Mineral Nodes (Mineable crystals and gold ingots)
	_spawn_material_node(parent, "arcane_crystal", "Arcane Cyan Crystal", "💎", "res://assets/items/quest_materials/Crystal1.glb", Vector3(28.0, 0.0, -20.0), Color(0.2, 0.8, 1.0), 30, 25, Vector3(1.8, 1.8, 1.8))
	_spawn_material_node(parent, "emerald_crystal", "Emerald Geo-Crystal", "💎", "res://assets/items/quest_materials/Crystal2.glb", Vector3(36.0, 0.0, -26.0), Color(0.2, 1.0, 0.4), 35, 30, Vector3(1.8, 1.8, 1.8))
	_spawn_material_node(parent, "gold_vein", "Mountain Gold Vein", "🪙", "res://assets/items/quest_materials/Gold_Ingots.glb", Vector3(26.0, 0.0, -30.0), Color(1.0, 0.85, 0.2), 40, 35, Vector3(1.5, 1.5, 1.5))
	_spawn_material_node(parent, "iron_ore", "Highland Iron Ore", "⛏️", "res://assets/overworld/resource_stone.gltf", Vector3(32.0, 0.0, -16.0), Color(0.6, 0.65, 0.7), 25, 20, Vector3(2.5, 2.5, 2.5))

func _build_forgotten_ruins(parent: Node3D) -> void:
	# Shrines & Ancient Stone Pillars (8.7m tall columns)
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-34.0, 0.0, -4.0), Vector3.ONE * 2.8)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-30.0, 0.0, -8.0), Vector3(1.6, 2.5, 1.6))
	_add_static_cyl(parent, Vector3(-30.0, 0.0, -8.0), 0.9, 7.5)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-38.0, 0.0, -8.0), Vector3(1.6, 2.5, 1.6))
	_add_static_cyl(parent, Vector3(-38.0, 0.0, -8.0), 0.9, 7.5)
	_place_prop(parent, "res://assets/overworld/shrine.gltf", Vector3(-32.0, 0.0, 2.0), Vector3.ONE * 2.5)
	_place_prop(parent, "res://assets/overworld/skull_candle.gltf", Vector3(-33.0, 0.0, -2.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/bone_A.gltf", Vector3(-31.0, 0.0, -5.0), Vector3.ONE * 1.8)

	# NPC: Hermit Morvath (Proportionate ~1.78m mage)
	var hermit = TownNPCScript.new()
	hermit.npc_id = "hermit"
	hermit.npc_name = "Hermit Morvath"
	hermit.npc_title = "Keeper of the Forgotten"
	hermit.icon = "🔮"
	hermit.model_path = "res://assets/characters/adventurers/Mage.glb"
	hermit.model_scale = Vector3(0.53, 0.53, 0.53)
	hermit.model_rotation_y = 65.0
	hermit.dialogue_text = "Tread lightly, warrior. The stones here remember an empire older than memory. The Sacred Chalice and the Ancient Codex are scattered among these cracked pedestals. Channel the Soul Echoes you reap to unlock arcane boons!"
	hermit.position = Vector3(-32.0, 0.0, -3.0)
	parent.add_child(hermit)

	# Sacred Relic Material Nodes
	_spawn_material_node(parent, "sacred_chalice", "Sacred Chalice of the First Kings", "🏆", "res://assets/items/quest_materials/Chalice.glb", Vector3(-36.0, 0.0, -6.0), Color(1.0, 0.8, 0.2), 50, 50, Vector3(2.0, 2.0, 2.0))
	_spawn_material_node(parent, "ossuary_codex", "Forgotten Ossuary Codex", "📜", "res://assets/items/quest_materials/Scroll.glb", Vector3(-30.0, 0.0, 2.0), Color(0.9, 0.85, 0.6), 40, 40, Vector3(2.0, 2.0, 2.0))
	_spawn_material_node(parent, "smugglers_chest", "Sunken Smuggler's Chest", "📦", "res://assets/items/quest_materials/Chest_Ingots.glb", Vector3(-26.0, 0.0, -12.0), Color(0.95, 0.75, 0.2), 60, 45, Vector3(1.5, 1.5, 1.5))

func _spawn_animal(parent: Node3D, type: int, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var animal = AnimalAIScript.new()
	animal.animal_type = type
	animal.position = pos
	if rot_y != 0.0:
		animal.rotation_degrees.y = rot_y
	parent.add_child(animal)
	return animal

func _spawn_material_node(parent: Node3D, mat_id: String, d_name: String, icon_s: String, m_path: String, pos: Vector3, col: Color, gold: int, echoes: int, m_scale: Vector3 = Vector3(1.4, 1.4, 1.4)) -> Node3D:
	var node = QuestMaterialNodeScript.new()
	node.material_id = mat_id
	node.display_name = d_name
	node.icon = icon_s
	node.model_path = m_path
	node.model_scale = m_scale
	node.glow_color = col
	node.gold_reward = gold
	node.echo_reward = echoes
	node.position = pos
	parent.add_child(node)
	return node

func _place_prop(parent: Node3D, path: String, pos: Vector3, sc: Vector3 = Vector3.ONE, rot_y_deg: float = 0.0) -> Node3D:
	var prop = AssetLoader.load_or_generate_model(path, "dungeon", "prop")
	prop.position = pos
	prop.scale = sc
	if rot_y_deg != 0.0:
		prop.rotation_degrees.y = rot_y_deg
	parent.add_child(prop)
	
	if "flag" in path:
		_apply_flag_shader(prop)
		
	return prop

func _apply_flag_shader(node: Node3D) -> void:
	var flag_shader = load("res://shaders/waving_flag.gdshader")
	if flag_shader:
		var flag_mat = ShaderMaterial.new()
		flag_mat.shader = flag_shader
		for child in node.find_children("*", "MeshInstance3D", true, false):
			var mi = child as MeshInstance3D
			if mi:
				mi.material_override = flag_mat

func _add_static_box(parent: Node3D, pos: Vector3, sz: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = 1
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = sz
	col.shape = box
	col.position = pos
	body.add_child(col)
	parent.add_child(body)
	return body

func _add_static_cyl(parent: Node3D, pos: Vector3, radius: float, height: float) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = 1
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	col.shape = cyl
	col.position = pos + Vector3(0, height * 0.5, 0)
	body.add_child(col)
	parent.add_child(body)
	return body
