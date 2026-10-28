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
	var ground_size = 96.0
	var half_s = ground_size * 0.5
	
	# 1. Floor Static Collision & Safety Void Safeguard (Full 106m x 106m realm)
	var floor_body = StaticBody3D.new()
	floor_body.collision_layer = 1
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(ground_size + 10.0, 1.2, ground_size + 10.0)
	col_shape.shape = box
	col_shape.position.y = -0.6
	floor_body.add_child(col_shape)
	parent.add_child(floor_body)
	
	# Outer world perimeter boundary collision barriers (North, South, East, West at +-48m)
	var wall_h = 10.0
	var thick = 2.0
	_add_static_box(parent, Vector3(0, wall_h * 0.5, -half_s - thick * 0.5), Vector3(ground_size + thick * 2, wall_h, thick))
	_add_static_box(parent, Vector3(0, wall_h * 0.5, half_s + thick * 0.5), Vector3(ground_size + thick * 2, wall_h, thick))
	_add_static_box(parent, Vector3(half_s + thick * 0.5, wall_h * 0.5, 0), Vector3(thick, wall_h, ground_size))
	_add_static_box(parent, Vector3(-half_s - thick * 0.5, wall_h * 0.5, 0), Vector3(thick, wall_h, ground_size))

	# 2. Hex Grass Tiles across the sanctuary grounds
	var hex_w = 2.0
	var hex_h = 1.732
	for r in range(-7, 8):
		for q in range(-7, 8):
			var x_pos = q * hex_w + (0.5 * hex_w if (abs(r) % 2 == 1) else 0.0)
			var z_pos = r * hex_h
			if abs(x_pos) <= 14.8 and abs(z_pos) <= 14.8:
				var hex = AssetLoader.load_or_generate_model("res://assets/overworld/hex_grass.gltf", "dungeon", "hex_grass")
				hex.position = Vector3(x_pos, 0, z_pos)
				parent.add_child(hex)

	# 3. Center Cobblestone Plaza (for Hero Class Pedestals)
	for px in range(-3, 4):
		for pz in range(-1, 4):
			var stone = AssetLoader.load_or_generate_model("res://assets/dungeon/floor_tile_large.glb", "dungeon", "floor_tile_large")
			stone.scale = Vector3(0.5, 1.0, 0.5)
			stone.position = Vector3(px * 2.0, 0.02, pz * 2.0)
			parent.add_child(stone)

	# 4. North: The Ancient Crypt (Mausoleum entrance to the catacombs)
	var crypt = AssetLoader.load_or_generate_model("res://assets/overworld/crypt.gltf", "dungeon", "crypt")
	crypt.position = Vector3(0, 0, -10.5)
	parent.add_child(crypt)
	_add_static_box(parent, Vector3(0, 2.5, -11.5), Vector3(6.5, 5.0, 5.5))
	
	# Dead cemetery trees and gravestones
	_place_prop(parent, "res://assets/overworld/tree_dead_large.gltf", Vector3(-5.5, 0, -9.5), Vector3.ONE * 1.25)
	_place_prop(parent, "res://assets/overworld/tree_dead_large.gltf", Vector3(5.5, 0, -9.5), Vector3.ONE * 1.25, 75.0)
	_place_prop(parent, "res://assets/overworld/grave_A.gltf", Vector3(-3.5, 0, -7.5), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/gravestone.gltf", Vector3(3.5, 0, -7.5), Vector3.ONE * 1.4, -25.0)
	_place_prop(parent, "res://assets/overworld/grave_A_destroyed.gltf", Vector3(-5.2, 0, -6.8), Vector3.ONE * 1.2)

	# 5. West: The Blacksmith's Forge (housing the Upgrade Altar)
	var smith = AssetLoader.load_or_generate_model("res://assets/overworld/building_blacksmith_blue.gltf", "dungeon", "blacksmith")
	smith.scale = Vector3(2.6, 2.6, 2.6)
	smith.position = Vector3(-9.5, 0, 0.0)
	smith.rotation_degrees.y = 90.0
	parent.add_child(smith)
	_add_static_box(parent, Vector3(-9.8, 2.0, 0.0), Vector3(4.5, 4.0, 4.5))

	# Master Torval - Town Blacksmith NPC
	var torval = TownNPCScript.new()
	torval.npc_id = "blacksmith"
	torval.npc_name = "Master Torval"
	torval.npc_title = "Forge Master"
	torval.icon = "⚒️"
	torval.model_path = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
	torval.model_scale = Vector3(1.3, 1.3, 1.3)
	torval.model_rotation_y = 90.0
	torval.dialogue_text = "Hail, warrior! The forge fires blaze with eternal embers. Deliver unto me the Soul Echoes reaped from the Ossuary depths, and I shall temper your weapons, bolster your armor, and sharpen your dash reflexes!"
	torval.position = Vector3(-7.5, 0, 0.0)
	parent.add_child(torval)

	# Blacksmith forge props
	_place_prop(parent, "res://assets/furniture/fireplace.gltf", Vector3(-9.2, 0, -2.4), Vector3.ONE * 1.3, 90.0)
	_place_prop(parent, "res://assets/furniture/table_medium.gltf", Vector3(-7.5, 0, -2.2), Vector3.ONE * 1.2, 0.0)
	_place_prop(parent, "res://assets/furniture/chair_stool_wood.gltf", Vector3(-6.8, 0, -2.2), Vector3.ONE * 1.2)

	# 6. East: The Ruined Cathedral
	var church = AssetLoader.load_or_generate_model("res://assets/overworld/building_church_blue.gltf", "dungeon", "church")
	church.scale = Vector3(3.0, 3.0, 3.0)
	church.position = Vector3(9.5, 0, 0.0)
	church.rotation_degrees.y = -90.0
	parent.add_child(church)
	_add_static_box(parent, Vector3(9.8, 2.5, 0.0), Vector3(4.5, 5.0, 5.0))
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(6.5, 0, 2.2), Vector3.ONE * 1.5, -45.0)

	# Eldress Alyssa - High Priestess & Bounty Questgiver NPC
	var alyssa = TownNPCScript.new()
	alyssa.npc_id = "priestess"
	alyssa.npc_name = "Eldress Alyssa"
	alyssa.npc_title = "Sanctuary Priestess"
	alyssa.icon = "✨"
	alyssa.model_path = "res://assets/characters/adventurers/Mage.glb"
	alyssa.model_scale = Vector3(1.15, 1.15, 1.15)
	alyssa.model_rotation_y = -90.0
	alyssa.dialogue_text = "May the Sacred Light guide your steps, champion. The dead stir restlessly in the Catacombs below. Inquire upon our Sanctuary Bounties—purge the wicked hordes to claim divine favour and rich reward!"
	alyssa.position = Vector3(7.5, 0, 0.0)
	parent.add_child(alyssa)

	# Cathedral props
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(6.5, 0, -2.2), Vector3.ONE * 1.5, -45.0)
	_place_prop(parent, "res://assets/furniture/cabinet_small_decorated.gltf", Vector3(9.2, 0, -2.5), Vector3.ONE * 1.2, -90.0)

	# 7. South: Castle Arch Gateway
	var gate = AssetLoader.load_or_generate_model("res://assets/overworld/arch_gate.gltf", "dungeon", "arch_gate")
	gate.position = Vector3(0, 0, 11.5)
	parent.add_child(gate)
	_add_static_box(parent, Vector3(-2.8, 2.0, 11.5), Vector3(1.5, 4.0, 1.5))
	_add_static_box(parent, Vector3(2.8, 2.0, 11.5), Vector3(1.5, 4.0, 1.5))

	# Captain Vane - Gate Sentinel NPC
	var vane = TownNPCScript.new()
	vane.npc_id = "guard"
	vane.npc_name = "Captain Vane"
	vane.npc_title = "Gate Sentinel"
	vane.icon = "🛡️"
	vane.model_path = "res://assets/characters/adventurers/Knight.glb"
	vane.model_scale = Vector3(1.2, 1.2, 1.2)
	vane.model_rotation_y = 180.0
	vane.dialogue_text = "Halt, warrior! You stand before the threshold of the Ossuary Catacombs. Beneath the north crypt lies the descent sigil. Step upon the glowing seal to plunge into the underworld. Beware the Bone Titan's wrath on the final floor!"
	vane.position = Vector3(0, 0, 9.5)
	parent.add_child(vane)

	# 8. Courtyard Perimeter Trees & Nature Rocks
	var border_trees = [
		Vector3(-12.0, 0, -12.0), Vector3(-8.5, 0, -12.5), Vector3(8.5, 0, -12.5), Vector3(12.0, 0, -12.0),
		Vector3(-12.5, 0, -5.0), Vector3(-12.5, 0, 5.0), Vector3(12.5, 0, -5.0), Vector3(12.5, 0, 5.0),
		Vector3(-12.0, 0, 12.0), Vector3(-6.0, 0, 12.5), Vector3(6.0, 0, 12.5), Vector3(12.0, 0, 12.0)
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
		_place_prop(parent, model_p, t_pos, Vector3.ONE * 1.3, float((i * 47) % 360))
		_add_static_cyl(parent, t_pos, 0.7, 4.0)

	# Decorative Props (Rocks, Barrels, Crates)
	_place_prop(parent, "res://assets/overworld/rock_single_A.gltf", Vector3(-4.5, 0, 8.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/rock_single_B.gltf", Vector3(4.5, 0, 8.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-2.2, 0, 10.0), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/barrel.gltf", Vector3(-1.6, 0, 10.4), Vector3.ONE * 1.1)

	# Fortified Town Walls flanking the South Arch Gateway
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-5.5, 0, 11.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(5.5, 0, 11.5), Vector3.ONE * 1.5)
	_add_static_box(parent, Vector3(-6.5, 2.0, 11.5), Vector3(6.5, 4.0, 1.5))
	_add_static_box(parent, Vector3(6.5, 2.0, 11.5), Vector3(6.5, 4.0, 1.5))

	# 9. EXPANDED OPEN WORLD MEDIEVAL REALM
	_build_road_network(parent)
	_build_river_and_bridges(parent)
	_build_farmlands_hamlet(parent)
	_build_castle_citadel(parent)
	_build_blackwood_forest(parent)
	_build_iron_mountains(parent)
	_build_forgotten_ruins(parent)

func _build_road_network(parent: Node3D) -> void:
	# Main Highway: Sanctuary South Gate (Z=12) -> Stone River Bridge (Z=20) -> Imperial Castle Keep (Z=36)
	for z_step in range(12, 37, 2):
		if z_step >= 18 and z_step <= 21:
			continue # Handled by the Stone Bridge
		var road = AssetLoader.load_or_generate_model("res://assets/overworld/hex_road_A.gltf", "dungeon", "hex_road_A")
		road.position = Vector3(0, 0.01, float(z_step))
		parent.add_child(road)
		
	# East Road Branch: Main Highway -> Farmlands Hamlet
	var east_path = [
		Vector3(2.5, 0.01, 18.0), Vector3(5.0, 0.01, 18.0), Vector3(7.5, 0.01, 18.2),
		Vector3(10.5, 0.01, 18.5), Vector3(13.5, 0.01, 19.0), Vector3(16.5, 0.01, 19.5),
		Vector3(19.5, 0.01, 20.0), Vector3(22.5, 0.01, 20.0)
	]
	for p in east_path:
		var tile = AssetLoader.load_or_generate_model("res://assets/dungeon/floor_tile_large.glb", "dungeon", "floor_tile_large")
		tile.scale = Vector3(0.5, 1.0, 0.5)
		tile.position = p
		parent.add_child(tile)
		
	# West Road Branch: Main Highway -> Wooden Bridge -> Blackwood Forest
	var west_path = [
		Vector3(-2.5, 0.01, 17.0), Vector3(-5.0, 0.01, 17.0), Vector3(-8.0, 0.01, 17.2),
		Vector3(-11.0, 0.01, 17.5), Vector3(-17.0, 0.01, 17.5), Vector3(-20.0, 0.01, 18.0),
		Vector3(-23.0, 0.01, 19.0), Vector3(-26.0, 0.01, 20.0)
	]
	for p in west_path:
		var tile = AssetLoader.load_or_generate_model("res://assets/dungeon/floor_tile_large.glb", "dungeon", "floor_tile_large")
		tile.scale = Vector3(0.5, 1.0, 0.5)
		tile.position = p
		parent.add_child(tile)

	# Mountain Trail: North-East from Cathedral into High Crags
	var mtn_path = [
		Vector3(12.0, 0.01, -4.0), Vector3(15.0, 0.01, -7.0), Vector3(18.0, 0.01, -11.0),
		Vector3(22.0, 0.01, -15.0), Vector3(25.0, 0.01, -18.0), Vector3(28.0, 0.01, -21.0)
	]
	for p in mtn_path:
		var tile = AssetLoader.load_or_generate_model("res://assets/overworld/floor_dirt.gltf", "dungeon", "floor_dirt")
		tile.scale = Vector3(1.3, 1.0, 1.3)
		tile.position = p
		parent.add_child(tile)

	# Ancient Path: North-West from Blacksmith into Forgotten Ruins
	var ruins_path = [
		Vector3(-12.0, 0.01, -3.0), Vector3(-16.0, 0.01, -4.5), Vector3(-20.0, 0.01, -5.5),
		Vector3(-24.0, 0.01, -5.5), Vector3(-28.0, 0.01, -4.5), Vector3(-32.0, 0.01, -3.5)
	]
	for p in ruins_path:
		var tile = AssetLoader.load_or_generate_model("res://assets/overworld/floor_dirt.gltf", "dungeon", "floor_dirt")
		tile.scale = Vector3(1.3, 1.0, 1.3)
		tile.position = p
		parent.add_child(tile)

func _build_river_and_bridges(parent: Node3D) -> void:
	# River: Winding belt of water from X=-46 to X=+46 around Z=19.0
	for rx in range(-23, 24):
		var rz = 19.0 + sin(float(rx) * 0.22) * 2.6
		var water = AssetLoader.load_or_generate_model("res://assets/overworld/hex_water.gltf", "dungeon", "hex_water")
		water.position = Vector3(float(rx) * 2.0, -0.05, rz)
		water.scale = Vector3(1.15, 1.0, 1.15)
		parent.add_child(water)

	# Water lilies and river reeds
	_place_prop(parent, "res://assets/overworld/waterlily_A.gltf", Vector3(-8.0, 0.02, 18.2), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/waterlily_B.gltf", Vector3(5.0, 0.02, 19.8), Vector3.ONE * 1.3)
	_place_prop(parent, "res://assets/overworld/waterplant_A.gltf", Vector3(-5.0, 0.0, 17.8), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/waterplant_B.gltf", Vector3(12.0, 0.0, 20.2), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/waterplant_C.gltf", Vector3(-18.0, 0.0, 16.5), Vector3.ONE * 1.4)

	# Main Highway Stone Arch Bridge
	_place_prop(parent, "res://assets/overworld/building_bridge_A.gltf", Vector3(0.0, 0.0, 19.5), Vector3(1.6, 1.4, 1.6))
	_add_static_box(parent, Vector3(0.0, 0.25, 19.5), Vector3(3.4, 0.5, 6.2))
	# Bridge side parapets
	_add_static_box(parent, Vector3(-1.9, 0.8, 19.5), Vector3(0.4, 1.2, 6.2))
	_add_static_box(parent, Vector3(1.9, 0.8, 19.5), Vector3(0.4, 1.2, 6.2))

	# Western Wooden Footbridge
	_place_prop(parent, "res://assets/overworld/building_bridge_B.gltf", Vector3(-14.0, 0.0, 17.5), Vector3(1.5, 1.3, 1.5))
	_add_static_box(parent, Vector3(-14.0, 0.2, 17.5), Vector3(2.8, 0.4, 5.5))
	_add_static_box(parent, Vector3(-15.6, 0.7, 17.5), Vector3(0.4, 1.0, 5.5))
	_add_static_box(parent, Vector3(-12.4, 0.7, 17.5), Vector3(0.4, 1.0, 5.5))

	# Riverside Watermill
	_place_prop(parent, "res://assets/overworld/building_watermill_blue.gltf", Vector3(9.0, 0.0, 17.0), Vector3.ONE * 2.4, -90.0)
	_add_static_box(parent, Vector3(9.0, 2.0, 17.0), Vector3(4.0, 4.0, 4.0))

func _build_farmlands_hamlet(parent: Node3D) -> void:
	# Windmill
	_place_prop(parent, "res://assets/overworld/building_windmill_blue.gltf", Vector3(28.0, 0.0, 26.0), Vector3.ONE * 2.5)
	_add_static_box(parent, Vector3(28.0, 2.5, 26.0), Vector3(4.0, 5.0, 4.0))
	
	# Cottages
	_place_prop(parent, "res://assets/overworld/building_home_A_blue.gltf", Vector3(20.0, 0.0, 16.0), Vector3.ONE * 2.2, 45.0)
	_add_static_box(parent, Vector3(20.0, 2.0, 16.0), Vector3(3.8, 4.0, 3.8))
	_place_prop(parent, "res://assets/overworld/building_home_B_blue.gltf", Vector3(34.0, 0.0, 18.0), Vector3.ONE * 2.2, -30.0)
	_add_static_box(parent, Vector3(34.0, 2.0, 18.0), Vector3(3.8, 4.0, 3.8))
	
	# Village Stone Well
	_place_prop(parent, "res://assets/overworld/building_well_blue.gltf", Vector3(24.0, 0.0, 21.0), Vector3.ONE * 1.8)
	_add_static_cyl(parent, Vector3(24.0, 0.0, 21.0), 1.2, 2.5)
	
	# NPC: Farmer Giles
	var giles = TownNPCScript.new()
	giles.npc_id = "farmer"
	giles.npc_name = "Farmer Giles"
	giles.npc_title = "Hamlet Elder"
	giles.icon = "🌾"
	giles.model_path = "res://assets/characters/adventurers/Barbarian.glb"
	giles.model_scale = Vector3(1.15, 1.15, 1.15)
	giles.model_rotation_y = -45.0
	giles.dialogue_text = "Good day, traveler! Welcome to our modest hamlet. The wheat is ripe, but hungry beasts stalk our pastures. Deliver raw meat or fine hides from the wild beasts, and we shall reward you richly in coin!"
	giles.position = Vector3(22.0, 0.0, 19.5)
	parent.add_child(giles)

	# Domestic Grazing Animals
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(27.0, 0.0, 19.0), 45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.COW, Vector3(32.0, 0.0, 23.0), -60.0)
	_spawn_animal(parent, AnimalAI.AnimalType.BULL, Vector3(29.0, 0.0, 22.0), 120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.HORSE, Vector3(21.0, 0.0, 26.0), 15.0)
	_spawn_animal(parent, AnimalAI.AnimalType.HORSE, Vector3(25.0, 0.0, 29.0), -85.0)

	# Fences and farm props
	_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(26.0, 0.0, 16.0), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/fence_wood_straight.gltf", Vector3(30.0, 0.0, 16.0), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/wheelbarrow.gltf", Vector3(22.5, 0.0, 22.0), Vector3.ONE * 1.3, 35.0)
	_place_prop(parent, "res://assets/overworld/pumpkin_orange.gltf", Vector3(23.5, 0.0, 17.5), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/pumpkin_orange.gltf", Vector3(24.2, 0.0, 17.2), Vector3.ONE * 1.2)
	_place_prop(parent, "res://assets/overworld/sack.gltf", Vector3(21.0, 0.0, 16.5), Vector3.ONE * 1.3)

func _build_castle_citadel(parent: Node3D) -> void:
	# Royal Castle Keep
	_place_prop(parent, "res://assets/overworld/building_castle_blue.gltf", Vector3(0.0, 0.0, 42.0), Vector3.ONE * 3.4)
	_add_static_box(parent, Vector3(0.0, 3.5, 42.0), Vector3(7.0, 7.0, 7.0))

	# Catapult Towers
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(-10.0, 0.0, 38.0), Vector3.ONE * 2.0)
	_add_static_box(parent, Vector3(-10.0, 3.0, 38.0), Vector3(3.0, 6.0, 3.0))
	_place_prop(parent, "res://assets/overworld/building_tower_catapult_blue.gltf", Vector3(10.0, 0.0, 38.0), Vector3.ONE * 2.0)
	_add_static_box(parent, Vector3(10.0, 3.0, 38.0), Vector3(3.0, 6.0, 3.0))

	# Stone curtain walls connecting keep to towers
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(-5.0, 0.0, 38.0), Vector3(1.5, 1.5, 1.5))
	_add_static_box(parent, Vector3(-5.0, 2.0, 38.0), Vector3(5.0, 4.0, 1.5))
	_place_prop(parent, "res://assets/overworld/wall_straight.gltf", Vector3(5.0, 0.0, 38.0), Vector3(1.5, 1.5, 1.5))
	_add_static_box(parent, Vector3(5.0, 2.0, 38.0), Vector3(5.0, 4.0, 1.5))

	# Garrison Barracks
	_place_prop(parent, "res://assets/overworld/building_barracks_blue.gltf", Vector3(14.0, 0.0, 34.0), Vector3.ONE * 2.2, -45.0)
	_add_static_box(parent, Vector3(14.0, 2.0, 34.0), Vector3(4.5, 4.0, 4.5))

	# Military Market Outpost
	_place_prop(parent, "res://assets/overworld/building_market_blue.gltf", Vector3(-14.0, 0.0, 34.0), Vector3.ONE * 2.0, 45.0)

	# NPC: Commander Drake
	var drake = TownNPCScript.new()
	drake.npc_id = "commander"
	drake.npc_name = "Commander Drake"
	drake.npc_title = "Citadel Commander"
	drake.icon = "🛡️"
	drake.model_path = "res://assets/characters/adventurers/Knight.glb"
	drake.model_scale = Vector3(1.25, 1.25, 1.25)
	drake.model_rotation_y = 180.0
	drake.dialogue_text = "Stand firm, warrior! The Imperial Citadel stands vigil against the abyss. Our scouts report arcane crystals gleaming in the north-eastern crags, and sacred relics lost in the western ruins. Check your royal bounties and bring glory to the realm!"
	drake.position = Vector3(0.0, 0.0, 34.0)
	parent.add_child(drake)

	# Castle Props
	_place_prop(parent, "res://assets/overworld/weaponrack.gltf", Vector3(-2.5, 0.0, 35.0), Vector3.ONE * 1.4, 25.0)
	_place_prop(parent, "res://assets/overworld/flag_blue.gltf", Vector3(-10.0, 5.5, 38.0), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/flag_blue.gltf", Vector3(10.0, 5.5, 38.0), Vector3.ONE * 1.5)
	_place_prop(parent, "res://assets/overworld/crate_A_big.gltf", Vector3(2.5, 0.0, 35.0), Vector3.ONE * 1.3)

func _build_blackwood_forest(parent: Node3D) -> void:
	# Lumbermill
	_place_prop(parent, "res://assets/overworld/building_lumbermill_blue.gltf", Vector3(-20.0, 0.0, 22.0), Vector3.ONE * 2.2, 90.0)
	_add_static_box(parent, Vector3(-20.0, 2.0, 22.0), Vector3(4.0, 4.0, 4.0))

	# Dense Forest Trees
	var forest_locs = [
		Vector3(-18.0, 0.0, 8.0), Vector3(-22.0, 0.0, 10.0), Vector3(-26.0, 0.0, 7.0),
		Vector3(-22.0, 0.0, 15.0), Vector3(-28.0, 0.0, 16.0), Vector3(-32.0, 0.0, 14.0),
		Vector3(-25.0, 0.0, 24.0), Vector3(-30.0, 0.0, 22.0), Vector3(-36.0, 0.0, 25.0),
		Vector3(-22.0, 0.0, 30.0), Vector3(-28.0, 0.0, 32.0), Vector3(-34.0, 0.0, 34.0),
		Vector3(-38.0, 0.0, 12.0), Vector3(-42.0, 0.0, 20.0), Vector3(-42.0, 0.0, 28.0),
		Vector3(-40.0, 0.0, 36.0), Vector3(-30.0, 0.0, 38.0), Vector3(-24.0, 0.0, 36.0)
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
		_place_prop(parent, tm, lp, Vector3.ONE * 1.35, float((i * 53) % 360))
		_add_static_cyl(parent, lp, 0.8, 5.0)

	# Boulders
	_place_prop(parent, "res://assets/overworld/rock_single_C.gltf", Vector3(-27.0, 0.0, 18.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/rock_single_D.gltf", Vector3(-35.0, 0.0, 20.0), Vector3.ONE * 2.0)

	# Forest Wildlife
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-26.0, 0.0, 14.0), 30.0)
	_spawn_animal(parent, AnimalAI.AnimalType.STAG, Vector3(-34.0, 0.0, 26.0), -45.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-22.0, 0.0, 18.0), 110.0)
	_spawn_animal(parent, AnimalAI.AnimalType.DEER, Vector3(-30.0, 0.0, 12.0), -120.0)
	_spawn_animal(parent, AnimalAI.AnimalType.FOX, Vector3(-28.0, 0.0, 32.0), 75.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-38.0, 0.0, 18.0), 160.0)
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(-36.0, 0.0, 30.0), -30.0)

	# Special Quest Timber Nodes
	_spawn_material_node(parent, "heartwood_timber", "Heartwood Timber", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-24.0, 0.0, 12.0), Color(0.8, 0.5, 0.2), 20, 15)
	_spawn_material_node(parent, "ironwood_logs", "Ironwood Logs", "🪵", "res://assets/overworld/resource_lumber.gltf", Vector3(-32.0, 0.0, 26.0), Color(0.7, 0.4, 0.2), 25, 20)

func _build_iron_mountains(parent: Node3D) -> void:
	# Mountain Peaks forming natural barriers
	var mtns = [
		{"pos": Vector3(26.0, 0.0, -36.0), "path": "res://assets/overworld/mountain_A.gltf", "scale": 3.0},
		{"pos": Vector3(36.0, 0.0, -32.0), "path": "res://assets/overworld/mountain_B_grass_trees.gltf", "scale": 3.0},
		{"pos": Vector3(42.0, 0.0, -22.0), "path": "res://assets/overworld/mountain_C.gltf", "scale": 3.0},
		{"pos": Vector3(38.0, 0.0, -12.0), "path": "res://assets/overworld/mountain_A_grass.gltf", "scale": 2.8},
		{"pos": Vector3(20.0, 0.0, -38.0), "path": "res://assets/overworld/hills_A.gltf", "scale": 2.5},
		{"pos": Vector3(18.0, 0.0, -24.0), "path": "res://assets/overworld/hills_B_trees.gltf", "scale": 2.4}
	]
	for m in mtns:
		_place_prop(parent, m["path"], m["pos"], Vector3.ONE * m["scale"])
		_add_static_box(parent, m["pos"] + Vector3(0, 4.0, 0), Vector3(m["scale"] * 2.5, 8.0, m["scale"] * 2.5))

	# Mountain Mine
	_place_prop(parent, "res://assets/overworld/building_mine_blue.gltf", Vector3(32.0, 0.0, -22.0), Vector3.ONE * 2.4, -90.0)
	_add_static_box(parent, Vector3(32.0, 2.0, -22.0), Vector3(4.5, 4.0, 4.5))

	# Mountain Wolf Guard
	_spawn_animal(parent, AnimalAI.AnimalType.WOLF, Vector3(28.0, 0.0, -24.0), 45.0)

	# Special Quest Mineral Nodes
	_spawn_material_node(parent, "arcane_crystal", "Arcane Cyan Crystal", "💎", "res://assets/items/quest_materials/Crystal1.glb", Vector3(26.0, 0.0, -20.0), Color(0.2, 0.8, 1.0), 30, 25)
	_spawn_material_node(parent, "emerald_crystal", "Emerald Geo-Crystal", "💎", "res://assets/items/quest_materials/Crystal2.glb", Vector3(34.0, 0.0, -26.0), Color(0.2, 1.0, 0.4), 35, 30)
	_spawn_material_node(parent, "gold_vein", "Mountain Gold Vein", "🪙", "res://assets/items/quest_materials/Gold_Ingots.glb", Vector3(24.0, 0.0, -30.0), Color(1.0, 0.85, 0.2), 40, 35)
	_spawn_material_node(parent, "iron_ore", "Highland Iron Ore", "⛏️", "res://assets/overworld/resource_stone.gltf", Vector3(30.0, 0.0, -16.0), Color(0.6, 0.65, 0.7), 25, 20)

func _build_forgotten_ruins(parent: Node3D) -> void:
	# Shrines & Ancient Stone Pillars
	_place_prop(parent, "res://assets/overworld/shrine_candles.gltf", Vector3(-34.0, 0.0, -4.0), Vector3.ONE * 2.0)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-30.0, 0.0, -8.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/pillar.gltf", Vector3(-38.0, 0.0, -8.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/shrine.gltf", Vector3(-32.0, 0.0, 2.0), Vector3.ONE * 1.8)
	_place_prop(parent, "res://assets/overworld/skull_candle.gltf", Vector3(-33.0, 0.0, -2.0), Vector3.ONE * 1.4)
	_place_prop(parent, "res://assets/overworld/bone_A.gltf", Vector3(-31.0, 0.0, -5.0), Vector3.ONE * 1.5)

	# NPC: Hermit Morvath
	var hermit = TownNPCScript.new()
	hermit.npc_id = "hermit"
	hermit.npc_name = "Hermit Morvath"
	hermit.npc_title = "Keeper of the Forgotten"
	hermit.icon = "🔮"
	hermit.model_path = "res://assets/characters/adventurers/Mage.glb"
	hermit.model_scale = Vector3(1.15, 1.15, 1.15)
	hermit.model_rotation_y = 65.0
	hermit.dialogue_text = "Tread lightly, warrior. The stones here remember an empire older than memory. The Sacred Chalice and the Ancient Codex are scattered among these cracked pedestals. Channel the Soul Echoes you reap to unlock arcane boons!"
	hermit.position = Vector3(-32.0, 0.0, -3.0)
	parent.add_child(hermit)

	# Sacred Relic Material Nodes
	_spawn_material_node(parent, "sacred_chalice", "Sacred Chalice of the First Kings", "🏆", "res://assets/items/quest_materials/Chalice.glb", Vector3(-36.0, 0.0, -6.0), Color(1.0, 0.8, 0.2), 50, 50, Vector3(2.0, 2.0, 2.0))
	_spawn_material_node(parent, "ossuary_codex", "Forgotten Ossuary Codex", "📜", "res://assets/items/quest_materials/Scroll.glb", Vector3(-30.0, 0.0, 2.0), Color(0.9, 0.85, 0.6), 40, 40, Vector3(2.0, 2.0, 2.0))
	_spawn_material_node(parent, "smugglers_chest", "Sunken Smuggler's Chest", "📦", "res://assets/items/quest_materials/Chest_Ingots.glb", Vector3(-26.0, 0.0, -12.0), Color(0.95, 0.75, 0.2), 60, 45, Vector3(1.2, 1.2, 1.2))

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
	return prop

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
