extends Node3D
class_name DungeonGenerator

const RoomControllerScript = preload("res://src/dungeon/RoomController.gd")
const SpikeTrapScript = preload("res://src/dungeon/SpikeTrap.gd")

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

# --- SURFACE OVERWORLD SANCTUARY HUB ---
func _build_overworld_sanctuary(parent: Node3D) -> void:
	var ground_size = 32.0
	var half_s = ground_size * 0.5
	
	# 1. Floor Static Collision & Safety Void Safeguard
	var floor_body = StaticBody3D.new()
	floor_body.collision_layer = 1
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(ground_size + 10.0, 1.2, ground_size + 10.0)
	col_shape.shape = box
	col_shape.position.y = -0.6
	floor_body.add_child(col_shape)
	parent.add_child(floor_body)
	
	# Perimeter boundary collision barriers (North, South, East, West)
	var wall_h = 8.0
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
			if abs(x_pos) <= half_s - 1.2 and abs(z_pos) <= half_s - 1.2:
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

	# 6. East: The Ruined Cathedral
	var church = AssetLoader.load_or_generate_model("res://assets/overworld/building_church_blue.gltf", "dungeon", "church")
	church.scale = Vector3(3.0, 3.0, 3.0)
	church.position = Vector3(9.5, 0, 0.0)
	church.rotation_degrees.y = -90.0
	parent.add_child(church)
	_add_static_box(parent, Vector3(9.8, 2.5, 0.0), Vector3(4.5, 5.0, 5.0))
	_place_prop(parent, "res://assets/overworld/bench.gltf", Vector3(6.5, 0, 2.2), Vector3.ONE * 1.5, -45.0)

	# 7. South: Castle Arch Gateway
	var gate = AssetLoader.load_or_generate_model("res://assets/overworld/arch_gate.gltf", "dungeon", "arch_gate")
	gate.position = Vector3(0, 0, 11.5)
	parent.add_child(gate)
	_add_static_box(parent, Vector3(-2.8, 2.0, 11.5), Vector3(1.5, 4.0, 1.5))
	_add_static_box(parent, Vector3(2.8, 2.0, 11.5), Vector3(1.5, 4.0, 1.5))

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
