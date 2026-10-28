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
	
	var matrix: Array = []
	if floor_num == 0:
		room_ctrl.is_hub_room = true
		add_child(room_ctrl)
		matrix = _generate_hub_matrix()
	elif floor_num >= 5:
		room_ctrl.is_boss_room = true
		add_child(room_ctrl)
		matrix = _generate_boss_matrix()
	else:
		room_ctrl.is_hub_room = false
		add_child(room_ctrl)
		matrix = _generate_chamber_matrix(floor_num)
		
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
